import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/protocol/base/assuan_data_reader.dart';
import '../../../core/protocol/base/assuan_data_writer.dart';
import '../../../core/protocol/base/assuan_message.dart';
import '../../../core/protocol/base/assuan_message_handler.dart';

part 'pinentry_get_info_request.freezed.dart';

enum PinentryInfoKey { flavor, version, ttyinfo, pid }

@freezed
sealed class PinentryGetInfoRequest
    with _$PinentryGetInfoRequest
    implements AssuanRequest {
  static const cmd = 'GETINFO';
  static const handler = PinentryGetInfoRequestHandler();

  const factory PinentryGetInfoRequest(PinentryInfoKey key) =
      _PinentryGetInfoRequest;

  const PinentryGetInfoRequest._();

  @override
  String get command => cmd;
}

class PinentryGetInfoRequestHandler
    implements AssuanMessageHandler<PinentryGetInfoRequest> {
  const PinentryGetInfoRequestHandler();

  @override
  bool hasData(_) => true;

  @override
  void encodeData(PinentryGetInfoRequest message, AssuanDataWriter writer) =>
      writer.write(message.key.name);

  @override
  PinentryGetInfoRequest decodeData(AssuanDataReader reader) =>
      PinentryGetInfoRequest(PinentryInfoKey.values.byName(reader.read()));
}
