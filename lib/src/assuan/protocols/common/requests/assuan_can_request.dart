import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/models/assuan_message.dart';
import '../../../core/models/assuan_message_handler.dart';

part 'assuan_can_request.freezed.dart';

@freezed
sealed class AssuanCanRequest with _$AssuanCanRequest implements AssuanRequest {
  static const cmd = 'CAN';
  static const handler = AssuanCanRequestHandler();

  const factory AssuanCanRequest() = _AssuanCanRequest;

  const AssuanCanRequest._();

  @override
  String get command => cmd;
}

class AssuanCanRequestHandler
    extends EmptyAssuanMessageHandler<AssuanCanRequest> {
  const AssuanCanRequestHandler() : super(AssuanCanRequest.new);
}
