import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

import '../codec/assuan_codec.dart';
import '../codec/assuan_data_decoder.dart';
import '../codec/assuan_data_encoder.dart';
import '../codec/auto_newline_converter.dart';
import '../protocol/assuan_comment.dart';
import '../protocol/assuan_data_message.dart';
import '../protocol/assuan_protocol.dart';
import '../protocol/base/assuan_error_code.dart';
import '../protocol/base/assuan_exception.dart';
import '../protocol/base/assuan_message.dart';
import '../protocol/requests/assuan_bye_request.dart';
import '../protocol/requests/assuan_cancel_request.dart';
import '../protocol/requests/assuan_end_request.dart';
import '../protocol/requests/assuan_help_request.dart';
import '../protocol/requests/assuan_nop_request.dart';
import '../protocol/requests/assuan_option_request.dart';
import '../protocol/requests/assuan_reset_request.dart';
import '../protocol/responses/assuan_error_response.dart';
import '../protocol/responses/assuan_inquire_response.dart';
import '../protocol/responses/assuan_ok_response.dart';
import '../protocol/responses/assuan_status_response.dart';
import 'models/server_reply.dart';

abstract class AssuanServer {
  final AssuanProtocol protocol;
  final StreamChannel<String> channel;

  var _closed = false;

  late final StreamSubscription<AssuanRequest> _requestSub;
  late final StreamSink<AssuanResponse> _responseSink;
  var _processingRequest = false;

  // ignore: close_sinks false positive
  StreamController<AssuanDataMessage>? _pendingInquire;

  AssuanServer(this.protocol, this.channel) {
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

    unawaited(init().catchError(_handleError));
  }

  AssuanServer.raw(
    AssuanProtocol protocol,
    StreamChannel<List<int>> channel, {
    Encoding encoding = utf8,
  }) : this(
         protocol,
         channel.transform(StreamChannelTransformer.fromCodec(encoding)),
       );

  AssuanServer.io(
    AssuanProtocol protocol,
    Stdin stdin,
    Stdout stdout, {
    Encoding encoding = systemEncoding,
  }) : this.raw(
         protocol,
         StreamChannel.withGuarantees(stdin, stdout, allowSinkErrors: false),
         encoding: encoding,
       );

  @nonVirtual
  bool get isOpen => !_closed;

  @nonVirtual
  Future<void> close({bool clientInitiated = false}) async {
    if (_closed) {
      return;
    }
    _closed = true;

    await finalize();

    if (clientInitiated) {
      _send(const AssuanOkResponse());
    }

    await Future.wait([
      reset(closing: true),
      _requestSub.cancel(),
      _responseSink.close(),
    ]);
  }

  @protected
  @nonVirtual
  void sendStatus(String keyword, String status) =>
      _send(AssuanStatusResponse(keyword, status));

  @protected
  @nonVirtual
  void sendComment(String comment) => _send(AssuanComment(comment));

  @protected
  @nonVirtual
  Stream<String> startInquire(
    String keyword, [
    List<String> parameters = const [],
  ]) {
    if (!_processingRequest) {
      throw AssuanException.code(
        AssuanErrorCode.unknownInquire,
        'Can only inquire while processing a client request',
      );
    }

    if (_pendingInquire != null) {
      throw AssuanException.code(
        AssuanErrorCode.nestedCommands,
        'Cannot inquire while another inquiry is still pending',
      );
    }

    // ignore: close_sinks
    final ctr = _pendingInquire = StreamController();
    _send(AssuanInquireResponse(keyword, parameters));
    return ctr.stream.transform(const AssuanDataDecoder());
  }

  @protected
  @nonVirtual
  Future<String> inquire(String keyword, [List<String> parameters = const []]) {
    final stream = startInquire(keyword, parameters);
    return stream.join();
  }

  @protected
  @mustCallSuper
  Future<void> init() async => _send(const AssuanOkResponse());

  @protected
  @mustCallSuper
  Future<void> finalize() => Future.value();

  @protected
  Future<void> setOption(String name, String? value);

  @protected
  Future<ServerReply> handleRequest(AssuanRequest request);

  @protected
  @mustCallSuper
  Future<void> reset({bool closing = false}) async {
    final error = AssuanException.code(
      AssuanErrorCode.canceled,
      closing ? 'Connection was closed' : 'Connection was reset',
    );

    if (_pendingInquire case final StreamController<AssuanDataMessage> ctr) {
      _pendingInquire = null;
      ctr.addError(error);
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
    if (_processingRequest) {
      await _handleInquiry(request);
      return;
    }

    try {
      _processingRequest = true;
      switch (request) {
        case AssuanByeRequest():
          await close(clientInitiated: true);
        case AssuanResetRequest():
          await reset();
          _send(const AssuanOkResponse());
        case AssuanHelpRequest():
          _sendHelp();
        case AssuanOptionRequest(:final name, :final value):
          await setOption(name, value);
          _send(const AssuanOkResponse());
        case AssuanNopRequest():
          _send(const AssuanOkResponse());
        case AssuanDataMessage() || AssuanEndRequest() || AssuanCancelRequest():
          throw AssuanException.code(
            AssuanErrorCode.unexpectedCmd,
            '${request.command} is only allowed as response to INQUIRE',
          );
        default:
          final reply = await handleRequest(request);
          switch (reply) {
            case OkReply(:final message):
              _send(AssuanOkResponse(message));
            case DataReply(:final data, :final message):
              await _sendStream(Stream.value(data), message);
            case DataStreamReply(:final data, :final message):
              await _sendStream(data, message);
          }
      }
      // ignore: avoid_catches_without_on_clauses
    } catch (e, s) {
      _handleError(e, s);
    } finally {
      _processingRequest = false;
    }
  }

  void _send(AssuanResponse response) => _responseSink.add(response);

  Future<void> _sendStream(Stream<String> stream, String? doneMessage) => stream
      .transform(const AssuanDataEncoder())
      .listen(_send)
      .asFuture<String?>(doneMessage)
      .then((message) => _send(AssuanOkResponse(message)));

  void _sendHelp() {
    for (final cmd in protocol.requestCommands) {
      _send(AssuanComment(cmd));
    }
    _send(const AssuanOkResponse());
  }

  Future<void> _handleInquiry(AssuanRequest request) async {
    try {
      if (_pendingInquire case StreamController(:final sink)) {
        switch (request) {
          case final AssuanDataMessage message:
            sink.add(message);
          case AssuanEndRequest():
            await sink.close();
            _pendingInquire = null;
          case AssuanCancelRequest():
            sink.addError(
              AssuanException.code(
                AssuanErrorCode.canceled,
                'Inquire was canceled',
              ),
            );
            await sink.close();
            _pendingInquire = null;
          default:
            throw AssuanException.code(
              AssuanErrorCode.unexpectedCmd,
              '${request.command} is not allowed as response to INQUIRE',
            );
        }
      } else {
        throw AssuanException.code(
          AssuanErrorCode.nestedCommands,
          'Already processing another command',
        );
      }
      // ignore: avoid_catches_without_on_clauses
    } catch (e, s) {
      _handleError(e, s);
    }
  }

  void _handleError(Object error, StackTrace stackTrace) {
    if (error case final Exception exception) {
      final assuanErr = mapException(exception, stackTrace);
      if (assuanErr != null) {
        _send(assuanErr);
        return;
      }
    } else {
      Zone.current.handleUncaughtError(error, stackTrace);
    }

    _send(AssuanErrorResponse(AssuanErrorCode.general.code));
  }
}
