import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/protocol/base/assuan_message.dart';
import '../../../core/protocol/base/assuan_message_handler.dart';

part 'pinentry_set_repeat_request.freezed.dart';

@freezed
sealed class const PinentrySetRepeatRequest._()
    with _$PinentrySetRepeatRequest
    implements AssuanRequest {
  static const cmd = 'SETREPEAT';
  static const handler = PinentrySetRepeatRequestHandler();

  const factory() = _PinentrySetRepeatRequest;

  @override
  String get command => cmd;
}

class const PinentrySetRepeatRequestHandler()
    extends EmptyAssuanMessageHandler<PinentrySetRepeatRequest> {
  this : super(PinentrySetRepeatRequest.new);
}
