import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/protocol/base/assuan_data_reader.dart';
import '../../../core/protocol/base/assuan_data_writer.dart';
import '../../../core/protocol/base/assuan_message.dart';
import '../../../core/protocol/base/assuan_message_handler.dart';

part 'pinentry_set_timeout_request.freezed.dart';

@freezed
sealed class const PinentrySetTimeoutRequest._()
    with _$PinentrySetTimeoutRequest
    implements AssuanRequest {
  static const cmd = 'SETTIMEOUT';
  static const handler = PinentrySetTimeoutRequestHandler();

  const factory(Duration timeout) = _PinentrySetTimeoutRequest;

  @override
  String get command => cmd;
}

class const PinentrySetTimeoutRequestHandler()
    implements AssuanMessageHandler<PinentrySetTimeoutRequest> {
  @override
  bool hasData(_) => true;

  @override
  void encodeData(PinentrySetTimeoutRequest message, AssuanDataWriter writer) =>
      writer.write(message.timeout.inSeconds);

  @override
  PinentrySetTimeoutRequest decodeData(AssuanDataReader reader) =>
      PinentrySetTimeoutRequest(Duration(seconds: reader.read()));
}
