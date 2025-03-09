import 'package:freezed_annotation/freezed_annotation.dart';

import '../base/assuan_message.dart';
import '../base/assuan_message_handler.dart';

part 'assuan_nop_request.freezed.dart';

@freezed
sealed class AssuanNopRequest with _$AssuanNopRequest implements AssuanRequest {
  static const cmd = 'NOP';
  static const handler = AssuanNopRequestHandler();

  const factory AssuanNopRequest() = _AssuanNopRequest;

  const AssuanNopRequest._();

  @override
  String get command => cmd;
}

class AssuanNopRequestHandler
    extends EmptyAssuanMessageHandler<AssuanNopRequest> {
  const AssuanNopRequestHandler() : super(AssuanNopRequest.new);
}
