import 'package:freezed_annotation/freezed_annotation.dart';

import 'bw_field.dart';
import 'bw_item_type.dart';
import 'bw_login.dart';

part 'bw_object.freezed.dart';
part 'bw_object.g.dart';

@Freezed(unionKey: 'object')
sealed class BwObject with _$BwObject {
  const factory folder({required String id, required String name}) = BwFolder;

  const factory item({
    required String id,
    required String name,
    required String folderId,
    required BwItemType type,
    @Default([]) List<BwField> fields,
    BwLogin? login,
  }) = BwItem;

  factory fromJson(Map<String, dynamic> json) => _$BwObjectFromJson(json);
}
