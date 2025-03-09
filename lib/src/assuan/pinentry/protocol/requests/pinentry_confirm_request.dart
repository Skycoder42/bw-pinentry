import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/protocol/base/assuan_data_reader.dart';
import '../../../core/protocol/base/assuan_data_writer.dart';
import '../../../core/protocol/base/assuan_error_code.dart';
import '../../../core/protocol/base/assuan_exception.dart';
import '../../../core/protocol/base/assuan_message.dart';
import '../../../core/protocol/base/assuan_message_handler.dart';

part 'pinentry_confirm_request.freezed.dart';

@freezed
sealed class PinentryConfirmRequest
    with _$PinentryConfirmRequest
    implements AssuanRequest {
  static const notConfirmedCode = 0x05000063;

  static const cmd = 'CONFIRM';
  static const handler = PinentryConfirmRequestHandler();

  const factory PinentryConfirmRequest({@Default(false) bool oneButton}) =
      _PinentryConfirmRequest;

  const PinentryConfirmRequest._();

  @override
  String get command => cmd;
}

class PinentryConfirmRequestHandler
    implements AssuanMessageHandler<PinentryConfirmRequest> {
  static const _oneButtonOption = '--one-button';

  const PinentryConfirmRequestHandler();

  @override
  bool hasData(PinentryConfirmRequest message) => message.oneButton;

  @override
  void encodeData(PinentryConfirmRequest message, AssuanDataWriter writer) {
    if (message.oneButton) {
      writer.write(_oneButtonOption);
    }
  }

  @override
  PinentryConfirmRequest decodeData(AssuanDataReader reader) {
    if (reader.hasMoreData()) {
      final option = reader.read<String>();
      if (option == _oneButtonOption) {
        return const PinentryConfirmRequest(oneButton: true);
      } else {
        throw AssuanException.code(
          AssuanErrorCode.parameter,
          'Parameter $option is not allowed for CONFIRM',
        );
      }
    } else {
      return const PinentryConfirmRequest();
    }
  }
}
