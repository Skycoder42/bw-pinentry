import 'dart:io';

import 'package:async/async.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
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
import '../bitwarden/models/bw_item_type.dart';
import '../bitwarden/models/bw_login.dart';
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
  bool _skipBitwarden = false;

  BwPinentryServer(super.stdin, super.stdout, this._arguments) : super.io();

  Stream<String> forwardInquiry(String keyword, List<String> parameters) =>
      startInquire(keyword, parameters);

  void forwardStatus(String keyword, String status) {
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
    await _bwCli.lock();
    if (!closing) {
      _textCache.clear();
      _keyGrip = null;
      _skipBitwarden = false;
      await _client.reset();
    }
    await super.reset(closing: closing);
  }

  @override
  @protected
  Future<void> finalize() async {
    await _bwCli.lock();
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
        'Prompt was not confirmed',
        PinentryServer.notConfirmedCode,
      );
    }
    return const ServerReply.ok();
  }

  Future<ServerReply> _getPin() async {
    if (_keyGrip case final String keyGrip when !_skipBitwarden) {
      final pin = await _getPinFromBitwarden(keyGrip);
      if (pin != null) {
        return ServerReply.data(pin);
      }
      _skipBitwarden = true;
    }

    final pin = await _client.getPin();
    if (pin != null) {
      return ServerReply.data(pin);
    } else {
      throw AssuanException(
        'Prompt was not confirmed',
        PinentryServer.notConfirmedCode,
      );
    }
  }

  Future<String?> _getPinFromBitwarden(String keyGrip) async {
    try {
      final status = await _ensureUnlocked();
      if (status == null) {
        await _resetClientTexts();
        return null;
      }

      var synced = false;
      if (status.lastSync case final DateTime dt
          when DateTime.now().difference(dt) > const Duration(days: 1)) {
        sendComment('Last sync was on $dt. Syncing bitwarden vault');
        await _bwCli.sync();
        synced = true;
      }

      return await _findPassword(keyGrip, synced: synced);
    } finally {
      await _bwCli.lock();
    }
  }

  Future<BwStatus?> _ensureUnlocked() async {
    sendComment('Checking bitwarden CLI status');
    final status = await _bwCli.status();
    switch (status.status) {
      case Status.unauthenticated:
        await _client.setText(
          SetCommand.error,
          'Bitwarden CLI is not logged in! '
          'Continuing without bitwarden integration.',
        );
        return null;
      case Status.locked:
        if (await _unlock(status)) {
          return status.copyWith(status: Status.unlocked);
        } else {
          return null;
        }
      case Status.unlocked:
        sendComment('WARNING: bitwarden sessions was already unlocked!');
        return status;
    }
  }

  Future<bool> _unlock(BwStatus status) async {
    final descBuffer = StringBuffer();
    if (_textCache case {SetCommand.description: final description}) {
      descBuffer.writeln(description);
    }
    descBuffer
      ..write('Please enter the master password for the bitwarden account "')
      ..write(status.userEmail)
      ..write('"')
      ..writeln();

    await _client.setText(SetCommand.title, 'Bitwarden Authentication');
    await _client.setText(SetCommand.description, descBuffer.toString());
    await _client.setText(SetCommand.prompt, 'Master-Password');
    for (var attempt = 1; attempt <= 3; ++attempt) {
      if (attempt > 1) {
        await _client.setText(
          SetCommand.error,
          'Invalid Password! Please try again (Attempt $attempt/3)',
        );
      }

      try {
        final masterPassword = await _client.getPin();
        if (masterPassword == null) {
          return false;
        }

        await _bwCli.unlock(masterPassword);
        return true;
      } on Exception catch (e) {
        sendComment('Failed to unlock bitwarden with error: $e');
      }
    }

    throw AssuanException('Failed to unlock bitwarden after 3 attempts');
  }

  Future<String?> _findPassword(String keyGrip, {bool synced = false}) async {
    sendComment('Searching for folder to narrow down search');
    final folder = await _bwCli.listFolders(search: _folderName).firstOrNull;
    sendComment('Searching for items within folder: ${folder?.name}');
    final items = await _bwCli.listItems(folderId: folder?.id).toList();
    sendComment('Found ${items.length} potential items');

    final matchingItems = items.where(_filterKeyGrip(keyGrip)).toList();
    switch (matchingItems) {
      case []:
        return await _retrySyncedOrFail(
          keyGrip: keyGrip,
          message: 'No matching items found!',
          synced: synced,
        );
      case [BwItem(type: != BwItemType.login)]:
        return await _retrySyncedOrFail(
          keyGrip: keyGrip,
          message: 'Found matching item, but it is not a login!',
          synced: synced,
        );
      case [BwItem(login: BwLogin(password: final String password))]:
        sendComment('Found matching login item with password set.');
        return password;
      case [_]:
        return await _retrySyncedOrFail(
          keyGrip: keyGrip,
          message: 'Found matching login item, but it has no password set!',
          synced: synced,
        );
      default:
        return await _retrySyncedOrFail(
          keyGrip: keyGrip,
          message: 'Found more then one matching item!',
          synced: synced,
        );
    }
  }

  bool Function(BwItem) _filterKeyGrip(String keyGrip) =>
      (i) => i.fields.any((f) => f.name == 'keygrip' && f.value == keyGrip);

  Future<String?> _retrySyncedOrFail({
    required String keyGrip,
    required String message,
    required bool synced,
  }) async {
    if (synced) {
      sendComment(message);
      await _resetClientTexts();
      await _client.setText(SetCommand.error, '$message\nKeygrip: $keyGrip');
      return null;
    } else {
      sendComment('$message Syncing vault, then trying again.');
      await _bwCli.sync();
      return _findPassword(keyGrip, synced: true);
    }
  }

  Future<void> _resetClientTexts() async {
    for (final MapEntry(:key, :value) in _textCache.entries) {
      await _client.setText(key, value);
    }
  }
}
