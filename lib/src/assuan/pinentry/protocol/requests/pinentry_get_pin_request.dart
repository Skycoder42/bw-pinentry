import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/protocol/base/assuan_message.dart';
import '../../../core/protocol/base/assuan_message_handler.dart';

part 'pinentry_get_pin_request.freezed.dart';

@freezed
sealed class const PinentryGetPinRequest._()
    with _$PinentryGetPinRequest
    implements AssuanRequest {
  static const cmd = 'GETPIN';
  static const handler = PinentryGetPinRequestHandler();

  const factory() = _PinentryGetPinRequest;

  @override
  String get command => cmd;
}

class const PinentryGetPinRequestHandler()
    extends EmptyAssuanMessageHandler<PinentryGetPinRequest> {
  this : super(PinentryGetPinRequest.new);
}
