import 'package:freezed_annotation/freezed_annotation.dart';

import '../base/assuan_message.dart';
import '../base/assuan_message_handler.dart';

part 'assuan_cancel_request.freezed.dart';

@freezed
sealed class const AssuanCancelRequest._()
    with _$AssuanCancelRequest
    implements AssuanRequest {
  static const cmd = 'CAN';
  static const handler = AssuanCancelRequestHandler();

  const factory() = _AssuanCancelRequest;

  @override
  String get command => cmd;
}

class const AssuanCancelRequestHandler()
    extends EmptyAssuanMessageHandler<AssuanCancelRequest> {
  this : super(AssuanCancelRequest.new);
}
