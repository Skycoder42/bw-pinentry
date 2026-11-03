import 'package:freezed_annotation/freezed_annotation.dart';

import '../base/assuan_message.dart';
import '../base/assuan_message_handler.dart';

part 'assuan_end_request.freezed.dart';

@freezed
sealed class const AssuanEndRequest._()
    with _$AssuanEndRequest
    implements AssuanRequest {
  static const cmd = 'END';
  static const handler = AssuanEndRequestHandler();

  const factory() = _AssuanEndRequest;

  @override
  String get command => cmd;
}

class const AssuanEndRequestHandler()
    extends EmptyAssuanMessageHandler<AssuanEndRequest> {
  this : super(AssuanEndRequest.new);
}
