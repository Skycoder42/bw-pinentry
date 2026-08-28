import 'dart:io';

import 'package:stream_channel/stream_channel.dart';

import '../../core/services/assuan_server.dart';
import '../protocol/pinentry_protocol.dart';

abstract class PinentryServer extends AssuanServer {
  static const notConfirmedCode = 0x05000063;

  new(StreamChannel<String> channel) : super(PinentryProtocol(), channel);

  new raw(StreamChannel<List<int>> channel, {super.encoding})
    : super.raw(PinentryProtocol(), channel);

  new io(Stdin stdin, Stdout stdout, {super.encoding})
    : super.io(PinentryProtocol(), stdin, stdout);
}
