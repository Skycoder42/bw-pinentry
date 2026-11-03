import 'package:freezed_annotation/freezed_annotation.dart';

import '../base/assuan_message.dart';
import '../base/assuan_message_handler.dart';

part 'assuan_bye_request.freezed.dart';

@freezed
sealed class const AssuanByeRequest._()
    with _$AssuanByeRequest
    implements AssuanRequest {
  static const cmd = 'BYE';
  static const handler = AssuanByeRequestHandler();

  const factory() = _AssuanByeRequest;

  @override
  String get command => cmd;
}

class const AssuanByeRequestHandler()
    extends EmptyAssuanMessageHandler<AssuanByeRequest> {
  this : super(AssuanByeRequest.new);
}
