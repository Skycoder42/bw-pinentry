#!/usr/bin/env dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';

void main(List<String> args) async {
  final logFile = File('/tmp/pinentry.log');
  final logFileSink = logFile.openWrite();
  try {
    logFileSink.writeln('STARTED: $args');
    final pinentry = await Process.start('/usr/bin/bw-pinentry', args);

    await Future.wait([
      stdin
          .tee(_lineWrapped('IN ', logFileSink))
          .pipe(pinentry.stdin)
          .whenComplete(() => logFileSink.writeln('IN: <<DONE>>')),
      pinentry.stdout
          .tee(_lineWrapped('OUT', logFileSink))
          .pipe(stdout)
          .whenComplete(() => logFileSink.writeln('OUT: <<DONE>>')),
      pinentry.stderr
          .tee(_lineWrapped('ERR', logFileSink))
          .pipe(stderr)
          .whenComplete(() => logFileSink.writeln('ERR: <<DONE>>')),
    ]);

    exitCode = await pinentry.exitCode;
    logFileSink.writeln('EXIT: $exitCode');
    // ignore: avoid_catches_without_on_clauses
  } catch (e, s) {
    logFileSink
      ..writeln('###############################################')
      ..writeln(e)
      ..writeln(s);
  } finally {
    await logFileSink.flush();
    await logFileSink.close();
  }
}

extension _StreamX<T> on Stream<T> {
  Stream<T> tee(EventSink<T> teeSink) => transform(
    StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        teeSink.add(data);
        sink.add(data);
      },
      handleError: (error, stackTrace, sink) {
        teeSink.addError(error, stackTrace);
        sink.addError(error, stackTrace);
      },
      handleDone: (sink) {
        teeSink.close();
        sink.close();
      },
    ),
  );
}

StreamSink<List<int>> _lineWrapped(
  String prefix,
  StreamSink<List<int>> original,
) => original
    .transform(
      StreamSinkTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (data, sink) => sink.add(data),
        handleError: (err, trace, sink) => sink.addError(err, trace),
        handleDone: (_) {},
      ),
    )
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
