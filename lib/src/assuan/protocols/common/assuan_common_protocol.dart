import 'package:meta/meta.dart';

import '../../core/models/assuan_message.dart';
import '../../core/models/assuan_message_handler.dart';
import '../../core/models/assuan_protocol.dart';
import 'assuan_comment.dart';
import 'assuan_data_message.dart';
import 'requests/assuan_bye_request.dart';
import 'requests/assuan_cancel_request.dart';
import 'requests/assuan_end_request.dart';
import 'requests/assuan_help_request.dart';
import 'requests/assuan_nop_request.dart';
import 'requests/assuan_option_request.dart';
import 'requests/assuan_reset_request.dart';
import 'responses/assuan_error_response.dart';
import 'responses/assuan_inquire_response.dart';
import 'responses/assuan_ok_response.dart';
import 'responses/assuan_status_response.dart';

class AssuanCommonProtocol implements AssuanProtocol {
  final _requestHandlers = <String, AssuanMessageHandler<AssuanRequest>>{
    AssuanDataMessage.cmd: AssuanDataMessage.handler,
    AssuanByeRequest.cmd: AssuanByeRequest.handler,
    AssuanResetRequest.cmd: AssuanResetRequest.handler,
    AssuanEndRequest.cmd: AssuanEndRequest.handler,
    AssuanHelpRequest.cmd: AssuanHelpRequest.handler,
    AssuanOptionRequest.cmd: AssuanOptionRequest.handler,
    AssuanNopRequest.cmd: AssuanNopRequest.handler,
    AssuanCancelRequest.cmd: AssuanCancelRequest.handler,
  };

  final _responseHandlers = <String, AssuanMessageHandler<AssuanResponse>>{
    AssuanDataMessage.cmd: AssuanDataMessage.handler,
    AssuanOkResponse.cmd: AssuanOkResponse.handler,
    AssuanErrorResponse.cmd: AssuanErrorResponse.handler,
    AssuanStatusResponse.cmd: AssuanStatusResponse.handler,
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

  @override
  Iterable<String> get requestCommands => _requestHandlers.keys;

  @override
  Iterable<String> get responseCommands => _responseHandlers.keys;

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
