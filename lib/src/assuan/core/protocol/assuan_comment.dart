import 'package:freezed_annotation/freezed_annotation.dart';

import 'base/assuan_data_reader.dart';
import 'base/assuan_data_writer.dart';
import 'base/assuan_error_code.dart';
import 'base/assuan_exception.dart';
import 'base/assuan_message.dart';
import 'base/assuan_message_handler.dart';

part 'assuan_comment.freezed.dart';

@freezed
sealed class AssuanComment with _$AssuanComment implements AssuanCommentBase {
  static const cmd = '#';
  static const handler = AssuanCommentHandler();

  const factory AssuanComment(String comment) = _AssuanComment;

  const AssuanComment._();

  @override
  String get command => cmd;
}

class AssuanCommentHandler implements AssuanMessageHandler<AssuanComment> {
  const AssuanCommentHandler();

  @override
  bool hasData(_) => true;

  @override
  void encodeData(AssuanComment message, AssuanDataWriter writer) {
    writer.write(message.comment);
  }

  @override
  AssuanComment decodeData(AssuanDataReader reader) =>
      throw AssuanException.code(
        AssuanErrorCode.syntax,
        'Comment messages can only be sent, not received',
      );
}
