import 'package:freezed_annotation/freezed_annotation.dart';

part 'inquiry_reply.freezed.dart';

@freezed
sealed class InquiryReply with _$InquiryReply {
  const factory data(String data) = InquiryDataReply;
  const factory dataStream(Stream<String> stream) = InquiryDataStreamReply;
  const factory cancel() = InquiryCancelReply;
}
