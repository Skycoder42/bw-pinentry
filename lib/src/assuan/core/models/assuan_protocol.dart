import 'assuan_message.dart';
import 'assuan_message_handler.dart';

abstract interface class AssuanProtocol {
  Iterable<String> get requestCommands;

  Iterable<String> get responseCommands;

  AssuanMessageHandler<AssuanRequest>? requestHandler(String command);

  AssuanMessageHandler<AssuanResponse>? responseHandler(String command);

  String get commentPrefix;

  AssuanCommentBase createComment(String comment);
}
