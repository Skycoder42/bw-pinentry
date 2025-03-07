import 'package:meta/meta.dart';

import '../../core/models/assuan_message.dart';
import '../../core/models/assuan_message_handler.dart';
import '../../core/models/assuan_protocol.dart';
import 'assuan_comment.dart';
import 'responses/assuan_data_response.dart';
import 'responses/assuan_error_response.dart';
import 'responses/assuan_inquire_response.dart';
import 'responses/assuan_ok_response.dart';
import 'responses/assuan_status_response.dart';

class AssuanCommonProtocol implements AssuanProtocol {
  final _requestHandlers = <String, AssuanMessageHandler<AssuanRequest>>{};
  final _responseHandlers = <String, AssuanMessageHandler<AssuanResponse>>{
    AssuanOkResponse.cmd: AssuanOkResponse.handler,
    AssuanErrorResponse.cmd: AssuanErrorResponse.handler,
    AssuanStatusResponse.cmd: AssuanStatusResponse.handler,
    AssuanDataResponse.cmd: AssuanDataResponse.handler,
    AssuanInquireResponse.cmd: AssuanInquireResponse.handler,
  };

  AssuanCommonProtocol({
    Map<String, AssuanMessageHandler<AssuanRequest>> requestHandlers = const {},
    Map<String, AssuanMessageHandler<AssuanResponse>> responseHandlers =
        const {},
  }) {
    _requestHandlers.addAll(requestHandlers);
    _responseHandlers.addAll(responseHandlers);
  }

  @nonVirtual
  @override
  AssuanMessageHandler<AssuanRequest>? requestHandler(String command) =>
      _requestHandlers[command];

  @nonVirtual
  @override
  AssuanMessageHandler<AssuanResponse>? responseHandler(String command) =>
      _responseHandlers[command];

  @override
  String get commentPrefix => AssuanComment.cmd;

  @override
  AssuanComment createComment(String comment) => AssuanComment(comment);
}
