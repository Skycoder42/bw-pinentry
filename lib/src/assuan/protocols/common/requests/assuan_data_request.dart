import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/models/assuan_data_reader.dart';
import '../../../core/models/assuan_data_writer.dart';
import '../../../core/models/assuan_error_code.dart';
import '../../../core/models/assuan_exception.dart';
import '../../../core/models/assuan_message.dart';
import '../../../core/models/assuan_message_handler.dart';

part 'assuan_data_request.freezed.dart';

@freezed
sealed class AssuanDataRequest
    with _$AssuanDataRequest
    implements AssuanRequest {
  static const cmd = 'D';
  static const handler = AssuanDataRequestHandler();

  factory AssuanDataRequest(String data) = _AssuanDataRequest;

  AssuanDataRequest._() {
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

class AssuanDataRequestHandler
    implements AssuanMessageHandler<AssuanDataRequest> {
  const AssuanDataRequestHandler();

  @override
  bool hasData(_) => true;

  @override
  void encodeData(AssuanDataRequest message, AssuanDataWriter writer) {
    writer.writeRaw(message.data);
  }

  @override
  AssuanDataRequest decodeData(AssuanDataReader reader) =>
      AssuanDataRequest(reader.readRaw(fixedSpace: true, readToEnd: true));
}
