import 'dart:io';

// ignore: no_self_package_imports
import '../../../gen/package_metadata.dart' as metadata;
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

final class BwPinentryServer extends PinentryServer {
  final _optionsCache = <String, String?>{};
  final _textCache = <SetCommand, String>{};
  Duration? _timeout;
  var _showQualityBar = false;
  var _enableGenPin = false;
  var _repeatPin = false;
  String? _keyGrip;

  BwPinentryServer(super.stdin, super.stdout) : super.io();

  Stream<String> forwardInquiry(String keyword, List<String> parameters) =>
      startInquire(keyword, parameters);

  void forwardStatus(String keyword, String status) =>
      sendStatus(keyword, status);

  @override
  Future<void> setOption(String name, String? value) {
    _optionsCache[name] = value;
    return Future.value();
  }

  @override
  Future<ServerReply> handleRequest(AssuanRequest request) async {
    switch (request) {
      case PinentryGetInfoRequest(:final key):
        return _handleGetInfo(key);
      case PinentrySetTextRequest(:final setCommand, :final text):
        _textCache[setCommand] = text;
        return const OkReply();
      case PinentrySetTimeoutRequest(:final timeout):
        _timeout = timeout;
        return const OkReply();
      case PinentryEnableQualityBarRequest():
        _showQualityBar = true;
        return const OkReply();
      case PinentrySetGenPinRequest():
        _enableGenPin = true;
        return const OkReply();
      case PinentrySetRepeatRequest():
        _repeatPin = true;
        return const OkReply();
      case PinentrySetKeyinfoRequest(:final keyGrip):
        _keyGrip = keyGrip;
        return const OkReply();
      case PinentryMessageRequest():
      case PinentryConfirmRequest(oneButton: true):
        return _showMessage();
      case PinentryConfirmRequest(oneButton: false):
        return _confirm();
      case PinentryGetPinRequest():
        // TODO use bitwarden!
        return _getPin();
      default:
        throw AssuanException.code(
          AssuanErrorCode.unknownCmd,
          'Unknown command <${request.command}>',
        );
    }
  }

  @override
  Future<void> reset({bool closing = false}) {
    _optionsCache.clear();
    _textCache.clear();
    _timeout = null;
    _showQualityBar = false;
    _enableGenPin = false;
    _repeatPin = false;
    _keyGrip = null;
    return super.reset(closing: closing);
  }

  ServerReply _handleGetInfo(PinentryInfoKey key) => switch (key) {
    PinentryInfoKey.flavor => const ServerReply.data('bitwarden'),
    PinentryInfoKey.version => const ServerReply.data(metadata.version),
    // ttyname ttytype display devicestat uid/gid emacs
    PinentryInfoKey.ttyinfo => const ServerReply.data('- - - - 0/0 -'),
    PinentryInfoKey.pid => ServerReply.data(pid.toString()),
  };

  Future<ServerReply> _showMessage() async {
    final client = await _initClient();
    try {
      sendComment('Forwarding MESSAGE');
      await client.showMessage();
      return const ServerReply.ok();
    } finally {
      await client.close();
    }
  }

  Future<ServerReply> _confirm() async {
    final client = await _initClient();
    try {
      sendComment('Forwarding CONFIRM');
      final response = await client.confirm();
      if (!response) {
        throw AssuanException(
          'prompt was not confirmed',
          PinentryConfirmRequest.notConfirmedCode,
        );
      }
      return const ServerReply.ok();
    } finally {
      await client.close();
    }
  }

  Future<ServerReply> _getPin() async {
    final client = await _initClient();
    try {
      sendComment('Forwarding GETPIN');
      final pin = await client.getPin();
      return ServerReply.data(pin);
    } finally {
      await client.close();
    }
  }

  Future<BwPinentryClient> _initClient() async {
    final client = await BwPinentryClient.start(this);
    sendComment('Starting real pinentry');
    await client.connected;
    // set all parameters
    for (final MapEntry(:key, :value) in _optionsCache.entries) {
      sendComment('Forwarding OPTION $key = $value');
      await client.setOption(key, value);
    }
    for (final MapEntry(:key, :value) in _textCache.entries) {
      sendComment('Forwarding ${key.command} $value');
      await client.setText(key, value);
    }
    if (_timeout case final Duration timeout) {
      sendComment('Forwarding SETTIMEOUT $timeout');
      await client.setTimeout(timeout);
    }
    if (_showQualityBar) {
      sendComment('Forwarding SETQUALITYBAR');
      await client.enableQualityBar();
    }
    if (_enableGenPin) {
      sendComment('Forwarding SETGENPIN');
      await client.enablePinGeneration();
    }
    if (_repeatPin) {
      sendComment('Forwarding SETREPEAT');
      await client.enableRepeat();
    }
    if (_keyGrip case final String keyGrip) {
      sendComment('Forwarding SETKEYINFO');
      await client.setKeyinfo(keyGrip);
    }
    return client;
  }
}
