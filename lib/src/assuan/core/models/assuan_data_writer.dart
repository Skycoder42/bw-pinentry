import 'assuan_exception.dart';

class AssuanDataWriter {
  final StringBuffer _buffer;

  AssuanDataWriter(this._buffer);

  void write<T extends Object>(T object, {bool autoSpace = true}) =>
      switch (object) {
        String() => _writeRaw(Uri.encodeFull(object), autoSpace: autoSpace),
        num() || bool() => _writeRaw(object.toString(), autoSpace: autoSpace),
        _ =>
          throw AssuanException(
            'Unsupported data type: ${object.runtimeType}',
            object,
          ),
      };

  void _writeRaw(String data, {bool autoSpace = true}) {
    if (autoSpace && _buffer.isNotEmpty) {
      _buffer.write(' ');
    }
    _buffer.write(data);

    if (_buffer.length > 1000) {
      throw const AssuanException(
        'Message too long! Must be less than 1000 bytes',
      );
    }
  }
}
