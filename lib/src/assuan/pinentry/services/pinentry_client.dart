import 'dart:io';

import 'package:stream_channel/stream_channel.dart';

import '../../core/protocol/base/assuan_exception.dart';
import '../../core/services/assuan_client.dart';
import '../../core/services/models/inquiry_reply.dart';
import '../protocol/pinentry_protocol.dart';
import '../protocol/requests/pinentry_confirm_request.dart';
import '../protocol/requests/pinentry_enable_quality_bar_request.dart';
import '../protocol/requests/pinentry_get_info_request.dart';
import '../protocol/requests/pinentry_get_pin_request.dart';
import '../protocol/requests/pinentry_message_request.dart';
import '../protocol/requests/pinentry_set_gen_pin_request.dart';
import '../protocol/requests/pinentry_set_keyinfo_request.dart';
import '../protocol/requests/pinentry_set_repeat_request.dart';
import '../protocol/requests/pinentry_set_text_request.dart';
import '../protocol/requests/pinentry_set_timeout_request.dart';

abstract class PinentryClient extends AssuanClient {
  PinentryClient(
    StreamChannel<String> channel, {
    super.terminateSignal,
    super.forceCloseCallback,
    super.forceCloseTimeout,
  }) : super(PinentryProtocol(), channel);

  PinentryClient.raw(
    StreamChannel<List<int>> channel, {
    super.encoding,
    super.terminateSignal,
    super.forceCloseCallback,
    super.forceCloseTimeout,
  }) : super.raw(PinentryProtocol(), channel);

  PinentryClient.process(
    Process process, {
    super.encoding,
    super.forceCloseTimeout,
  }) : super.process(PinentryProtocol(), process);

  Future<String> getInfo(PinentryInfoKey key) =>
      sendRequest(PinentryGetInfoRequest(key));

  Future<void> setTimeout(Duration timeout) =>
      sendAction(PinentrySetTimeoutRequest(timeout));

  Future<void> setText(SetCommand command, String text) =>
      sendAction(PinentrySetTextRequest(command, text));

  Future<void> setKeyinfo(String keyGrip) =>
      sendAction(PinentrySetKeyinfoRequest(keyGrip));

  Future<void> enableQualityBar() =>
      sendAction(const PinentryEnableQualityBarRequest());

  Future<void> enablePinGeneration() =>
      sendAction(const PinentrySetGenPinRequest());

  Future<void> enableRepeat() => sendAction(const PinentrySetRepeatRequest());

  Future<String> getPin() => sendRequest(const PinentryGetPinRequest());

  Future<bool> confirm() async {
    try {
      await sendAction(const PinentryConfirmRequest());
      return true;
    } on AssuanException catch (e) {
      if (e.code == PinentryConfirmRequest.notConfirmedCode) {
        return false;
      }
      rethrow;
    }
  }

  Future<void> showMessage() => sendAction(const PinentryMessageRequest());

  @override
  Future<InquiryReply> onInquire(String keyword, List<String> parameters) =>
      Future.value(const InquiryReply.cancel());
}
