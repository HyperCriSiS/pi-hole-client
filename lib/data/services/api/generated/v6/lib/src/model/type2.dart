//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'type2.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Type2 {
  /// Returns a new [Type2] instance.
  Type2({this.type});

  /// Type of list
  @JsonKey(name: r'type', required: false, includeIfNull: false)
  final Type2TypeEnum? type;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Type2 && other.type == type;

  @override
  int get hashCode => type.hashCode;

  factory Type2.fromJson(Map<String, dynamic> json) => _$Type2FromJson(json);

  Map<String, dynamic> toJson() => _$Type2ToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// Type of list
enum Type2TypeEnum {
  /// Type of list
  @JsonValue(r'allow')
  allow(r'allow'),

  /// Type of list
  @JsonValue(r'block')
  block(r'block');

  const Type2TypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
