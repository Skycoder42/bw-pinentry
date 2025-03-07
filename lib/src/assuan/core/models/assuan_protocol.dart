import 'assuan_message.dart';
import 'assuan_message_handler.dart';

abstract interface class AssuanProtocol {
  AssuanMessageHandler<AssuanRequest>? requestHandler(String command);

  AssuanMessageHandler<AssuanResponse>? responseHandler(String command);

  String get commentPrefix;

  AssuanCommentBase createComment(String comment);
}
