import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'id')
enum BwFieldType(final int id) {
  text(0),
  hidden(1),
  boolean(2),
  linked(3),
}
