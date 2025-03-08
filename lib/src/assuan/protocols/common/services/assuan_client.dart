import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

import '../../../core/codec/assuan_codec.dart';
import '../../../core/models/assuan_message.dart';
import '../../../core/util/auto_newline_converter.dart';
import '../assuan_common_protocol.dart';

class AssuanClient {
  final AssuanCommonProtocol protocol;
  final StreamChannel<String> channel;

  var _closed = false;

  late final StreamSubscription<AssuanResponse> _responseSub;
  late final StreamSink<AssuanRequest> _requestSink;

  AssuanClient(this.protocol, this.channel) {
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
          _handleRequest,
          onError: _handleError,
          onDone: close,
          cancelOnError: false,
        );
  }

  AssuanClient.raw(
    AssuanCommonProtocol protocol,
    StreamChannel<List<int>> channel, {
    Encoding encoding = utf8,
  }) : this(
         protocol,
         channel.transform(StreamChannelTransformer.fromCodec(encoding)),
       );

  AssuanClient.process(
    AssuanCommonProtocol protocol,
    Process process, {
    Encoding encoding = systemEncoding,
  }) : this.raw(
         protocol,
         StreamChannel.withGuarantees(
           process.stdout,
           process.stdin,
           allowSinkErrors: false,
         ),
         encoding: encoding,
       ); // TODO attach process

  @nonVirtual
  bool get isOpen => !_closed;

  @mustCallSuper
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;

    await Future.wait([_responseSub.cancel(), _requestSink.close()]);
  }

  // @protected
  // @nonVirtual
  // Future<String> send(AssuanRequest request) {}

  // @protected
  // @nonVirtual
  // Stream<String> sendStreamed(AssuanRequest request) {}

  Future<void> _handleRequest(AssuanResponse response) async {}

  void _handleError(Object error, StackTrace stackTrace) {}
}
