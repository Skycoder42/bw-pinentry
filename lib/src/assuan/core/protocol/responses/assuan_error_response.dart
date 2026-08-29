import 'package:freezed_annotation/freezed_annotation.dart';

import '../base/assuan_data_reader.dart';
import '../base/assuan_data_writer.dart';
import '../base/assuan_message.dart';
import '../base/assuan_message_handler.dart';

part 'assuan_error_response.freezed.dart';

@freezed
sealed class AssuanErrorResponse
    with _$AssuanErrorResponse
    implements AssuanResponse {
  static const cmd = 'ERR';
  static const handler = AssuanErrorResponseHandler();

  const factory(int code, [String? message]) = _AssuanErrorResponse;

  const new _();

  @override
  String get command => cmd;
}

class AssuanErrorResponseHandler
    implements AssuanMessageHandler<AssuanErrorResponse> {
  const new();

  @override
  bool hasData(_) => true;

  @override
  void encodeData(AssuanErrorResponse message, AssuanDataWriter writer) {
    writer.write(message.code);
    if (message.message case final String msg) {
      writer.write(msg);
    }
  }

  @override
  AssuanErrorResponse decodeData(AssuanDataReader reader) =>
      AssuanErrorResponse(reader.read(), reader.readAllOptional());
}
