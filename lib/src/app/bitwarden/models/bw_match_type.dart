import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'id')
enum BwMatchType(final int id) {
  domain(0),
  host(1),
  startsWith(2),
  exact(3),
  regExp(4),
  never(5),
}
