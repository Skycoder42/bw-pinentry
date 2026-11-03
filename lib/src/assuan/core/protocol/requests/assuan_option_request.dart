import 'package:freezed_annotation/freezed_annotation.dart';

import '../base/assuan_data_reader.dart';
import '../base/assuan_data_writer.dart';
import '../base/assuan_message.dart';
import '../base/assuan_message_handler.dart';

part 'assuan_option_request.freezed.dart';

@freezed
sealed class const AssuanOptionRequest._()
    with _$AssuanOptionRequest
    implements AssuanRequest {
  static const cmd = 'OPTION';
  static const handler = AssuanOptionRequestHandler();

  const factory(String name, [String? value]) = _AssuanOptionRequest;

  @override
  String get command => cmd;
}

class const AssuanOptionRequestHandler()
    implements AssuanMessageHandler<AssuanOptionRequest> {
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
