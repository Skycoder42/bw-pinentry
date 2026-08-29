import 'package:freezed_annotation/freezed_annotation.dart';

import 'bw_match_type.dart';

part 'bw_uri.freezed.dart';
part 'bw_uri.g.dart';

@freezed
sealed class BwUri with _$BwUri {
  const factory(String uri, [BwMatchType? match]) = _BwUri;

  factory fromJson(Map<String, dynamic> json) => _$BwUriFromJson(json);
}
