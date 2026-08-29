import 'package:freezed_annotation/freezed_annotation.dart';

import '../base/assuan_message.dart';
import '../base/assuan_message_handler.dart';

part 'assuan_help_request.freezed.dart';

@freezed
sealed class AssuanHelpRequest
    with _$AssuanHelpRequest
    implements AssuanRequest {
  static const cmd = 'HELP';
  static const handler = AssuanHelpRequestHandler();

  const factory() = _AssuanHelpRequest;

  const new _();

  @override
  String get command => cmd;
}

class AssuanHelpRequestHandler
    extends EmptyAssuanMessageHandler<AssuanHelpRequest> {
  const new() : super(AssuanHelpRequest.new);
}
