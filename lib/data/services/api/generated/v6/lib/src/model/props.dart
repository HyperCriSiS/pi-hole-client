//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pihole_v6_api/src/model/props_config.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'props.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Props {
  /// Returns a new [Props] instance.
  Props({this.config});

  @JsonKey(name: r'config', required: false, includeIfNull: false)
  final PropsConfig? config;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Props && other.config == config;

  @override
  int get hashCode => config.hashCode;

  factory Props.fromJson(Map<String, dynamic> json) => _$PropsFromJson(json);

  Map<String, dynamic> toJson() => _$PropsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
