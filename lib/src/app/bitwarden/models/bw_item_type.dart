import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'id')
enum BwItemType {
  login(1),
  secureNote(2),
  card(3),
  identity(4),
  sshKey(5);

  final int id;
  const BwItemType(this.id);
}
