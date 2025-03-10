import 'dart:async';

import '../protocol/assuan_data_message.dart';
import 'assuan_percent_codec.dart';

class AssuanDataDecoder
    extends StreamTransformerBase<AssuanDataMessage, String> {
  const AssuanDataDecoder();

  @override
  Stream<String> bind(Stream<AssuanDataMessage> stream) =>
      Stream.eventTransformed(stream, _AssuanDataDecoderSink.new);
}

class _AssuanDataDecoderSink implements EventSink<AssuanDataMessage> {
  final EventSink<String> _sink;

  _AssuanDataDecoderSink(this._sink);

  @override
  void add(AssuanDataMessage event) =>
      _sink.add(assuanPercentCodec.decode(event.data));

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _sink.addError(error, stackTrace);

  @override
  void close() => _sink.close();
}
