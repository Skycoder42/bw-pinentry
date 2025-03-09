import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/protocol/base/assuan_message.dart';
import '../../../core/protocol/base/assuan_message_handler.dart';

part 'pinentry_get_pin_request.freezed.dart';

@freezed
sealed class PinentryGetPinRequest
    with _$PinentryGetPinRequest
    implements AssuanRequest {
  static const cmd = 'GETPIN';
  static const handler = PinentryGetPinRequestHandler();

  const factory PinentryGetPinRequest() = _PinentryGetPinRequest;

  const PinentryGetPinRequest._();

  @override
  String get command => cmd;
}

class PinentryGetPinRequestHandler
    extends EmptyAssuanMessageHandler<PinentryGetPinRequest> {
  const PinentryGetPinRequestHandler() : super(PinentryGetPinRequest.new);
}
