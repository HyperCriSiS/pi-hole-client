//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'enabled2.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Enabled2 {
  /// Returns a new [Enabled2] instance.
  Enabled2({this.enabled = true});

  /// Status of item
  @JsonKey(
    defaultValue: true,
    name: r'enabled',
    required: false,
    includeIfNull: false,
  )
  final bool? enabled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Enabled2 && other.enabled == enabled;

  @override
  int get hashCode => enabled.hashCode;

  factory Enabled2.fromJson(Map<String, dynamic> json) =>
      _$Enabled2FromJson(json);

  Map<String, dynamic> toJson() => _$Enabled2ToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
