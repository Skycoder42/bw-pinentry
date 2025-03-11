import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'id')
enum BwMatchType {
  domain(0),
  host(1),
  startsWith(2),
  exact(3),
  regExp(4),
  never(5);

  final int id;
  const BwMatchType(this.id);
}
