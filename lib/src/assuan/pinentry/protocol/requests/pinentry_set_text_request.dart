import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/protocol/base/assuan_data_reader.dart';
import '../../../core/protocol/base/assuan_data_writer.dart';
import '../../../core/protocol/base/assuan_message.dart';
import '../../../core/protocol/base/assuan_message_handler.dart';

part 'pinentry_set_text_request.freezed.dart';

enum SetCommand(final String command) {
  description('SETDESC'),
  prompt('SETPROMPT'),
  title('SETTITLE'),
  ok('SETOK'),
  cancel('SETCANCEL'),
  notOk('SETNOTOK'),
  error('SETERROR'),
  qualityBar('SETQUALITYBAR_TT'),
  genPin('SETGENPIN_TT'),
}

@freezed
sealed class const PinentrySetTextRequest._()
    with _$PinentrySetTextRequest
    implements AssuanRequest {
  static Iterable<String> get cmds => SetCommand.values.map((v) => v.command);
  static const handler = PinentrySetTextRequestHandler();

  const factory(SetCommand setCommand, String text) = _PinentrySetTextRequest;

  @override
  String get command => setCommand.command;
}

class const PinentrySetTextRequestHandler()
    implements AssuanMessageHandler<PinentrySetTextRequest> {
  @override
  bool hasData(_) => true;

  @override
  void encodeData(PinentrySetTextRequest message, AssuanDataWriter writer) =>
      writer.write(message.text);

  @override
  PinentrySetTextRequest decodeData(AssuanDataReader reader) =>
      PinentrySetTextRequest(
        .values.singleWhere((c) => c.command == reader.command),
        reader.readAll(),
      );
}
