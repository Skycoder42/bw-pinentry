import 'package:freezed_annotation/freezed_annotation.dart';

import '../base/assuan_message.dart';
import '../base/assuan_message_handler.dart';

part 'assuan_bye_request.freezed.dart';

@freezed
sealed class AssuanByeRequest with _$AssuanByeRequest implements AssuanRequest {
  static const cmd = 'BYE';
  static const handler = AssuanByeRequestHandler();

  const factory AssuanByeRequest() = _AssuanByeRequest;

  const AssuanByeRequest._();

  @override
  String get command => cmd;
}

class AssuanByeRequestHandler
    extends EmptyAssuanMessageHandler<AssuanByeRequest> {
  const AssuanByeRequestHandler() : super(AssuanByeRequest.new);
}
