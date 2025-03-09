import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

import '../codec/assuan_codec.dart';
import '../codec/assuan_data_decoder.dart';
import '../codec/assuan_data_encoder.dart';
import '../codec/auto_newline_converter.dart';
import '../protocol/assuan_data_message.dart';
import '../protocol/assuan_protocol.dart';
import '../protocol/base/assuan_error_code.dart';
import '../protocol/base/assuan_exception.dart';
import '../protocol/base/assuan_message.dart';
import '../protocol/requests/assuan_bye_request.dart';
import '../protocol/requests/assuan_cancel_request.dart';
import '../protocol/requests/assuan_end_request.dart';
import '../protocol/requests/assuan_nop_request.dart';
import '../protocol/requests/assuan_option_request.dart';
import '../protocol/requests/assuan_reset_request.dart';
import '../protocol/responses/assuan_error_response.dart';
import '../protocol/responses/assuan_inquire_response.dart';
import '../protocol/responses/assuan_ok_response.dart';
import '../protocol/responses/assuan_status_response.dart';
import 'models/inquiry_reply.dart';
import 'models/pending_reply.dart';

typedef CloseCallback = Future<void> Function();

abstract class AssuanClient {
  static const defaultForceCloseTimeout = Duration(seconds: 5);

  final AssuanProtocol protocol;
  final StreamChannel<String> channel;
  final Future<void>? terminateSignal;
  final Duration forceCloseTimeout;
  final CloseCallback? forceCloseCallback;

  late Future<void> connected;
  var _closed = false;

  late final StreamSubscription<AssuanResponse> _responseSub;
  late final StreamSink<AssuanRequest> _requestSink;

  PendingReply? _pendingReply;
  Timer? _forceCloseTimer;

  AssuanClient(
    this.protocol,
    this.channel, {
    this.terminateSignal,
    this.forceCloseCallback,
    this.forceCloseTimeout = defaultForceCloseTimeout,
  }) {
    _requestSink = channel.sink
        .transform(
          StreamSinkTransformer.fromStreamTransformer(
            AppendLineTerminatorConverter(),
          ),
        )
        .transform(
          StreamSinkTransformer.fromStreamTransformer(
            AssuanRequestCodec(protocol).encoder,
          ),
        );

    _responseSub = channel.stream
        .transform(const LineSplitter())
        .transform(AssuanResponseCodec(protocol).decoder)
        .listen(
          _handleResponse,
          onError: _handleError,
          onDone: _handleStreamClosed,
          cancelOnError: false,
        );

    if (terminateSignal case final Future<void> signal) {
      unawaited(
        signal.then((_) => _handleTerminated()).catchError(_handleError),
      );
    } else if (forceCloseCallback != null) {
      throw ArgumentError(
        'can only be set if terminateSignal is set as well',
        'forceCloseCallback',
      );
    }

    final completer = Completer<void>();
    connected = completer.future;
    _pendingReply = PendingReply.action(completer);
  }

  AssuanClient.raw(
    AssuanProtocol protocol,
    StreamChannel<List<int>> channel, {
    Encoding encoding = utf8,
    Future<void>? terminateSignal,
    CloseCallback? forceCloseCallback,
    Duration forceCloseTimeout = defaultForceCloseTimeout,
  }) : this(
         protocol,
         channel.transform(StreamChannelTransformer.fromCodec(encoding)),
         terminateSignal: terminateSignal,
         forceCloseCallback: forceCloseCallback,
         forceCloseTimeout: forceCloseTimeout,
       );

  AssuanClient.process(
    AssuanProtocol protocol,
    Process process, {
    Encoding encoding = systemEncoding,
    Duration forceCloseTimeout = defaultForceCloseTimeout,
  }) : this.raw(
         protocol,
         StreamChannel.withGuarantees(
           process.stdout,
           process.stdin,
           allowSinkErrors: false,
         ),
         encoding: encoding,
         terminateSignal: process.exitCode,
         forceCloseCallback: () => Future.sync(process.kill),
         forceCloseTimeout: forceCloseTimeout,
       );

  @nonVirtual
  bool get isOpen => !_closed;

  @nonVirtual
  Future<void> setOption(String name, [String? value]) =>
      sendAction(AssuanOptionRequest(name, value));

  @nonVirtual
  Future<void> nop() => sendAction(const AssuanNopRequest());

  @nonVirtual
  Future<void> reset() => sendAction(const AssuanResetRequest());

  @mustCallSuper
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;

