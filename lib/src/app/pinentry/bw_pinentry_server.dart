import 'dart:io';

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
import '../../assuan/pinentry/services/pinentry_client.dart';
import '../../assuan/pinentry/services/pinentry_server.dart';
import '../bitwarden/bitwarden_cli.dart';
import '../bitwarden/models/bw_status.dart';
import 'bw_pinentry_client.dart';

final class BwPinentryServer extends PinentryServer {
  final List<String> _arguments;

  final _bwCli = BitwardenCli();
  late final BwPinentryClient _client;

  final _textCache = <SetCommand, String>{};
  String? _keyGrip;

  BwPinentryServer(super.stdin, super.stdout, this._arguments) : super.io();

  Stream<String> forwardInquiry(String keyword, List<String> parameters) {
    sendComment('Forwarding INQUIRE $keyword from client');
    return startInquire(keyword, parameters);
  }

  void forwardStatus(String keyword, String status) {
    sendComment('Forwarding STATUS $keyword from client');
    sendStatus(keyword, status);
  }

  @override
  @protected
  Future<void> init() async {
    final pinentry = Platform.environment['PINENTRY'] ?? 'pinentry';
    sendComment(
      'Server ready. Starting proxied $pinentry with arguments $_arguments...',
    );
    _client = await BwPinentryClient.start(this, pinentry, _arguments);
    sendComment('Proxy is ready.');
    return super.init();
  }

  @override
  @protected
  Future<void> setOption(String name, String? value) =>
      _client.setOption(name, value);

  @override
  @protected
  Future<void> reset({bool closing = false}) async {
    if (!closing) {
      _textCache.clear();
      _keyGrip = null;
      await _client.reset();
    }
    await super.reset(closing: closing);
  }

  @override
  @protected
  Future<void> finalize() async {
    await _client.close();
    await super.finalize();
  }

  @override
  @protected
  Future<ServerReply> handleRequest(AssuanRequest request) async {
    switch (request) {
      case PinentryGetInfoRequest(:final key):
        final info = await _client.getInfo(key);
        return ServerReply.data(info);
      case PinentrySetTextRequest(:final setCommand, :final text):
        _textCache[setCommand] = text;
        await _client.setText(setCommand, text);
        return const OkReply();
      case PinentrySetTimeoutRequest(:final timeout):
        await _client.setTimeout(timeout);
        return const OkReply();
      case PinentryEnableQualityBarRequest():
        await _client.enableQualityBar();
        return const OkReply();
      case PinentrySetGenPinRequest():
        await _client.enablePinGeneration();
        return const OkReply();
      case PinentrySetRepeatRequest():
        await _client.enableRepeat();
        return const OkReply();
      case PinentrySetKeyinfoRequest(:final keyGrip):
        _keyGrip = keyGrip;
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

  Future<ServerReply> _showMessage() async {
    await _client.showMessage();
    return const ServerReply.ok();
  }

  Future<ServerReply> _confirm() async {
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

    final pin = await _client.getPin();
    return ServerReply.data(pin);
  }

  Future<void> _resetClientTexts() async {
    for (final MapEntry(:key, :value) in _textCache.entries) {
      await _client.setText(key, value);
    }
  }

  Future<String?> _getBitwardenKey(String keyGrip) async {
    sendComment('Checking bitwarden CLI status');
    final status = await _bwCli.status();
    switch (status.status) {
      case Status.unauthenticated:
        await _client.setText(
          SetCommand.description,
          'Bitwarden CLI is not logged in! Please log in and try again.',
        );
        await _client.showMessage();
        return null;
      case Status.locked:
        if (!await _unlock(status)) {
          return null;
        }
      case Status.unlocked:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
    return null;
  }

  Future<bool> _unlock(BwStatus status) async {
    await _client.setText(SetCommand.title, 'Bitwarden Authentication');
    await _client.setText(
      SetCommand.description,
      'Please enter the master password '
      'for the bitwarden account "${status.userEmail}"',
    );
    for (var i = 0; i < 3; ++i) {
      try {
        final masterPassword = await _getMasterPassword(status);
        await _bwCli.unlock(masterPassword);
        return true;
      } on Exception catch (e) {
        sendComment('Failed to unlock bitwarden with error: $e');
        await _client.setText(
          SetCommand.error,
          'Invalid Password! Please try again (Attempt ${i + 2}/3)',
        );
      }
    }

    sendComment('Failed to unlock bitwarden after 3 attempts');
    return false;
  }

  Future<String> _getMasterPassword(BwStatus status) async {
    await _client.setText(SetCommand.prompt, 'Master-Password');
    return await _client.getPin();
  }
}
