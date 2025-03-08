import 'dart:convert';
import 'dart:io';

class AppendLineTerminatorConverter extends Converter<String, String> {
  final String lineTerminator;

  AppendLineTerminatorConverter({String? lineTerminator})
    : lineTerminator = lineTerminator ?? Platform.lineTerminator;

  @override
  String convert(String input) => '$input$lineTerminator';

  @override
  Sink<String> startChunkedConversion(Sink<String> sink) =>
      _AppendLineTerminatorSink(sink, lineTerminator);
}

class _AppendLineTerminatorSink implements Sink<String> {
  final Sink<String> _sink;
  final String _lineTerminator;

  _AppendLineTerminatorSink(this._sink, this._lineTerminator);

  @override
  void add(String data) {
    _sink
      ..add(data)
      ..add(_lineTerminator);
  }

  @override
  void close() => _sink.close();
}
