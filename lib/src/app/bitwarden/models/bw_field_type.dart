import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'id')
enum BwFieldType {
  text(0),
  hidden(1),
  boolean(2),
  linked(3);

  final int id;

  const BwFieldType(this.id);
}
