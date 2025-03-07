import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/models/assuan_data_reader.dart';
import '../../../core/models/assuan_data_writer.dart';
import '../../../core/models/assuan_message.dart';
import '../../../core/models/assuan_message_handler.dart';

part 'assuan_data_response.freezed.dart';

@freezed
sealed class AssuanDataResponse
    with _$AssuanDataResponse
    implements AssuanResponse {
  static const cmd = 'D';
  static const handler = AssuanDataResponseHandler();

  const factory AssuanDataResponse(String data) = _AssuanDataResponse;

  const AssuanDataResponse._();

  @override
  String get command => cmd;
}

class AssuanDataResponseHandler
    implements AssuanMessageHandler<AssuanDataResponse> {
  const AssuanDataResponseHandler();

  @override
  bool hasData(_) => true;

  @override
  void encodeData(AssuanDataResponse message, AssuanDataWriter writer) {
    writer.write(message.data);
  }

  @override
  AssuanDataResponse decodeData(AssuanDataReader reader) =>
      AssuanDataResponse(reader.readAll(fixedSpace: true));
}
