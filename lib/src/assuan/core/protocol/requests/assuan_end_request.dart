import 'package:freezed_annotation/freezed_annotation.dart';

import '../base/assuan_message.dart';
import '../base/assuan_message_handler.dart';

part 'assuan_end_request.freezed.dart';

@freezed
sealed class AssuanEndRequest with _$AssuanEndRequest implements AssuanRequest {
  static const cmd = 'END';
  static const handler = AssuanEndRequestHandler();

  const factory() = _AssuanEndRequest;

  const new _();

  @override
  String get command => cmd;
}

class AssuanEndRequestHandler
    extends EmptyAssuanMessageHandler<AssuanEndRequest> {
  const new() : super(AssuanEndRequest.new);
}
