abstract interface class AssuanMessage {
  String get command;
}

abstract interface class AssuanRequest implements AssuanMessage {}

abstract interface class AssuanResponse implements AssuanMessage {}

abstract interface class AssuanCommentBase
    implements AssuanRequest, AssuanResponse {}
