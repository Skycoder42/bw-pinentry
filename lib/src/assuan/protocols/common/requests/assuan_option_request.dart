import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/models/assuan_data_reader.dart';
import '../../../core/models/assuan_data_writer.dart';
import '../../../core/models/assuan_message.dart';
import '../../../core/models/assuan_message_handler.dart';

part 'assuan_option_request.freezed.dart';

@freezed
sealed class AssuanOptionRequest
    with _$AssuanOptionRequest
    implements AssuanRequest {
  static const cmd = 'OPTION';
  static const handler = AssuanOptionRequestHandler();

  const factory AssuanOptionRequest(String name, [String? value]) =
      _AssuanOptionRequest;

  const AssuanOptionRequest._();

  @override
  String get command => cmd;
}

class AssuanOptionRequestHandler
    implements AssuanMessageHandler<AssuanOptionRequest> {
  const AssuanOptionRequestHandler();

  @override
  bool hasData(_) => true;

  @override
  void encodeData(AssuanOptionRequest message, AssuanDataWriter writer) {
    writer.write(message.name);
    if (message.value case final String value) {
      writer
        ..write('=', autoSpace: false)
        ..write(value, autoSpace: false);
    }
  }

  @override
  AssuanOptionRequest decodeData(AssuanDataReader reader) {
    var data = reader.readAll();
    if (data.startsWith('--')) {
      data = data.substring(2);
    }

    final equalsIndex = data.indexOf('=');
    if (equalsIndex == -1) {
      return AssuanOptionRequest(data);
    } else {
      return AssuanOptionRequest(
        data.substring(0, equalsIndex).trim(),
        data.substring(equalsIndex + 1).trim(),
      );
    }
  }
}
