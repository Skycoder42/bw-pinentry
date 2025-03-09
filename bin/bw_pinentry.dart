import 'dart:io';

import 'package:bw_pinentry/src/app/pinentry/bw_pinentry_server.dart';

void main(List<String> arguments) => BwPinentryServer(stdin, stdout);
