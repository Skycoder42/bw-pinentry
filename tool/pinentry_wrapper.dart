#!/usr/bin/env dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';

void main(List<String> args) async {
  final logFile = File('/tmp/pinentry.log');
  // ignore: close_sinks
  final logFileSink = logFile.openWrite();
  try {
    logFileSink.writeln('STARTED: $args');
    final pinentry = await Process.start(
      '/home/sky/repo/dart-packages/bw-pinentry/bin/bw_pinentry.exe',
      args,
    );

    await Future.wait([
      pinentry.stdin
          .addStream(stdin.tee(_lineWrapped('IN ', logFileSink)))
          .whenComplete(() => logFileSink.writeln('IN: <<DONE>>')),
      stdout
          .addStream(pinentry.stdout.tee(_lineWrapped('OUT', logFileSink)))
          .whenComplete(() => logFileSink.writeln('OUT: <<DONE>>')),
      stderr
          .addStream(pinentry.stderr.tee(_lineWrapped('ERR', logFileSink)))
          .whenComplete(() => logFileSink.writeln('ERR: <<DONE>>')),
    ]);

    exitCode = await pinentry.exitCode;
    logFileSink.writeln('EXIT: $exitCode');
  } finally {
    await logFileSink.flush();
    await logFileSink.close();
  }
}

extension _StreamX<T> on Stream<T> {
  Stream<T> tee(Sink<T> sink) => map((e) {
    sink.add(e);
    return e;
  });
}

StreamSink<List<int>> _lineWrapped(
  String prefix,
  StreamSink<List<int>> original,
) => original
    .transform(StreamSinkTransformer.fromStreamTransformer(utf8.encoder))
    .transform(
      StreamSinkTransformer.fromHandlers(
        handleData: (data, sink) => sink.add('$prefix: $data\n'),
      ),
    )
    .transform(
      const StreamSinkTransformer.fromStreamTransformer(LineSplitter()),
    )
    .transform(StreamSinkTransformer.fromStreamTransformer(utf8.decoder));
