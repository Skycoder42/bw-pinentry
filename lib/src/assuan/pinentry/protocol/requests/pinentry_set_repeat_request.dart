import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/protocol/base/assuan_message.dart';
import '../../../core/protocol/base/assuan_message_handler.dart';

part 'pinentry_set_repeat_request.freezed.dart';

@freezed
sealed class PinentrySetRepeatRequest
    with _$PinentrySetRepeatRequest
    implements AssuanRequest {
  static const cmd = 'SETREPEAT';
  static const handler = PinentrySetRepeatRequestHandler();

  const factory() = _PinentrySetRepeatRequest;

  const new _();

  @override
  String get command => cmd;
}

class PinentrySetRepeatRequestHandler
    extends EmptyAssuanMessageHandler<PinentrySetRepeatRequest> {
  const new() : super(PinentrySetRepeatRequest.new);
}
