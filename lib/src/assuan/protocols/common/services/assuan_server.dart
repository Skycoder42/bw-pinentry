import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

import '../../../core/codec/assuan_codec.dart';
import '../../../core/models/assuan_error_code.dart';
import '../../../core/models/assuan_exception.dart';
import '../../../core/models/assuan_message.dart';
import '../../../core/util/auto_newline_converter.dart';
import '../assuan_comment.dart';
import '../assuan_common_protocol.dart';
import '../requests/assuan_bye_request.dart';
import '../requests/assuan_can_request.dart';
import '../requests/assuan_data_request.dart';
import '../requests/assuan_end_request.dart';
import '../requests/assuan_help_request.dart';
import '../requests/assuan_nop_request.dart';
import '../requests/assuan_option_request.dart';
import '../requests/assuan_reset_request.dart';
import '../responses/assuan_data_response.dart';
import '../responses/assuan_error_response.dart';
import '../responses/assuan_inquire_response.dart';
import '../responses/assuan_ok_response.dart';

abstract class AssuanServer {
  final AssuanCommonProtocol protocol;
  final StreamChannel<String> channel;
  final bool exitOnClose;

  var _closed = false;

  late final StreamSubscription<AssuanRequest> _requestSub;
  late final StreamSink<AssuanResponse> _responseSink;

  StreamController<String>? _currentDataStream;
  // ignore: close_sinks false positive
  StreamController<String>? _pendingInquire;
  Completer<void>? _pendingSendData;

  AssuanServer(this.protocol, this.channel, {this.exitOnClose = false}) {
    _responseSink = channel.sink
        .transform(
          StreamSinkTransformer.fromStreamTransformer(
            AppendLineTerminatorConverter(),
          ),
        )
        .transform(
          StreamSinkTransformer.fromStreamTransformer(
            AssuanResponseCodec(protocol).encoder,
          ),
        );

    _requestSub = channel.stream
        .transform(const LineSplitter())
        .transform(AssuanRequestCodec(protocol).decoder)
        .listen(
          _handleRequest,
          onError: _handleError,
          onDone: close,
          cancelOnError: false,
        );
  }

  AssuanServer.raw(
    AssuanCommonProtocol protocol,
    StreamChannel<List<int>> channel, {
    Encoding encoding = utf8,
    bool exitOnClose = false,
  }) : this(
         protocol,
         channel.transform(StreamChannelTransformer.fromCodec(encoding)),
         exitOnClose: exitOnClose,
       );

  AssuanServer.io(
    AssuanCommonProtocol protocol,
    Stdin stdin,
    Stdout stdout, {
    Encoding encoding = utf8,
    bool exitOnClose = false,
  }) : this.raw(
         protocol,
         StreamChannel.withGuarantees(stdin, stdout, allowSinkErrors: false),
         encoding: encoding,
         exitOnClose: exitOnClose,
       );

  @nonVirtual
  bool get isOpen => !_closed;

  @mustCallSuper
  Future<void> close() async {
    _closed = true;

    await Future.wait([
      reset(closing: true),
      _requestSub.cancel(),
      _responseSink.close(),
    ]);

    // TODO remove if not needed
    if (exitOnClose) {
      Future(() => exit(0)).ignore();
    }
  }

  @protected
  @nonVirtual
  void send(AssuanResponse response) => _responseSink.add(response);

  @protected
  @nonVirtual
  StreamSink<String> sendData() {
    if (_pendingSendData case Completer(isCompleted: false)) {
      throw AssuanException.code(
        AssuanErrorCode.nestedCommands,
        'Cannot sendData while another sink is still open',
      );
    }

    final completer = _pendingSendData = Completer<void>();
    return _SendDataSink(this, completer);
  }

  @protected
  @nonVirtual
  Stream<String> inquire(String keyword, [List<String> parameters = const []]) {
    if (_pendingInquire != null) {
      throw AssuanException.code(
        AssuanErrorCode.nestedCommands,
        'Cannot inquire while another inquiry is still pending',
      );
    }

    // ignore: close_sinks
    final ctr = _pendingInquire = StreamController();
    send(AssuanInquireResponse(keyword, parameters));
    return ctr.stream;
  }

  @protected
  Future<void> setOption(String name, String? value) => Future.value();

  @protected
  void onData(Stream<String> data) => unawaited(data.drain<void>());

  @protected
  Future<void> handleApplicationRequest(AssuanRequest request) {
    send(
      AssuanErrorResponse(
        AssuanErrorCode.unknownCmd.code,
        'Unknown command ${request.command}',
      ),
    );
    return Future.value();
  }

