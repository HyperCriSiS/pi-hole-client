//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'props_config_read_only_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PropsConfigReadOnlyInner {
  /// Returns a new [PropsConfigReadOnlyInner] instance.
  PropsConfigReadOnlyInner({this.key, this.reason, this.description});

  /// The name of the read-only property
  @JsonKey(name: r'key', required: false, includeIfNull: false)
  final String? key;

  /// The reason why this property is read-only (machine-readable)
  @JsonKey(name: r'reason', required: false, includeIfNull: false)
  final String? reason;

  /// A human-readable description of the read-only reason
  @JsonKey(name: r'description', required: false, includeIfNull: false)
  final String? description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropsConfigReadOnlyInner &&
          other.key == key &&
          other.reason == reason &&
          other.description == description;

  @override
  int get hashCode => key.hashCode + reason.hashCode + description.hashCode;

  factory PropsConfigReadOnlyInner.fromJson(Map<String, dynamic> json) =>
      _$PropsConfigReadOnlyInnerFromJson(json);

  Map<String, dynamic> toJson() => _$PropsConfigReadOnlyInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
