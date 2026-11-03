import 'package:freezed_annotation/freezed_annotation.dart';

import '../base/assuan_message.dart';
import '../base/assuan_message_handler.dart';

part 'assuan_reset_request.freezed.dart';

@freezed
sealed class const AssuanResetRequest._()
    with _$AssuanResetRequest
    implements AssuanRequest {
  static const cmd = 'RESET';
  static const handler = AssuanResetRequestHandler();

  const factory() = _AssuanResetRequest;

  @override
  String get command => cmd;
}

class const AssuanResetRequestHandler()
    extends EmptyAssuanMessageHandler<AssuanResetRequest> {
  this : super(AssuanResetRequest.new);
}
