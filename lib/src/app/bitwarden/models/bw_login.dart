import 'package:freezed_annotation/freezed_annotation.dart';

import 'bw_uri.dart';

part 'bw_login.freezed.dart';
part 'bw_login.g.dart';

@freezed
sealed class BwLogin with _$BwLogin {
  const factory BwLogin({
    String? username,
    String? password,
    String? totp,
    @Default([]) List<BwUri> uris,
    @Default([]) List<dynamic> fido2Credentials,
    DateTime? passwordRevisionDate,
  }) = _BwLogin;

  factory BwLogin.fromJson(Map<String, dynamic> json) =>
      _$BwLoginFromJson(json);
}
