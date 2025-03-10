import '../../codec/assuan_percent_codec.dart';
import 'assuan_error_code.dart';
import 'assuan_exception.dart';

class AssuanDataWriter {
  final StringBuffer _buffer;

  AssuanDataWriter(this._buffer);

  void write<T extends Object>(T object, {bool autoSpace = true}) =>
      switch (object) {
        String() => writeRaw(
          assuanPercentCodec.encode(object),
          autoSpace: autoSpace,
        ),
        num() || bool() => writeRaw(object.toString(), autoSpace: autoSpace),
        _ =>
          throw AssuanException.code(
            AssuanErrorCode.invValue,
            'Unsupported data type <${object.runtimeType}>',
          ),
      };

  void writeRaw(String data, {bool autoSpace = true}) {
    if (autoSpace && _buffer.isNotEmpty) {
      _buffer.write(' ');
    }
    _buffer.write(data);

    if (_buffer.length > 1000) {
      throw AssuanException.code(
        AssuanErrorCode.lineTooLong,
        'Message too long! Must be less than 1000 bytes, '
        'but is at least ${_buffer.length}',
      );
    }
  }
}
