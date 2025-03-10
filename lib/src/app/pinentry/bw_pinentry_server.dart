import 'package:meta/meta.dart';

import '../../assuan/core/protocol/base/assuan_error_code.dart';
import '../../assuan/core/protocol/base/assuan_exception.dart';
import '../../assuan/core/protocol/base/assuan_message.dart';
import '../../assuan/core/services/models/server_reply.dart';
import '../../assuan/pinentry/protocol/requests/pinentry_confirm_request.dart';
import '../../assuan/pinentry/protocol/requests/pinentry_enable_quality_bar_request.dart';
import '../../assuan/pinentry/protocol/requests/pinentry_get_info_request.dart';
import '../../assuan/pinentry/protocol/requests/pinentry_get_pin_request.dart';
import '../../assuan/pinentry/protocol/requests/pinentry_message_request.dart';
import '../../assuan/pinentry/protocol/requests/pinentry_set_gen_pin_request.dart';
import '../../assuan/pinentry/protocol/requests/pinentry_set_keyinfo_request.dart';
import '../../assuan/pinentry/protocol/requests/pinentry_set_repeat_request.dart';
import '../../assuan/pinentry/protocol/requests/pinentry_set_text_request.dart';
import '../../assuan/pinentry/protocol/requests/pinentry_set_timeout_request.dart';
import '../../assuan/pinentry/services/pinentry_server.dart';
import 'bw_pinentry_client.dart';
import 'bw_status.dart';

final class BwPinentryServer extends PinentryServer {
  late final BwPinentryClient _client;

  final _textCache = <SetCommand, String>{};
  String? _keyGrip;

  BwPinentryServer(super.stdin, super.stdout) : super.io();

  Stream<String> forwardInquiry(String keyword, List<String> parameters) {
    sendComment('Forwarding INQUIRE $keyword $parameters');
    return startInquire(keyword, parameters);
  }

  void forwardStatus(String keyword, String status) {
    sendComment('Forwarding STATUS $keyword $status');
    sendStatus(keyword, status);
  }

  @override
  @protected
  Future<void> init() async {
    _sendBwStatus(
      const BwStatus.proxy('Server ready. Starting proxied pinentry...'),
    );
    _client = await BwPinentryClient.start(this);
    _sendBwStatus(const BwStatus.proxy('Proxy is ready.'));
    return super.init();
  }

  @override
  @protected
  Future<void> setOption(String name, String? value) {
    sendComment('Forwarding OPTION $name = $value');
    return _client.setOption(name, value);
  }

  @override
  @protected
  Future<void> reset({bool closing = false}) async {
    if (!closing) {
      _textCache.clear();
      _keyGrip = null;
      sendComment('Forwarding RESET');
      await _client.reset();
    }
    await super.reset(closing: closing);
  }

  @override
  @protected
  Future<void> close() async {
    sendComment('Forwarding BYE');
    await _client.close();
    sendComment('Client terminated');
    await super.close();
  }

  @override
  @protected
  Future<ServerReply> handleRequest(AssuanRequest request) async {
    switch (request) {
      case PinentryGetInfoRequest(:final key):
        sendComment('Forwarding ${request.command} $key');
        final info = await _client.getInfo(key);
        return ServerReply.data(info);
      case PinentrySetTextRequest(:final setCommand, :final text):
        _textCache[setCommand] = text;
        sendComment('Forwarding ${request.command} $text');
        await _client.setText(setCommand, text);
        return const OkReply();
      case PinentrySetTimeoutRequest(:final timeout):
        sendComment('Forwarding ${request.command} $timeout');
        await _client.setTimeout(timeout);
        return const OkReply();
      case PinentryEnableQualityBarRequest():
        sendComment('Forwarding ${request.command}');
        await _client.enableQualityBar();
        return const OkReply();
      case PinentrySetGenPinRequest():
        sendComment('Forwarding ${request.command}');
        await _client.enablePinGeneration();
        return const OkReply();
      case PinentrySetRepeatRequest():
        sendComment('Forwarding ${request.command}');
        await _client.enableRepeat();
        return const OkReply();
      case PinentrySetKeyinfoRequest(:final keyGrip):
        _keyGrip = keyGrip;
        sendComment('Forwarding ${request.command} $keyGrip');
        await _client.setKeyinfo(keyGrip);
        return const OkReply();
      case PinentryMessageRequest():
      case PinentryConfirmRequest(oneButton: true):
        return _showMessage();
      case PinentryConfirmRequest(oneButton: false):
        return _confirm();
      case PinentryGetPinRequest():
        return _getPin();
      default:
        throw AssuanException.code(
          AssuanErrorCode.unknownCmd,
          'Unknown command <${request.command}>',
        );
    }
  }

  void _sendBwStatus(BwStatus status) =>
      sendStatus(status.keyword, status.status);

  Future<ServerReply> _showMessage() async {
    sendComment('Forwarding MESSAGE');
    await _client.showMessage();
    return const ServerReply.ok();
  }

  Future<ServerReply> _confirm() async {
    sendComment('Forwarding CONFIRM');
    final response = await _client.confirm();
    if (!response) {
      throw AssuanException(
        'prompt was not confirmed',
        PinentryConfirmRequest.notConfirmedCode,
      );
    }
    return const ServerReply.ok();
  }

  Future<ServerReply> _getPin() async {
    if (_keyGrip case final String keyGrip) {
      final passphrase = await _getBitwardenKey(keyGrip);
      if (passphrase != null) {
        return ServerReply.data(passphrase);
      } else {
        await _resetClientTexts();
      }
    }

    sendComment('Forwarding GETPIN');
    final pin = await _client.getPin();
    return ServerReply.data(pin);
  }

  Future<void> _resetClientTexts() async {
    final client = await BwPinentryClient.start(this);
    for (final MapEntry(:key, :value) in _textCache.entries) {
      sendComment('Forwarding ${key.command} $value');
      await client.setText(key, value);
    }
  }

  Future<String?> _getBitwardenKey(String keyGrip) async {
    final ok = await _client.confirm();
    return ok ? keyGrip : null;
  }
}
