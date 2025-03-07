import 'dart:convert';

import 'package:meta/meta.dart';

import '../models/assuan_data_writer.dart';
import '../models/assuan_exception.dart';
import '../models/assuan_message.dart';
import '../models/assuan_message_handler.dart';
import '../models/assuan_protocol.dart';

class AssuanRequestEncoder extends AssuanMessageEncoder<AssuanRequest> {
  AssuanRequestEncoder(super.protocol);

  @override
  @visibleForOverriding
  AssuanMessageHandler<AssuanRequest>? getHandler(String command) =>
      protocol.requestHandler(command);
}

class AssuanResponseEncoder extends AssuanMessageEncoder<AssuanResponse> {
  AssuanResponseEncoder(super.protocol);

  @override
  @visibleForOverriding
  AssuanMessageHandler<AssuanResponse>? getHandler(String command) =>
      protocol.responseHandler(command);
}

sealed class AssuanMessageEncoder<T extends AssuanMessage>
    extends Converter<T, String> {
  @protected
  final AssuanProtocol protocol;

  AssuanMessageEncoder(this.protocol);

  @visibleForOverriding
  AssuanMessageHandler<T>? getHandler(String command);

  @override
  String convert(T response) {
    final command = response.command;
    final handler = getHandler(command);
    if (handler == null) {
      throw AssuanException('Unknown command: $command', response);
    }

    final buffer = StringBuffer(command);
    if (handler.hasData(response)) {
      final writer = AssuanDataWriter(buffer);
      handler.encodeData(response, writer);
    }

    if (buffer.length > 1000) {
      throw const AssuanException(
        'Message too long! Must be less than 1000 bytes',
      );
    }

    return buffer.toString();
  }
}
