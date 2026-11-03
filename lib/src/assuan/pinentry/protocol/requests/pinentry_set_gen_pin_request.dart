import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/protocol/base/assuan_message.dart';
import '../../../core/protocol/base/assuan_message_handler.dart';

part 'pinentry_set_gen_pin_request.freezed.dart';

@freezed
sealed class const PinentrySetGenPinRequest._()
    with _$PinentrySetGenPinRequest
    implements AssuanRequest {
  static const cmd = 'SETGENPIN';
  static const handler = PinentrySetGenPinRequestHandler();

  const factory() = _PinentrySetGenPinRequest;

  @override
  String get command => cmd;
}

class const PinentrySetGenPinRequestHandler()
    extends EmptyAssuanMessageHandler<PinentrySetGenPinRequest> {
  this : super(PinentrySetGenPinRequest.new);
}
