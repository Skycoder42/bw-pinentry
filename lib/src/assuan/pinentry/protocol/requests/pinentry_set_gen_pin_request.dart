import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/protocol/base/assuan_message.dart';
import '../../../core/protocol/base/assuan_message_handler.dart';

part 'pinentry_set_gen_pin_request.freezed.dart';

@freezed
sealed class PinentrySetGenPinRequest
    with _$PinentrySetGenPinRequest
    implements AssuanRequest {
  static const cmd = 'SETGENPIN';
  static const handler = PinentrySetGenPinRequestHandler();

  const factory PinentrySetGenPinRequest() = _PinentrySetGenPinRequest;

  const PinentrySetGenPinRequest._();

  @override
  String get command => cmd;
}

class PinentrySetGenPinRequestHandler
    extends EmptyAssuanMessageHandler<PinentrySetGenPinRequest> {
  const PinentrySetGenPinRequestHandler() : super(PinentrySetGenPinRequest.new);
}
