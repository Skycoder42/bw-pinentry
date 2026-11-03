import 'dart:convert';

class ConverterSink<S, T>(final Sink<T> _sink, final Converter<S, T> _converter)
    implements Sink<S> {
  @override
  void add(S data) => _sink.add(_converter.convert(data));

  @override
  void close() => _sink.close();
}
