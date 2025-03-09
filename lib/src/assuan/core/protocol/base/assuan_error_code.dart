// https://github.com/gpg/libgpg-error/blob/master/src/err-codes.h.in#L293
enum AssuanErrorCode {
  general(257, 'General IPC error'),
  acceptFailed(258, 'IPC accept call failed'),
  connectFailed(259, 'IPC connect call failed'),
  invResponse(260, 'Invalid IPC response'),
  invValue(261, 'Invalid value passed to IPC'),
  incompleteLine(262, 'Incomplete line passed to IPC'),
  lineTooLong(263, 'Line passed to IPC too long'),
  nestedCommands(264, 'Nested IPC commands'),
  noDataCb(265, 'No data callback in IPC'),
  noInquireCb(266, 'No inquire callback in IPC'),
  notAServer(267, 'Not an IPC server'),
  notAClient(268, 'Not an IPC client'),
  serverStart(269, 'Problem starting IPC server'),
  readError(270, 'IPC read error'),
  writeError(271, 'IPC write error'),
  // reserved
  tooMuchData(273, 'Too much data for IPC layer'),
  unexpectedCmd(274, 'Unexpected IPC command'),
  unknownCmd(275, 'Unknown IPC command'),
  syntax(276, 'IPC syntax error'),
  canceled(277, 'IPC call has been cancelled'),
  noInput(278, 'No input source for IPC'),
  noOutput(279, 'No output source for IPC'),
  parameter(280, 'IPC parameter error'),
  unknownInquire(281, 'Unknown IPC inquire');

  final int code;
  final String message;

  const AssuanErrorCode(this.code, this.message);
}
