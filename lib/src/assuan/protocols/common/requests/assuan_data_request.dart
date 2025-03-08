import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/models/assuan_data_reader.dart';
import '../../../core/models/assuan_data_writer.dart';
import '../../../core/models/assuan_message.dart';
import '../../../core/models/assuan_message_handler.dart';

part 'assuan_data_request.freezed.dart';

@freezed
sealed class AssuanDataRequest
    with _$AssuanDataRequest
    implements AssuanRequest {
  static const cmd = 'D';
  static const handler = AssuanDataRequestHandler();

  const factory AssuanDataRequest(String data) = _AssuanDataRequest;

  const AssuanDataRequest._();

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
    writer.write(message.data);
  }

  @override
  AssuanDataRequest decodeData(AssuanDataReader reader) =>
      AssuanDataRequest(reader.readAll(fixedSpace: true));
}
