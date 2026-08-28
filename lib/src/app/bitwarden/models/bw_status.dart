import 'package:freezed_annotation/freezed_annotation.dart';

part 'bw_status.freezed.dart';
part 'bw_status.g.dart';

enum Status { unauthenticated, locked, unlocked }

@freezed
sealed class BwStatus with _$BwStatus {
  const factory({
    required Status status,
    Uri? serverUrl,
    DateTime? lastSync,
    String? userId,
    String? userEmail,
  }) = _BwStatus;

  factory fromJson(Map<String, dynamic> json) => _$BwStatusFromJson(json);
}
