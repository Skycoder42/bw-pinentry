import 'package:freezed_annotation/freezed_annotation.dart';

import '../base/assuan_data_reader.dart';
import '../base/assuan_data_writer.dart';
import '../base/assuan_message.dart';
import '../base/assuan_message_handler.dart';

part 'assuan_ok_response.freezed.dart';

@freezed
sealed class AssuanOkResponse
    with _$AssuanOkResponse
    implements AssuanResponse {
  static const cmd = 'OK';
  static const handler = AssuanOkResponseHandler();

  const factory([String? debugData]) = _AssuanOkResponse;

  const new _();

  @override
  String get command => cmd;
}

class AssuanOkResponseHandler
    implements AssuanMessageHandler<AssuanOkResponse> {
  const new();

  @override
  bool hasData(AssuanOkResponse message) => message.debugData != null;

  @override
  void encodeData(AssuanOkResponse message, AssuanDataWriter writer) {
    if (message.debugData case final String data) {
      writer.write(data);
    }
  }

  @override
  AssuanOkResponse decodeData(AssuanDataReader reader) =>
      AssuanOkResponse(reader.readAllOptional());
}
