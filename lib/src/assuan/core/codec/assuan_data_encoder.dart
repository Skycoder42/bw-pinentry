import 'dart:async';
import 'dart:math';

import '../../protocols/common/assuan_data_message.dart';

class AssuanDataEncoder
    extends StreamTransformerBase<String, AssuanDataMessage> {
  const AssuanDataEncoder();

  @override
  Stream<AssuanDataMessage> bind(Stream<String> stream) =>
      Stream.eventTransformed(stream, _AssuanDataEncoderSink.new);
}

class _AssuanDataEncoderSink implements EventSink<String> {
  static final _escapeRequiredChars = RegExp(r'[\%\n\r\\]');

  final EventSink<AssuanDataMessage> _sink;
  final _buffer = StringBuffer();

  _AssuanDataEncoderSink(this._sink);

  int get _remainingBufferLen =>
      _buffer.length - AssuanDataMessage.maxDataLength;

  @override
  void add(String event) {
    var eventOffset = 0;
    while (eventOffset < event.length) {
      final escapeIdx = event.indexOf(_escapeRequiredChars, eventOffset);

      // no escaping required -> add whole string
      if (escapeIdx == -1) {
        _addSegment(event, eventOffset, event.length);
        return;
      }

      // add data until escape position
      _addSegment(event, eventOffset, escapeIdx);
      // add the escaped data
      _addEscaped(event[escapeIdx]);
      // continue after the escaped char
      eventOffset = escapeIdx + 1;
    }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _sink.addError(error, stackTrace);

  @override
  void close() {
    // send remaining buffer
    if (_buffer.isNotEmpty) {
      _sink.add(AssuanDataMessage(_buffer.toString()));
      _buffer.clear();
    }

    _sink.close();
  }

  void _addSegment(String event, int start, int end) {
    var offset = start;
    while (offset < end) {
      final remainingEventLen = end - offset;
      final chunkSize = min(_remainingBufferLen, remainingEventLen);
      _buffer.write(event.substring(offset, offset + chunkSize));

      if (_remainingBufferLen == 0) {
        _sink.add(AssuanDataMessage(_buffer.toString()));
        _buffer.clear();
      }

      offset += chunkSize;
    }
  }

  void _addEscaped(String char) {
    final escaped = Uri.encodeFull(char);
    if (escaped.length > _remainingBufferLen) {
      _sink.add(AssuanDataMessage(_buffer.toString()));
      _buffer.clear();
    }
    _buffer.write(escaped);
  }
}
