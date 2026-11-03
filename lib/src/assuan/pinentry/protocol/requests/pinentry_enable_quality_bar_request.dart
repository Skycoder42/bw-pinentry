import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/protocol/base/assuan_message.dart';
import '../../../core/protocol/base/assuan_message_handler.dart';

part 'pinentry_enable_quality_bar_request.freezed.dart';

@freezed
sealed class const PinentryEnableQualityBarRequest._()
    with _$PinentryEnableQualityBarRequest
    implements AssuanRequest {
  static const cmd = 'SETQUALITYBAR';
  static const handler = PinentryEnableQualityBarRequestHandler();

  const factory() = _PinentryEnableQualityBarRequest;

  @override
  String get command => cmd;
}

class const PinentryEnableQualityBarRequestHandler()
    extends EmptyAssuanMessageHandler<PinentryEnableQualityBarRequest> {
  this : super(PinentryEnableQualityBarRequest.new);
}
