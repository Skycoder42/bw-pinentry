import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/models/assuan_message.dart';
import '../../../core/models/assuan_message_handler.dart';

part 'assuan_cancel_request.freezed.dart';

@freezed
sealed class AssuanCancelRequest
    with _$AssuanCancelRequest
    implements AssuanRequest {
  static const cmd = 'CAN';
  static const handler = AssuanCancelRequestHandler();

  const factory AssuanCancelRequest() = _AssuanCancelRequest;

  const AssuanCancelRequest._();

  @override
  String get command => cmd;
}

class AssuanCancelRequestHandler
    extends EmptyAssuanMessageHandler<AssuanCancelRequest> {
  const AssuanCancelRequestHandler() : super(AssuanCancelRequest.new);
}
