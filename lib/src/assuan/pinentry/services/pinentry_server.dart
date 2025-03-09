import '../../core/protocol/base/assuan_message.dart';
import '../../core/services/assuan_server.dart';
import '../../core/services/models/server_reply.dart';

final class PinentryServer extends AssuanServer {
  PinentryServer(super.protocol, super.channel, {super.exitOnClose});

  PinentryServer.raw(
    super.protocol,
    super.channel, {
    super.encoding,
    super.exitOnClose,
  }) : super.raw();

  PinentryServer.io(
    super.protocol,
    super.stdin,
    super.stdout, {
    super.encoding,
    super.exitOnClose,
  }) : super.io();

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
