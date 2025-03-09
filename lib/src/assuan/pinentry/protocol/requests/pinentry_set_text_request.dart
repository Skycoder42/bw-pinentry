import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/protocol/base/assuan_data_reader.dart';
import '../../../core/protocol/base/assuan_data_writer.dart';
import '../../../core/protocol/base/assuan_message.dart';
import '../../../core/protocol/base/assuan_message_handler.dart';

part 'pinentry_set_text_request.freezed.dart';

enum SetCommand {
  description('SETDESC'),
  prompt('SETPROMPT'),
  title('SETTITLE'),
  ok('SETOK'),
  cancel('SETCANCEL'),
  notOk('SETNOTOK'),
  error('SETERROR'),
  qualityBar('SETQUALITYBAR_TT'),
  getPin('SETGENPIN_TT');

  final String command;

  const SetCommand(this.command);
}

@freezed
sealed class PinentrySetTextRequest
    with _$PinentrySetTextRequest
    implements AssuanRequest {
  static Iterable<String> get cmds => SetCommand.values.map((v) => v.command);
  static const handler = PinentrySetTextRequestHandler();

  factory PinentrySetTextRequest(SetCommand setCommand, String text) =>
      PinentrySetTextRequest.internal(setCommand.command, text);

  @protected
  const factory PinentrySetTextRequest.internal(String command, String text) =
      _PinentrySetTextRequest;

  const PinentrySetTextRequest._();

  SetCommand get setCommand =>
      SetCommand.values.singleWhere((c) => c.command == command);
}

class PinentrySetTextRequestHandler
    implements AssuanMessageHandler<PinentrySetTextRequest> {
  const PinentrySetTextRequestHandler();

  @override
  bool hasData(_) => true;

  @override
  void encodeData(PinentrySetTextRequest message, AssuanDataWriter writer) =>
      writer.write(message.text);

  @override
  PinentrySetTextRequest decodeData(AssuanDataReader reader) =>
      PinentrySetTextRequest.internal(reader.command, reader.readAll());
}
