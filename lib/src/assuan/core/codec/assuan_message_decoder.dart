import 'dart:convert';

import 'package:meta/meta.dart';

import '../protocol/assuan_protocol.dart';
import '../protocol/base/assuan_data_reader.dart';
import '../protocol/base/assuan_error_code.dart';
import '../protocol/base/assuan_exception.dart';
import '../protocol/base/assuan_message.dart';
import '../protocol/base/assuan_message_handler.dart';
import 'converter_sink.dart';

class AssuanRequestDecoder extends AssuanMessageDecoder<AssuanRequest> {
  AssuanRequestDecoder(super.protocol);

  @override
  @visibleForOverriding
  AssuanMessageHandler<AssuanRequest>? getHandler(String command) =>
      protocol.requestHandler(command);
}

class AssuanResponseDecoder extends AssuanMessageDecoder<AssuanResponse> {
  AssuanResponseDecoder(super.protocol);

  @override
  @visibleForOverriding
  AssuanMessageHandler<AssuanResponse>? getHandler(String command) =>
      protocol.responseHandler(command);
}

sealed class AssuanMessageDecoder<T extends AssuanMessage>
    extends Converter<String, T> {
  @protected
  final AssuanProtocol protocol;

  AssuanMessageDecoder(this.protocol);

  @visibleForOverriding
  AssuanMessageHandler<T>? getHandler(String command);

  @override
  T convert(String line) {
    // special handling for comments
    if (line.startsWith(protocol.commentPrefix)) {
      return protocol.createComment(line.substring(1).trim()) as T;
    }

    final (command, offset) = _splitLine(line);

    final handler = getHandler(command);
    if (handler == null) {
      throw AssuanException.code(
        AssuanErrorCode.unknownCmd,
        'Unknown command: $command',
      );
    }

    final reader = AssuanDataReader(line, offset);
    return handler.decodeData(reader);
  }

  @override
  Sink<String> startChunkedConversion(Sink<T> sink) =>
      ConverterSink(sink, this);

  (String command, int offset) _splitLine(String line) {
    final spaceIdx = line.indexOf(' ');
    if (spaceIdx == -1) {
      return (line, line.length);
    } else {
      return (line.substring(0, spaceIdx), spaceIdx);
    }
  }
}