  @protected
  @mustCallSuper
  Future<void> reset({bool closing = false}) async {
    final error = AssuanException.code(
      AssuanErrorCode.canceled,
      closing ? 'Connection was closed' : 'Connection was reset',
    );

    if (_pendingSendData case Completer(isCompleted: false)) {
      _pendingSendData?.completeError(error, StackTrace.current);
      _pendingSendData = null;
    }

    if (_pendingInquire case final StreamController<String> ctr) {
      _pendingInquire = null;
      ctr.addError(error, StackTrace.current);
      await ctr.close();
    }

    if (_currentDataStream case final StreamController<String> ctr) {
      _currentDataStream = null;
      ctr.addError(error, StackTrace.current);
      await ctr.close();
    }
  }

  @protected
  AssuanErrorResponse? mapException(
    Exception exception,
    StackTrace stackTrace,
  ) {
    if (exception case final AssuanException e) {
      return AssuanErrorResponse(e.code, e.message);
    } else {
      return AssuanErrorResponse(
        AssuanErrorCode.general.code,
        exception.toString(),
      );
    }
  }

  Future<void> _handleRequest(AssuanRequest request) async {
    try {
      if (_pendingInquire case final StreamController<String> ctr) {
        await _handleInquire(ctr.sink, request);
        return;
      }

      switch (request) {
        case AssuanByeRequest():
          send(const AssuanOkResponse());
          await close();
        case AssuanResetRequest():
          await reset();
          send(const AssuanOkResponse());
        case AssuanHelpRequest():
          _sendHelp();
        case AssuanOptionRequest(:final name, :final value):
          await setOption(name, value);
          send(const AssuanOkResponse());
        case AssuanNopRequest():
          send(const AssuanOkResponse());
        case AssuanDataRequest(:final data):
          _getDataSink().add(data);
        case AssuanEndRequest():
          await _currentDataStream?.close();
          _currentDataStream = null;
        case AssuanCanRequest():
          throw AssuanException.code(
            AssuanErrorCode.unexpectedCmd,
            'CAN is only allowed as response to INQUIRE',
          );
        default:
          await handleApplicationRequest(request);
      }
      // ignore: avoid_catches_without_on_clauses
    } catch (e, s) {
      _handleError(e, s);
    }
  }

  Future<void> _handleInquire(
    StreamSink<String> sink,
    AssuanRequest request,
  ) async {
    switch (request) {
      case AssuanDataRequest(:final data):
        sink.add(data);
      case AssuanEndRequest():
        await sink.close();
        _pendingInquire = null;
      case AssuanCanRequest():
        sink.addError(
          AssuanException.code(
            AssuanErrorCode.canceled,
            'Inquire was canceled',
          ),
          StackTrace.current,
        );
        await sink.close();
        _pendingInquire = null;
      default:
        _handleError(
          AssuanErrorResponse(
            AssuanErrorCode.unexpectedCmd.code,
            'Command ${request.command} is not allowed '
            'as response to an INQUIRE',
          ),
          StackTrace.current,
        );
    }
  }

  void _handleError(Object error, StackTrace stackTrace) {
    if (error case final Exception exception) {
      final assuanErr = mapException(exception, stackTrace);
      if (assuanErr != null) {
        send(assuanErr);
        return;
      }
    } else {
      Zone.current.handleUncaughtError(error, stackTrace);
    }

    send(AssuanErrorResponse(AssuanErrorCode.general.code));
  }

  void _sendHelp() {
    for (final cmd in protocol.requestCommands) {
      send(AssuanComment(cmd));
    }
    send(const AssuanOkResponse());
  }

  Sink<String> _getDataSink() {
    if (_currentDataStream case final StreamController<String> ctr) {
      return ctr.sink;
    } else {
      // ignore: close_sinks
      final ctr = _currentDataStream = StreamController();
      onData(ctr.stream);
      return ctr.sink;
    }
  }
}

class _SendDataSink implements StreamSink<String> {
  final AssuanServer _server;
  final Completer<void> _doneCompleter;

  _SendDataSink(this._server, this._doneCompleter);

  @override
  Future<void> get done => _doneCompleter.future;

  @override
  void add(String event) {
    _ensureOpen();
    _server.send(AssuanDataResponse(event));
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _ensureOpen();
    _server._handleError(error, stackTrace ?? StackTrace.current);
    _doneCompleter.complete();
  }

  @override
  Future<void> addStream(Stream<String> stream) {
    _ensureOpen();
    final completer = Completer<void>();
    stream.listen(
      add,
      onError: (Object error, StackTrace? stackTrace) {
        addError(error, stackTrace);
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      cancelOnError: true,
    );
    return completer.future;
  }

  @override
  Future<void> close() {
    if (!_doneCompleter.isCompleted) {
      _server.send(const AssuanOkResponse());
      _doneCompleter.complete();
    }
    return done;
  }

  void _ensureOpen() {
    if (_doneCompleter.isCompleted) {
      throw AssuanException.code(
        AssuanErrorCode.writeError,
        'Cannot send data after the sink was closed',
      );
    }
  }
}
