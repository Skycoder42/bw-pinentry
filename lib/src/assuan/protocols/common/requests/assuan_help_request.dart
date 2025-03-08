import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/models/assuan_message.dart';
import '../../../core/models/assuan_message_handler.dart';

part 'assuan_help_request.freezed.dart';

@freezed
sealed class AssuanHelpRequest
    with _$AssuanHelpRequest
    implements AssuanRequest {
  static const cmd = 'HELP';
  static const handler = AssuanHelpRequestHandler();

  const factory AssuanHelpRequest() = _AssuanHelpRequest;

  const AssuanHelpRequest._();

  @override
  String get command => cmd;
}

class AssuanHelpRequestHandler
    extends EmptyAssuanMessageHandler<AssuanHelpRequest> {
  const AssuanHelpRequestHandler() : super(AssuanHelpRequest.new);
}
