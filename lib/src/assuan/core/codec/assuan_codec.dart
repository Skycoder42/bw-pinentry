import 'dart:convert';

import 'package:meta/meta.dart';

import '../protocol/assuan_protocol.dart';
import '../protocol/base/assuan_message.dart';
import 'assuan_message_decoder.dart';
import 'assuan_message_encoder.dart';

sealed class AssuanCodec<T extends AssuanMessage>(
  @protected final AssuanProtocol protocol,
) extends Codec<T, String> {
  @override
  AssuanMessageEncoder<T> get encoder;

  @override
  AssuanMessageDecoder<T> get decoder;
}

class AssuanRequestCodec(super.protocol) extends AssuanCodec<AssuanRequest> {
  @override
  AssuanRequestEncoder get encoder => AssuanRequestEncoder(protocol);

  @override
  AssuanRequestDecoder get decoder => AssuanRequestDecoder(protocol);
}

class AssuanResponseCodec(super.protocol) extends AssuanCodec<AssuanResponse> {
  @override
  AssuanResponseEncoder get encoder => AssuanResponseEncoder(protocol);

  @override
  AssuanResponseDecoder get decoder => AssuanResponseDecoder(protocol);
}
