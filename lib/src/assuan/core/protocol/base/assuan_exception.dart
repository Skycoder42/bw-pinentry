import 'assuan_error_code.dart';

class AssuanException implements Exception {
  final int code;
  final String message;

  AssuanException(this.message, [int? code])
    : code = code ?? AssuanErrorCode.general.code;

  AssuanException.code(AssuanErrorCode code, [String? message])
    : code = code.code,
      message = message ?? code.message;

  AssuanErrorCode? get knowErrorCode =>
      AssuanErrorCode.values.where((c) => c.code == code).firstOrNull;

  @override
  String toString() => 'AssuanException($code): $message';
}
