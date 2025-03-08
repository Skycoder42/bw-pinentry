import 'dart:convert';

class ConverterSink<S, T> implements Sink<S> {
  final Sink<T> _sink;
  final Converter<S, T> _converter;

  ConverterSink(this._sink, this._converter);

  @override
  void add(S data) => _sink.add(_converter.convert(data));

  @override
  void close() => _sink.close();
}
