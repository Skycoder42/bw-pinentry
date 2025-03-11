import 'dart:io';

import 'package:async/async.dart';
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
import '../bitwarden/bitwarden_cli.dart';
import '../bitwarden/models/bw_object.dart';
import '../bitwarden/models/bw_status.dart';
import 'bw_pinentry_client.dart';

final class BwPinentryServer extends PinentryServer {
  static const _folderName = 'GPG-Keys';

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
      final pin = await _getPinFromBitwarden(keyGrip);
      if (pin != null) {
        return ServerReply.data(pin);
      } else {
        await _resetClientTexts();
      }
    }

    final pin = await _client.getPin();
    return ServerReply.data(pin);
  }

  Future<String?> _getPinFromBitwarden(String keyGrip) async {
    try {
      if (!await _ensureUnlocked()) {
        return null;
      }

      final folder = await _getBitwardenFolder();
      final item = await _getBitwardenItem(keyGrip, folder);
      if (item?.login?.password case final String password) {
        return password;
      }

      final password = await _client.getPin();

      if (item != null) {
        await _client.setText(
          SetCommand.description,
          'Save passphrase with existing item "${item.name}"?',
        );
      } else {
        await _client.setText(
          SetCommand.description,
          'Create new item in folder "${folder?.name}" '
          'to persist the passphrase?',
        );
      }

      final shouldPersist = await _client.confirm();
      if (!shouldPersist) {
        return password;
      }
    } finally {
      await _bwCli.lock();
    }
    return null;
  }

  Future<bool> _ensureUnlocked() async {
    sendComment('Checking bitwarden CLI status');
    final status = await _bwCli.status();
    switch (status.status) {
      case Status.unauthenticated:
        await _client.setText(
          SetCommand.description,
          'Bitwarden CLI is not logged in! Please log in and try again. '
          'Continuing without bitwarden integration.',
        );
        await _client.showMessage();
        return false;
      case Status.locked:
        await _unlock(status);
        return true;
      case Status.unlocked:
        sendComment('WARNING: bitwarden sessions was already unlocked!');
        return true;
    }
  }

  Future<void> _unlock(BwStatus status) async {
    await _client.setText(SetCommand.title, 'Bitwarden Authentication');
    await _client.setText(
      SetCommand.description,
      'Please enter the master password '
      'for the bitwarden account "${status.userEmail}"',
    );
    for (var i = 0; i < 2; ++i) {
      try {
        final masterPassword = await _getMasterPassword(status);
        await _bwCli.unlock(masterPassword);
        return;
      } on Exception catch (e) {
        sendComment('Failed to unlock bitwarden with error: $e');
        await _client.setText(
          SetCommand.error,
          'Invalid Password! Please try again (Attempt ${i + 2}/3)',
        );
      }
    }

    throw AssuanException('Failed to unlock bitwarden after 3 attempts');
  }

  Future<String> _getMasterPassword(BwStatus status) async {
    await _client.setText(SetCommand.prompt, 'Master-Password');
    return await _client.getPin();
  }

  Future<BwFolder?> _getBitwardenFolder() async {
    sendComment('Searching for folder to narrow down search');
    return await _bwCli.listFolders(search: _folderName).firstOrNull;
  }

  Future<BwItem?> _getBitwardenItem(String keyGrip, BwFolder? folder) async {
    sendComment('Searching for items within folder: ${folder?.name}');
    final items = await _bwCli.listItems(folderId: folder?.id).toList();
    sendComment('Found ${items.length} potential items');
    final matchingItems = items.where(_filterKeyGrip(keyGrip)).toList();
    switch (matchingItems) {
      case []:
        await _setMatchFailure('No matching items found!', keyGrip);
        return null;
      case [final item]:
        sendComment('Found one matching item');
        return item;
      default:
        await _setMatchFailure('Found more then one matching item!', keyGrip);
        return null;
    }
  }

  Future<void> _resetClientTexts() async {
    for (final MapEntry(:key, :value) in _textCache.entries) {
      await _client.setText(key, value);
    }
  }

  bool Function(BwItem) _filterKeyGrip(String keyGrip) =>
      (i) => i.fields.any((f) => f.name == 'keygrip' && f.value == keyGrip);

  Future<void> _setMatchFailure(String message, String keyGrip) async {
    sendComment(message);
    await _resetClientTexts();
    await _client.setText(SetCommand.error, message);
  }
}
