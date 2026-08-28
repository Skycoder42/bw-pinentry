import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../protocol/assuan_data_message.dart';

part 'pending_reply.freezed.dart';

@freezed
sealed class PendingReply with _$PendingReply {
  const factory action(Completer<void> completer) = PendingActionReply;
  const factory data(StreamController<AssuanDataMessage> controller) =
      PendingDataReply;

  const new _();
}
