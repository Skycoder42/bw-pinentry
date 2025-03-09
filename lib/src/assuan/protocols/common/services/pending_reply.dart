import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../assuan_data_message.dart';

part 'pending_reply.freezed.dart';

@freezed
sealed class PendingReply with _$PendingReply {
  const factory PendingReply.action(Completer<void> completer) =
      PendingActionReply;
  const factory PendingReply.data(
    StreamController<AssuanDataMessage> controller,
  ) = PendingDataReply;

  const PendingReply._();
}
