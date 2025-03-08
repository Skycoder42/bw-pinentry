import 'package:freezed_annotation/freezed_annotation.dart';

part 'server_reply.freezed.dart';

@freezed
sealed class ServerReply with _$ServerReply {
  const factory ServerReply.ok([String? message]) = OkReply;
  const factory ServerReply.data(String data, [String? message]) = DataReply;
  const factory ServerReply.dataStream(Stream<String> data, [String? message]) =
      DataStreamReply;
}
