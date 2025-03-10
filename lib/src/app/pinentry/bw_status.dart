import 'package:freezed_annotation/freezed_annotation.dart';

part 'bw_status.freezed.dart';

@freezed
sealed class BwStatus with _$BwStatus {
  static const _prefix = 'bw_pinentry';

  const factory BwStatus.proxy(String status) = _BwProxyStatus;
  const factory BwStatus.generic(String $keyword, String status) =
      _BwGenericStatus;

  const BwStatus._();

  String get keyword => switch (this) {
    _BwProxyStatus() => '${_prefix}_proxy',
    _BwGenericStatus(:final $keyword) => $keyword,
  };
}
