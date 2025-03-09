import 'dart:io';

import 'package:stream_channel/stream_channel.dart';

import '../../core/protocol/base/assuan_message.dart';
import '../../core/services/assuan_server.dart';
import '../../core/services/models/server_reply.dart';
import '../protocol/pinentry_protocol.dart';

abstract class PinentryServer extends AssuanServer {
  PinentryServer(StreamChannel<String> channel, {super.exitOnClose})
    : super(PinentryProtocol(), channel);

  PinentryServer.raw(
    StreamChannel<List<int>> channel, {
    super.encoding,
    super.exitOnClose,
  }) : super.raw(PinentryProtocol(), channel);

  PinentryServer.io(
    Stdin stdin,
    Stdout stdout, {
    super.encoding,
    super.exitOnClose,
  }) : super.io(PinentryProtocol(), stdin, stdout);

  @override
  Future<void> setOption(String name, String? value) {
    // TODO: implement setOption
    throw UnimplementedError();
  }

  @override
  Future<ServerReply> handleRequest(AssuanRequest request) {
    // TODO: implement handleRequest
    throw UnimplementedError();
  }
}
