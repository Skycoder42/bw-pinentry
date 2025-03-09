import 'dart:io';

import 'package:stream_channel/stream_channel.dart';

import '../../core/services/assuan_server.dart';
import '../protocol/pinentry_protocol.dart';

abstract class PinentryServer extends AssuanServer {
  PinentryServer(StreamChannel<String> channel)
    : super(PinentryProtocol(), channel);

  PinentryServer.raw(StreamChannel<List<int>> channel, {super.encoding})
    : super.raw(PinentryProtocol(), channel);

  PinentryServer.io(Stdin stdin, Stdout stdout, {super.encoding})
    : super.io(PinentryProtocol(), stdin, stdout);
}
