import '../../core/services/assuan_client.dart';
import '../../core/services/models/inquiry_reply.dart';

final class PinentryClient extends AssuanClient {
  PinentryClient(
    super.protocol,
    super.channel, {
    super.terminateSignal,
    super.forceCloseCallback,
    super.forceCloseTimeout,
  });

  PinentryClient.raw(
    super.protocol,
    super.channel, {
    super.encoding,
    super.terminateSignal,
    super.forceCloseCallback,
    super.forceCloseTimeout,
  }) : super.raw();

  PinentryClient.process(
    super.protocol,
    super.process, {
    super.encoding,
    super.forceCloseTimeout,
  }) : super.process();

  @override
  Future<void> onStatus(String keyword, String status) {
    // TODO: implement onStatus
    throw UnimplementedError();
  }

  @override
  Future<InquiryReply> onInquire(String keyword, List<String> parameters) {
    // TODO: implement onInquire
    throw UnimplementedError();
  }
}
