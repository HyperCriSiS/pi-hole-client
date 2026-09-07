//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pihole_v6_api/src/model/props_config_read_only_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'props_config.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PropsConfig {
  /// Returns a new [PropsConfig] instance.
  PropsConfig({this.readOnly});

  @JsonKey(name: r'read_only', required: false, includeIfNull: false)
  final List<PropsConfigReadOnlyInner>? readOnly;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropsConfig && other.readOnly == readOnly;

  @override
  int get hashCode => readOnly.hashCode;

  factory PropsConfig.fromJson(Map<String, dynamic> json) =>
      _$PropsConfigFromJson(json);

  Map<String, dynamic> toJson() => _$PropsConfigToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
