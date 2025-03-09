import 'package:freezed_annotation/freezed_annotation.dart';

import 'base/assuan_data_reader.dart';
import 'base/assuan_data_writer.dart';
import 'base/assuan_error_code.dart';
import 'base/assuan_exception.dart';
import 'base/assuan_message.dart';
import 'base/assuan_message_handler.dart';

part 'assuan_data_message.freezed.dart';

@freezed
sealed class AssuanDataMessage
    with _$AssuanDataMessage
    implements AssuanRequest, AssuanResponse {
  static const maxDataLength = 1000 - 2;

  static const cmd = 'D';
  static const handler = AssuanDataMessageHandler();

  factory AssuanDataMessage(String data) = _AssuanDataMessage;

  AssuanDataMessage._() {
    if (data.contains('/r') || data.contains('/n')) {
      throw AssuanException.code(
        AssuanErrorCode.parameter,
        'data must not contain CR or LF',
      );
    }
  }

  @override
  String get command => cmd;
}

class AssuanDataMessageHandler
    implements AssuanMessageHandler<AssuanDataMessage> {
  const AssuanDataMessageHandler();

  @override
  bool hasData(_) => true;

  @override
  void encodeData(AssuanDataMessage message, AssuanDataWriter writer) {
    writer.writeRaw(message.data);
  }

  @override
  AssuanDataMessage decodeData(AssuanDataReader reader) =>
      AssuanDataMessage(reader.readRaw(fixedSpace: true, readToEnd: true));
}
