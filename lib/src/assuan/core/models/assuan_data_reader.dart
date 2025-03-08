import 'assuan_error_code.dart';
import 'assuan_exception.dart';

class AssuanDataReader {
  static const _space = ' ';

  final String _data;
  int _offset;

  AssuanDataReader(this._data, this._offset);

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
        AssuanErrorCode.incompleteLine,
        'Unexpected end of data',
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

  int _nextNonSpaceIndex() => _data.indexOf(const NotASpacePattern(), _offset);

  bool get _atEnd => _offset >= _data.length;
}

class NotASpaceMatch implements Match {
  @override
  final NotASpacePattern pattern;

  @override
  final String input;

  @override
  final int start;

  @override
  final int end;

  NotASpaceMatch(this.pattern, this.input, this.start, this.end);

  @override
  String? group(int group) {
    // TODO: implement group
    throw UnimplementedError();
  }

  @override
  String? operator [](int group) => throw UnsupportedError('NotASpaceMatch');

  @override
  List<String?> groups(List<int> groupIndices) =>
      throw UnsupportedError('NotASpaceMatch');

  @override
  int get groupCount => throw UnsupportedError('NotASpaceMatch');
}

class NotASpacePattern implements Pattern {
  const NotASpacePattern();

  @override
  Match? matchAsPrefix(String string, [int start = 0]) {
    for (var i = start; i < string.length; i++) {
      if (string[i] != AssuanDataReader._space) {
        return NotASpaceMatch(this, string, i, i + 1);
      }
    }
    return null;
  }

  @override
  Iterable<Match> allMatches(String string, [int start = 0]) sync* {
    for (var i = start; i < string.length; i++) {
      if (string[i] != AssuanDataReader._space) {
        yield NotASpaceMatch(this, string, i, i + 1);
      }
    }
  }
}
