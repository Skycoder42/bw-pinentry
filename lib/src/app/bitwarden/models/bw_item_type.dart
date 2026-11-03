import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'id')
enum BwItemType(final int id) {
  login(1),
  secureNote(2),
  card(3),
  identity(4),
  sshKey(5),
}
