import 'package:meta/meta.dart';

import 'assuan_comment.dart';
import 'assuan_data_message.dart';
import 'base/assuan_message.dart';
import 'base/assuan_message_handler.dart';
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

base class AssuanProtocol {
  final _responseHandlers =
      const <String, AssuanMessageHandler<AssuanResponse>>{
        AssuanComment.cmd: AssuanComment.handler,
        AssuanDataMessage.cmd: AssuanDataMessage.handler,
        AssuanOkResponse.cmd: AssuanOkResponse.handler,
        AssuanErrorResponse.cmd: AssuanErrorResponse.handler,
        AssuanStatusResponse.cmd: AssuanStatusResponse.handler,
        AssuanInquireResponse.cmd: AssuanInquireResponse.handler,
      };

  final _requestHandlers = <String, AssuanMessageHandler<AssuanRequest>>{
    AssuanComment.cmd: AssuanComment.handler,
    AssuanDataMessage.cmd: AssuanDataMessage.handler,
    AssuanByeRequest.cmd: AssuanByeRequest.handler,
    AssuanResetRequest.cmd: AssuanResetRequest.handler,
    AssuanEndRequest.cmd: AssuanEndRequest.handler,
    AssuanHelpRequest.cmd: AssuanHelpRequest.handler,
    AssuanOptionRequest.cmd: AssuanOptionRequest.handler,
    AssuanNopRequest.cmd: AssuanNopRequest.handler,
    AssuanCancelRequest.cmd: AssuanCancelRequest.handler,
  };

  AssuanProtocol([
    Map<String, AssuanMessageHandler<AssuanRequest>> requestHandlers = const {},
  ]) {
    _requestHandlers.addAll(requestHandlers);
  }

  @nonVirtual
  Iterable<String> get requestCommands => _requestHandlers.keys;

  @nonVirtual
  Iterable<String> get responseCommands => _responseHandlers.keys;

  @nonVirtual
  AssuanMessageHandler<AssuanRequest>? requestHandler(String command) =>
      _requestHandlers[command];

  @nonVirtual
  AssuanMessageHandler<AssuanResponse>? responseHandler(String command) =>
      _responseHandlers[command];

  @nonVirtual
  String get commentPrefix => AssuanComment.cmd;

  @nonVirtual
  AssuanComment createComment(String comment) => AssuanComment(comment);
}
