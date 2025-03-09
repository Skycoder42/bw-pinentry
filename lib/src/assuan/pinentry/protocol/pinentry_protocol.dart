import '../../core/protocol/assuan_protocol.dart';
import 'requests/pinentry_confirm_request.dart';
import 'requests/pinentry_enable_quality_bar_request.dart';
import 'requests/pinentry_get_info_request.dart';
import 'requests/pinentry_get_pin_request.dart';
import 'requests/pinentry_message_request.dart';
import 'requests/pinentry_set_gen_pin_request.dart';
import 'requests/pinentry_set_keyinfo_request.dart';
import 'requests/pinentry_set_repeat_request.dart';
import 'requests/pinentry_set_text_request.dart';
import 'requests/pinentry_set_timeout_request.dart';

final class PinentryProtocol extends AssuanProtocol {
  PinentryProtocol()
    : super({
        PinentryConfirmRequest.cmd: PinentryConfirmRequest.handler,
        PinentryEnableQualityBarRequest.cmd:
            PinentryEnableQualityBarRequest.handler,
        PinentryGetInfoRequest.cmd: PinentryGetInfoRequest.handler,
        PinentryGetPinRequest.cmd: PinentryGetPinRequest.handler,
        PinentryMessageRequest.cmd: PinentryMessageRequest.handler,
        PinentrySetGenPinRequest.cmd: PinentrySetGenPinRequest.handler,
        PinentrySetKeyinfoRequest.cmd: PinentrySetKeyinfoRequest.handler,
        PinentrySetRepeatRequest.cmd: PinentrySetRepeatRequest.handler,
        for (final cmd in PinentrySetTextRequest.cmds)
          cmd: PinentrySetTextRequest.handler,
        PinentrySetTimeoutRequest.cmd: PinentrySetTimeoutRequest.handler,
      });
}
