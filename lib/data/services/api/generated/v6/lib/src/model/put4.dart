//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'put4.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Put4 {
  /// Returns a new [Put4] instance.
  Put4({this.comment, this.type, this.groups = const [0], this.enabled = true});

  /// User-provided free-text comment for this list
  @JsonKey(name: r'comment', required: false, includeIfNull: false)
  final String? comment;

  /// Type of list
  @JsonKey(name: r'type', required: false, includeIfNull: false)
  final Put4TypeEnum? type;

  /// Array of group IDs
  @JsonKey(
    defaultValue: [0],
    name: r'groups',
    required: false,
    includeIfNull: false,
  )
  final List<int>? groups;

  /// Status of domain
  @JsonKey(
    defaultValue: true,
    name: r'enabled',
    required: false,
    includeIfNull: false,
  )
  final bool? enabled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Put4 &&
          other.comment == comment &&
          other.type == type &&
          other.groups == groups &&
          other.enabled == enabled;

  @override
  int get hashCode =>
      (comment == null ? 0 : comment.hashCode) +
      type.hashCode +
      groups.hashCode +
      enabled.hashCode;

  factory Put4.fromJson(Map<String, dynamic> json) => _$Put4FromJson(json);

  Map<String, dynamic> toJson() => _$Put4ToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// Type of list
enum Put4TypeEnum {
  /// Type of list
  @JsonValue(r'allow')
  allow(r'allow'),

  /// Type of list
  @JsonValue(r'block')
  block(r'block');

  const Put4TypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
