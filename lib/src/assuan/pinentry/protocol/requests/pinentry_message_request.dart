import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/protocol/base/assuan_message.dart';
import '../../../core/protocol/base/assuan_message_handler.dart';

part 'pinentry_message_request.freezed.dart';

@freezed
sealed class const PinentryMessageRequest._()
    with _$PinentryMessageRequest
    implements AssuanRequest {
  static const cmd = 'MESSAGE';
  static const handler = PinentryMessageRequestHandler();

  const factory() = _PinentryMessageRequest;

  @override
  String get command => cmd;
}

class const PinentryMessageRequestHandler()
    extends EmptyAssuanMessageHandler<PinentryMessageRequest> {
  this : super(PinentryMessageRequest.new);
}
