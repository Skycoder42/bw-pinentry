import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'models/bw_status.dart';

class BitwardenCli {
  static const _passwordEnvKey = '__BITWARDEN_MASTER_PASSWORD';

  Future<BwStatus> status() => _execJson('status', BwStatus.fromJson);

  Future<void> unlock(String masterPassword) => _execString(
    'unlock',
    arguments: const {'passwordenv': _passwordEnvKey, 'raw': null},
    environment: {_passwordEnvKey: 'masterPassword'},
  );

  Future<T> _execJson<T>(
    String command,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic> arguments = const {},
    Map<String, String>? environment,
  }) =>
      _streamBw(command, arguments: arguments, environment: environment)
          .transform(utf8.decoder)
          .transform(json.decoder)
          .cast<Map<String, dynamic>>()
          .map(fromJson)
          .single;

  Future<void> _execString(
    String command, {
    Map<String, dynamic> arguments = const {},
    Map<String, String>? environment,
  }) =>
      _streamBw(
        command,
        arguments: arguments,
        environment: environment,
      ).transform(utf8.decoder).join();

  Stream<List<int>> _streamBw(
    String command, {
    Map<String, dynamic> arguments = const {},
    Map<String, String>? environment,
    int? expectedExitCode = 0,
  }) async* {
    final proc = await Process.start('bw', [
      command,
      for (final MapEntry(:key, :value) in arguments.entries) ...[
        '--$key',
        if (value != null) value.toString(),
      ],
    ], environment: environment);
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
