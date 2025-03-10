import 'dart:convert';

const assuanPercentCodec = AssuanPercentCodec();

class AssuanPercentCodec extends Codec<String, String> {
  const AssuanPercentCodec();

  @override
  Converter<String, String> get decoder => const _AssuanPercentDecoder();

  @override
  Converter<String, String> get encoder => const _AssuanPercentEncoder();
}

class _AssuanPercentEncoder extends Converter<String, String> {
  static final _escapeRequiredCharsPattern = RegExp(r'[\%\n\r\\]');

  const _AssuanPercentEncoder();

  @override
  String convert(String input) =>
      input.replaceAllMapped(_escapeRequiredCharsPattern, _encode);

  String _encode(Match match) => utf8.encode(match[0]!).map(_encodeChar).join();

  String _encodeChar(int char) {
    final hex = char.toRadixString(16).padLeft(2, '0').toUpperCase();
    return '%$hex';
  }
}

class _AssuanPercentDecoder extends Converter<String, String> {
  static final _percentEncodedPattern = RegExp('((?:%[0-9a-fA-F]{2})+)');

  const _AssuanPercentDecoder();

  @override
  String convert(String input) =>
      input.replaceAllMapped(_percentEncodedPattern, _decode);

  String _decode(Match match) {
    final bytes =
        match[0]!
            .split('%')
            .skip(1)
            .map((hex) => int.parse(hex, radix: 16))
            .toList();
    return utf8.decode(bytes);
  }
}
