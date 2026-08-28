import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/protocol/base/assuan_message.dart';
import '../../../core/protocol/base/assuan_message_handler.dart';

part 'pinentry_message_request.freezed.dart';

@freezed
sealed class PinentryMessageRequest
    with _$PinentryMessageRequest
    implements AssuanRequest {
  static const cmd = 'MESSAGE';
  static const handler = PinentryMessageRequestHandler();

  const factory() = _PinentryMessageRequest;

  const new _();

  @override
  String get command => cmd;
}

class PinentryMessageRequestHandler
    extends EmptyAssuanMessageHandler<PinentryMessageRequest> {
  const new() : super(PinentryMessageRequest.new);
}
