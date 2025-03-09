import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/protocol/base/assuan_data_reader.dart';
import '../../../core/protocol/base/assuan_data_writer.dart';
import '../../../core/protocol/base/assuan_message.dart';
import '../../../core/protocol/base/assuan_message_handler.dart';

part 'pinentry_set_keyinfo_request.freezed.dart';

@freezed
sealed class PinentrySetKeyinfoRequest
    with _$PinentrySetKeyinfoRequest
    implements AssuanRequest {
  static const cmd = 'SETKEYINFO';
  static const handler = PinentrySetKeyinfoRequestHandler();

  const factory PinentrySetKeyinfoRequest(String keyGrip) =
      _PinentrySetKeyinfoRequest;

  const PinentrySetKeyinfoRequest._();

  @override
  String get command => cmd;
}

class PinentrySetKeyinfoRequestHandler
    implements AssuanMessageHandler<PinentrySetKeyinfoRequest> {
  const PinentrySetKeyinfoRequestHandler();

  @override
  bool hasData(_) => true;

  @override
  void encodeData(PinentrySetKeyinfoRequest message, AssuanDataWriter writer) =>
      writer.write(message.keyGrip);

  @override
  PinentrySetKeyinfoRequest decodeData(AssuanDataReader reader) =>
      PinentrySetKeyinfoRequest(reader.readAll());
}
