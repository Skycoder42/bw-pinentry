import 'assuan_error_code.dart';
import 'assuan_exception.dart';

class AssuanDataReader {
  static const _space = ' ';
  static final _nonSpacePattern = RegExp(r'\S');

  final String command;
  final String _data;
  int _offset;

  AssuanDataReader(this.command, this._data, this._offset);

  bool hasMoreData({bool fixedSpace = false}) =>
      !_atEnd && (fixedSpace || _nextNonSpaceIndex() != -1);

  T read<T extends Object>({bool fixedSpace = false}) {
    final raw = readRaw(fixedSpace: fixedSpace);
    return switch (T) {
      const (String) => Uri.decodeFull(raw) as T,
      const (int) => int.parse(raw) as T,
      const (double) => double.parse(raw) as T,
      const (bool) => bool.parse(raw) as T,
      _ =>
        throw AssuanException.code(
          AssuanErrorCode.invValue,
          'Unsupported data type <$T>',
        ),
    };
  }

  String readAll({bool fixedSpace = false}) {
    final raw = readRaw(fixedSpace: fixedSpace, readToEnd: true);
    return Uri.decodeFull(raw);
  }

  T? readOptional<T extends Object>({bool fixedSpace = false}) {
    if (!hasMoreData(fixedSpace: fixedSpace)) {
      return null;
    }
    return read(fixedSpace: fixedSpace);
  }

  String? readAllOptional({bool fixedSpace = false}) {
    if (!hasMoreData(fixedSpace: fixedSpace)) {
      return null;
    }
    return readAll(fixedSpace: fixedSpace);
  }

  String readRaw({bool fixedSpace = false, bool readToEnd = false}) {
    if (_atEnd) {
      throw AssuanException.code(
        AssuanErrorCode.parameter,
        'Missing a required parameter',
      );
    }

    // debug assert, as this should never happen
    assert(
      _data[_offset] == _space,
      'Expected character at $_offset to be a space, but got ${_data[_offset]}',
    );

    final start = fixedSpace ? _offset + 1 : _nextNonSpaceIndex();
    if (start == -1 || start >= _data.length) {
      throw AssuanException.code(
        AssuanErrorCode.incompleteLine,
        'Unexpected end of data',
      );
    }
    final end = readToEnd ? -1 : _data.indexOf(_space, start);

    if (end == -1) {
      final result = _data.substring(start);
      _offset = _data.length;
      return result;
    } else {
      final result = _data.substring(start, end);
      _offset = end; // not +1, as we want to keep the space for the next read
      return result;
    }
  }

  int _nextNonSpaceIndex() => _data.indexOf(_nonSpacePattern, _offset);

  bool get _atEnd => _offset >= _data.length;
}
