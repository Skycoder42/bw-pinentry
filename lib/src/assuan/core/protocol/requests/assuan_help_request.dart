import 'package:freezed_annotation/freezed_annotation.dart';

import '../base/assuan_message.dart';
import '../base/assuan_message_handler.dart';

part 'assuan_help_request.freezed.dart';

@freezed
sealed class const AssuanHelpRequest._()
    with _$AssuanHelpRequest
    implements AssuanRequest {
  static const cmd = 'HELP';
  static const handler = AssuanHelpRequestHandler();

  const factory() = _AssuanHelpRequest;

  @override
  String get command => cmd;
}

class const AssuanHelpRequestHandler()
    extends EmptyAssuanMessageHandler<AssuanHelpRequest> {
  this : super(AssuanHelpRequest.new);
}
