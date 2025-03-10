import 'dart:io';

import '../../assuan/core/services/models/inquiry_reply.dart';
import '../../assuan/pinentry/services/pinentry_client.dart';
import 'bw_pinentry_server.dart';

class BwPinentryClient extends PinentryClient {
  final BwPinentryServer _server;

  BwPinentryClient._(this._server, super.process) : super.process();

  static Future<BwPinentryClient> start(BwPinentryServer server) async {
    final proc = await Process.start('/usr/bin/pinentry-qt', const []);
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
