import 'package:freezed_annotation/freezed_annotation.dart';

import '../base/assuan_message.dart';
import '../base/assuan_message_handler.dart';

part 'assuan_end_request.freezed.dart';

@freezed
sealed class AssuanEndRequest with _$AssuanEndRequest implements AssuanRequest {
  static const cmd = 'END';
  static const handler = AssuanEndRequestHandler();

  const factory AssuanEndRequest() = _AssuanEndRequest;

  const AssuanEndRequest._();

  @override
  String get command => cmd;
}

class AssuanEndRequestHandler
    extends EmptyAssuanMessageHandler<AssuanEndRequest> {
  const AssuanEndRequestHandler() : super(AssuanEndRequest.new);
}
