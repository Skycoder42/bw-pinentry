import 'dart:convert';

import 'package:meta/meta.dart';

import '../models/assuan_message.dart';
import '../models/assuan_protocol.dart';
import 'assuan_message_decoder.dart';
import 'assuan_message_encoder.dart';

sealed class AssuanCodec<T extends AssuanMessage> extends Codec<T, String> {
  @protected
  final AssuanProtocol protocol;

  AssuanCodec(this.protocol);

  @override
  AssuanMessageEncoder<T> get encoder;

  @override
  AssuanMessageDecoder<T> get decoder;
}

class AssuanRequestCodec extends AssuanCodec<AssuanRequest> {
  AssuanRequestCodec(super.protocol);

  @override
  AssuanRequestEncoder get encoder => AssuanRequestEncoder(protocol);

  @override
  AssuanRequestDecoder get decoder => AssuanRequestDecoder(protocol);
}

class AssuanResponseCodec extends AssuanCodec<AssuanResponse> {
  AssuanResponseCodec(super.protocol);

  @override
  AssuanResponseEncoder get encoder => AssuanResponseEncoder(protocol);

  @override
  AssuanResponseDecoder get decoder => AssuanResponseDecoder(protocol);
}
