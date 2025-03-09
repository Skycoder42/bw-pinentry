import 'package:freezed_annotation/freezed_annotation.dart';

import '../base/assuan_message.dart';
import '../base/assuan_message_handler.dart';

part 'assuan_reset_request.freezed.dart';

@freezed
sealed class AssuanResetRequest
    with _$AssuanResetRequest
    implements AssuanRequest {
  static const cmd = 'RESET';
  static const handler = AssuanResetRequestHandler();

  const factory AssuanResetRequest() = _AssuanResetRequest;

  const AssuanResetRequest._();

  @override
  String get command => cmd;
}

class AssuanResetRequestHandler
    extends EmptyAssuanMessageHandler<AssuanResetRequest> {
  const AssuanResetRequestHandler() : super(AssuanResetRequest.new);
}
