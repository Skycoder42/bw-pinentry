#!/usr/bin/env dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';

void main(List<String> args) async {
  final logFile = File('/tmp/pinentry-log');
  // ignore: close_sinks
  final logFileSink = logFile.openWrite();
  try {
    final pinentry = await Process.start('/usr/bin/pinentry-qt', const []);

    await Future.wait([
      stdin.tee(_lineWrapped('IN ', logFileSink)).pipe(pinentry.stdin),
      pinentry.stdout.tee(_lineWrapped('OUT', logFileSink)).pipe(stdout),
      pinentry.stderr.tee(_lineWrapped('ERR', logFileSink)).pipe(stderr),
    ]);

    exitCode = await pinentry.exitCode;
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
