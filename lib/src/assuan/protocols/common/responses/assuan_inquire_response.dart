import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/models/assuan_data_reader.dart';
import '../../../core/models/assuan_data_writer.dart';
import '../../../core/models/assuan_message.dart';
import '../../../core/models/assuan_message_handler.dart';

part 'assuan_inquire_response.freezed.dart';

@freezed
sealed class AssuanInquireResponse
    with _$AssuanInquireResponse
    implements AssuanResponse {
  static const cmd = 'INQUIRE';
  static const handler = AssuanInquireResponseHandler();

  const factory AssuanInquireResponse(
    String keyword, [
    @Default([]) List<String> parameters,
  ]) = _AssuanInquireResponse;

  const AssuanInquireResponse._();

  @override
  String get command => cmd;
}

class AssuanInquireResponseHandler
    implements AssuanMessageHandler<AssuanInquireResponse> {
  const AssuanInquireResponseHandler();

  @override
  bool hasData(_) => true;

  @override
  void encodeData(AssuanInquireResponse message, AssuanDataWriter writer) {
    writer.write(message.keyword);
    message.parameters.forEach(writer.write);
  }

  @override
  AssuanInquireResponse decodeData(AssuanDataReader reader) {
    final keyword = reader.read<String>();
    final parameters = [for (; reader.hasMoreData();) reader.read<String>()];
    return AssuanInquireResponse(keyword, parameters);
  }
}
