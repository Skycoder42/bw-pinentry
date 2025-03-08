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
import '../responses/assuan_status_response.dart';
import 'server_reply.dart';

abstract class AssuanServer {
  final AssuanCommonProtocol protocol;
  final StreamChannel<String> channel;
  final bool exitOnClose;

  var _closed = false;

  late final StreamSubscription<AssuanRequest> _requestSub;
  late final StreamSink<AssuanResponse> _responseSink;
  var _processingRequest = false;

  // ignore: close_sinks false positive
  StreamController<String>? _pendingInquire;

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
    Encoding encoding = systemEncoding,
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
    if (_closed) {
      return;
    }
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
    return ctr.stream;
  }

  @protected
  @nonVirtual
  Future<String> inquire(String keyword, [List<String> parameters = const []]) {
    final stream = startInquire(keyword, parameters);
    return stream.join();
  }

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

    if (_pendingInquire case final StreamController<String> ctr) {
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
          _send(const AssuanOkResponse());
          await close();
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
        case AssuanDataRequest() || AssuanEndRequest() || AssuanCanRequest():
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
      // TODO move to transformer
      .map(Uri.encodeFull)
      .expand((s) sync* {
        var offset = 0;
        while ((s.length - offset) > 998) {
          yield s.substring(offset, offset + 998);
          offset += 998;
        }
        yield s.substring(offset);
      })
      .map(AssuanDataResponse.new)
      .listen(_send)
      .asFuture(doneMessage)
      .then((message) => _send(AssuanOkResponse(message)));

  void _sendHelp() {
    for (final cmd in protocol.requestCommands) {
      _send(AssuanComment(cmd));
    }
    _send(const AssuanOkResponse());
  }

  Future<void> _handleInquiry(AssuanRequest request) async {
    try {
      if (_pendingInquire case StreamController<String>(:final sink)) {
        switch (request) {
          case AssuanDataRequest(:final data):
            // TODO decode data -> transformer
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
