//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'enabled3.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Enabled3 {
  /// Returns a new [Enabled3] instance.
  Enabled3({this.enabled = true});

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
      identical(this, other) || other is Enabled3 && other.enabled == enabled;

  @override
  int get hashCode => enabled.hashCode;

  factory Enabled3.fromJson(Map<String, dynamic> json) =>
      _$Enabled3FromJson(json);

  Map<String, dynamic> toJson() => _$Enabled3ToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
