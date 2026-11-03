import 'dart:convert';
import 'dart:io';

class AppendLineTerminatorConverter({String? lineTerminator})
    extends Converter<String, String> {
  final String lineTerminator = lineTerminator ?? Platform.lineTerminator;

  @override
  String convert(String input) => '$input$lineTerminator';

  @override
  Sink<String> startChunkedConversion(Sink<String> sink) =>
      _AppendLineTerminatorSink(sink, lineTerminator);
}

class _AppendLineTerminatorSink(
  final Sink<String> _sink,
  final String _lineTerminator,
) implements Sink<String> {
  @override
  void add(String data) {
    _sink
      ..add(data)
      ..add(_lineTerminator);
  }

  @override
  void close() => _sink.close();
}