    try {
      if (forceCloseCallback case final CloseCallback callback) {
        _forceCloseTimer = Timer(forceCloseTimeout, callback);
      }
      await sendAction(const AssuanByeRequest());
    } finally {
      await _cleanup(force: true);
    }
  }

  @protected
  @nonVirtual
  Future<void> sendAction(AssuanRequest request) {
    if (_pendingReply != null) {
      throw AssuanException.code(
        AssuanErrorCode.nestedCommands,
        'Another command is still awaiting a reply',
      );
    }

    final completer = Completer<void>();
    _pendingReply = PendingReply.action(completer);
    _send(request);
    return completer.future;
  }

  @protected
  @nonVirtual
  Future<String> sendRequest(AssuanRequest request) =>
      sendRequestStreamed(request).join();

  @protected
  @nonVirtual
  Stream<String> sendRequestStreamed(AssuanRequest request) {
    if (_pendingReply != null) {
      return Stream.error(
        AssuanException.code(
          AssuanErrorCode.nestedCommands,
          'Another command is still awaiting a reply',
        ),
        StackTrace.current,
      );
    }

    // ignore: close_sinks false positive
    final controller = StreamController<AssuanDataMessage>();
    _pendingReply = PendingReply.data(controller);
    _send(request);
    return controller.stream.transform(const AssuanDataDecoder());
  }

  @protected
  Future<void> onStatus(String keyword, String status);

  @protected
  Future<InquiryReply> onInquire(String keyword, List<String> parameters);

  @protected
  void onUnhandledError(Object error, StackTrace stackTrace) =>
      Zone.current.handleUncaughtError(error, stackTrace);

  Future<void> _handleResponse(AssuanResponse response) async {
    try {
      switch (response) {
        case AssuanOkResponse():
          await _handleOk();
        case AssuanErrorResponse(:final code, :final message):
          await _handleErr(code, message);
        case AssuanStatusResponse(:final keyword, :final status):
          await onStatus(keyword, status);
        case AssuanDataMessage():
          _handleData(response);
        case AssuanInquireResponse(:final keyword, :final parameters):
          await _handleInquire(keyword, parameters);
        default:
          throw AssuanException.code(
            AssuanErrorCode.unknownCmd,
            'Unknown command <${response.command}>',
          );
      }
      // ignore: avoid_catches_without_on_clauses
    } catch (e, s) {
      await _handleError(e, s);
    }
  }

  Future<void> _handleOk() async {
    switch (_pendingReply) {
      case PendingActionReply(:final completer):
        _pendingReply = null;
        completer.complete();
      case PendingDataReply(:final controller):
        _pendingReply = null;
        await controller.close();
      case null:
        _throwNotPending();
    }
  }

  Future<void> _handleErr(int code, String? message) async {
    final exception = AssuanException(message ?? '', code);
    switch (_pendingReply) {
      case PendingActionReply(:final completer):
        _pendingReply = null;
        completer.completeError(exception);
      case PendingDataReply(:final controller):
        _pendingReply = null;
        controller.addError(exception);
        await controller.close();
      case null:
        _throwNotPending();
    }
  }

  void _handleData(AssuanDataMessage message) {
    switch (_pendingReply) {
      case PendingDataReply(:final controller):
        controller.add(message);
      case PendingActionReply():
        throw AssuanException.code(
          AssuanErrorCode.invResponse,
          'Expected OK or ERR response, but got D response',
        );
      case null:
        _throwNotPending();
    }
  }

  Future<void> _handleInquire(String keyword, List<String> parameters) async {
    try {
      if (_pendingReply == null) {
        _throwNotPending();
      }

      final response = await onInquire(keyword, parameters);
      switch (response) {
        case InquiryDataReply(:final data):
          await _sendStream(Stream.value(data));
        case InquiryDataStreamReply(:final stream):
          await _sendStream(stream);
        case InquiryCancelReply():
          _send(const AssuanCancelRequest());
      }
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      _send(const AssuanCancelRequest());
      rethrow;
    }
  }

  Future<void> _handleError(Object error, StackTrace stackTrace) async {
    switch (_pendingReply) {
      case PendingActionReply(:final completer):
        _pendingReply = null;
        completer.completeError(error, stackTrace);
      case PendingDataReply(:final controller):
        _pendingReply = null;
        controller.addError(error, stackTrace);
        await controller.close();
      case null:
        onUnhandledError(error, stackTrace);
    }
  }

  void _send(AssuanRequest request) {
    _requestSink.add(request);
  }

  Future<void> _sendStream(Stream<String> stream) => stream
      .transform(const AssuanDataEncoder())
      .listen(_send)
      .asFuture<void>()
      .then((message) => _send(const AssuanEndRequest()));

  Future<void> _handleTerminated() async {
    try {
      final wasClosed = _closed;
      _forceCloseTimer?.cancel();
      await _cleanup();

      if (!wasClosed) {
        await _handleError(
          AssuanException.code(
            AssuanErrorCode.connectFailed,
            'Server closed unexpectedly',
          ),
          StackTrace.current,
        );
      }

      // ignore: avoid_catches_without_on_clauses
    } catch (e, s) {
      await _handleError(e, s);
    }
  }

  Future<void> _handleStreamClosed() async {
    try {
      final wasClosed = _closed;

      if (forceCloseCallback case final CloseCallback callback
          when !wasClosed) {
        _forceCloseTimer ??= Timer(forceCloseTimeout, callback);
      }

      await _cleanup();

      if (!wasClosed) {
        await _handleError(
          AssuanException.code(
            AssuanErrorCode.connectFailed,
            'Server closed unexpectedly',
          ),
          StackTrace.current,
        );
      }

      // ignore: avoid_catches_without_on_clauses
    } catch (e, s) {
      await _handleError(e, s);
    }
  }

  Future<void> _cleanup({bool force = false}) {
    if (_closed && !force) {
      return Future.value();
    }
    _closed = true;

    return Future.wait([
      _responseSub.cancel(),
      _requestSink.close(),
      if (_pendingReply != null)
        _handleError(
          AssuanException.code(
            AssuanErrorCode.canceled,
            'Connection was closed',
          ),
          StackTrace.current,
        ),
    ]);
  }

  Never _throwNotPending() =>
      throw AssuanException.code(
        AssuanErrorCode.invResponse,
        'Not awaiting any data from server',
      );
}
