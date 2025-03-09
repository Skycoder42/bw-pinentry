import 'package:freezed_annotation/freezed_annotation.dart';

part 'inquiry_reply.freezed.dart';

@freezed
sealed class InquiryReply with _$InquiryReply {
  const factory InquiryReply.data(String data) = InquiryDataReply;
  const factory InquiryReply.dataStream(Stream<String> stream) =
      InquiryDataStreamReply;
  const factory InquiryReply.cancel() = InquiryCancelReply;
}
