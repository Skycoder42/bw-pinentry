import 'dart:io';

import '../../assuan/core/services/models/inquiry_reply.dart';
import '../../assuan/pinentry/services/pinentry_client.dart';
import 'bw_pinentry_server.dart';

class BwPinentryClient._(final BwPinentryServer _server, super.process)
    extends PinentryClient {
  this : super.process();

  static Future<BwPinentryClient> start(
    BwPinentryServer server,
    String pinentry,
    List<String> arguments,
  ) async {
    final proc = await Process.start(pinentry, arguments);
    final client = BwPinentryClient._(server, proc);
    try {
      await client.connected;
      return client;
    } on Exception {
      client.close().ignore();
      rethrow;
    }
  }

  @override
  Future<InquiryReply> onInquire(String keyword, List<String> parameters) =>
      Future.value(
        InquiryReply.dataStream(_server.forwardInquiry(keyword, parameters)),
      );

  @override
  Future<void> onStatus(String keyword, String status) {
    _server.forwardStatus(keyword, status);
    return Future.value();
  }
}
