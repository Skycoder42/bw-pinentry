import 'package:freezed_annotation/freezed_annotation.dart';

import '../base/assuan_message.dart';
import '../base/assuan_message_handler.dart';

part 'assuan_nop_request.freezed.dart';

@freezed
sealed class const AssuanNopRequest._()
    with _$AssuanNopRequest
    implements AssuanRequest {
  static const cmd = 'NOP';
  static const handler = AssuanNopRequestHandler();

  const factory() = _AssuanNopRequest;

  @override
  String get command => cmd;
}

class const AssuanNopRequestHandler()
    extends EmptyAssuanMessageHandler<AssuanNopRequest> {
  this : super(AssuanNopRequest.new);
}
