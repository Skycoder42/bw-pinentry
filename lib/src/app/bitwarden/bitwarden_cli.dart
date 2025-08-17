import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'models/bw_object.dart';
import 'models/bw_status.dart';

class BitwardenCli {
  static const _passwordEnvKey = '__BITWARDEN_MASTER_PASSWORD';

  String? _session;

  Future<BwStatus> status() => _execJson(const ['status'], BwStatus.fromJson);

  Future<void> sync() => _exec(const ['sync']);

  Future<void> unlock(String masterPassword) async {
    await lock();
    _session = await _execString(
      const ['unlock'],
      arguments: const {'passwordenv': _passwordEnvKey},
      environment: {_passwordEnvKey: masterPassword},
    );
  }

  Future<void> lock() async {
    if (_session != null) {
      await _exec(const ['lock']);
      _session = null;
    }
  }

  Stream<BwFolder> listFolders({
    String? search,
    String? url,
    String? folderId,
  }) =>
      _list<BwFolder>('folders', search: search, url: url, folderId: folderId);

  Stream<BwItem> listItems({String? search, String? url, String? folderId}) =>
      _list<BwItem>('items', search: search, url: url, folderId: folderId);

  Stream<T> _list<T extends BwObject>(
    String type, {
    String? search,
    String? url,
    String? folderId,
  }) => _execJsonStream(
    ['list', type],
    BwObject.fromJson,
    arguments: {'search': ?search, 'url': ?url, 'folderid': ?folderId},
  ).cast<T>();

  Future<void> _exec(
    List<String> command, {
    Map<String, dynamic> arguments = const {},
    Map<String, String>? environment,
  }) => _streamBw(
    command,
    arguments: arguments,
    environment: environment,
  ).drain<void>();

  Future<String> _execString(
    List<String> command, {
    Map<String, dynamic> arguments = const {},
    Map<String, String>? environment,
  }) => _streamBw(
    command,
    arguments: arguments,
    environment: environment,
  ).transform(utf8.decoder).join();

  Future<T> _execJson<T>(
    List<String> command,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic> arguments = const {},
    Map<String, String>? environment,
  }) => _streamBw(command, arguments: arguments, environment: environment)
      .transform(utf8.decoder)
      .transform(json.decoder)
      .cast<Map<String, dynamic>>()
      .map(fromJson)
      .single;

  Stream<T> _execJsonStream<T>(
    List<String> command,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic> arguments = const {},
    Map<String, String>? environment,
  }) => _streamBw(command, arguments: arguments, environment: environment)
      .transform(utf8.decoder)
      .transform(json.decoder)
      .cast<List<dynamic>>()
      .expand((l) => l)
      .cast<Map<String, dynamic>>()
      .map(fromJson);

  Stream<List<int>> _streamBw(
    List<String> command, {
    Map<String, dynamic> arguments = const {},
    Map<String, String>? environment,
    int? expectedExitCode = 0,
  }) async* {
    final proc = await Process.start(
      'bw',
      [
        ...command,
        '--raw',
        for (final MapEntry(:key, :value) in arguments.entries) ...[
          '--$key',
          if (value != null) value.toString(),
        ],
      ],
      environment: {
        ...?environment,
        if (_session case final String session) 'BW_SESSION': session,
      },
    );
    final stderrSub = proc.stderr.listen(stderr.add);
    try {
      yield* proc.stdout;

      final exitCode = await proc.exitCode;
      if (expectedExitCode != null && exitCode != expectedExitCode) {
        throw Exception('bw failed with exit code: $exitCode');
      }
    } finally {
      unawaited(stderrSub.cancel());
    }
  }
}
