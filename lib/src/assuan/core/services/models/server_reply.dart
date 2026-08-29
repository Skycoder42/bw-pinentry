import 'package:freezed_annotation/freezed_annotation.dart';

part 'server_reply.freezed.dart';

@freezed
sealed class ServerReply with _$ServerReply {
  const factory ok([String? message]) = OkReply;
  const factory data(String data, [String? message]) = DataReply;
  const factory dataStream(Stream<String> data, [String? message]) =
      DataStreamReply;
}
