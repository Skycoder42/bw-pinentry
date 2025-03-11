import 'package:freezed_annotation/freezed_annotation.dart';

import 'bw_field_type.dart';

part 'bw_field.freezed.dart';
part 'bw_field.g.dart';

@freezed
sealed class BwField with _$BwField {
  const factory BwField({
    required BwFieldType type,
    String? name,
    String? value,
    int? linkedId,
  }) = _BwField;

  factory BwField.fromJson(Map<String, dynamic> json) =>
      _$BwFieldFromJson(json);
}
