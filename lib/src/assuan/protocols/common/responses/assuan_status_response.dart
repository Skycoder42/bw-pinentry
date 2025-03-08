import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/models/assuan_data_reader.dart';
import '../../../core/models/assuan_data_writer.dart';
import '../../../core/models/assuan_error_code.dart';
import '../../../core/models/assuan_exception.dart';
import '../../../core/models/assuan_message.dart';
import '../../../core/models/assuan_message_handler.dart';

part 'assuan_status_response.freezed.dart';

@freezed
sealed class AssuanStatusResponse
    with _$AssuanStatusResponse
    implements AssuanResponse {
  static const cmd = 'S';
  static const handler = AssuanStatusResponseHandler();

  static final _keywordPattern = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');

  factory AssuanStatusResponse(String keyword, [String? status]) =
      _AssuanStatusResponse;

  AssuanStatusResponse._() {
    if (!_keywordPattern.hasMatch(keyword)) {
      throw AssuanException.code(
        AssuanErrorCode.parameter,
        'Invalid keyword: $keyword',
      );
    }
  }

  @override
  String get command => cmd;
}

class AssuanStatusResponseHandler
    implements AssuanMessageHandler<AssuanStatusResponse> {
  const AssuanStatusResponseHandler();

  @override
  bool hasData(_) => true;

  @override
  void encodeData(AssuanStatusResponse message, AssuanDataWriter writer) {
    writer.write(message.keyword);
    if (message.status case final String status) {
      writer.write(status);
    }
  }

  @override
  AssuanStatusResponse decodeData(AssuanDataReader reader) =>
      AssuanStatusResponse(reader.read(), reader.readAll());
}
