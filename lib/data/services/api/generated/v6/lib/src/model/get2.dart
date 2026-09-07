//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pihole_v6_api/src/model/get2_groups_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'get2.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Get2 {
  /// Returns a new [Get2] instance.
  Get2({this.groups});

  @JsonKey(name: r'groups', required: false, includeIfNull: false)
  final List<Get2GroupsInner>? groups;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Get2 && other.groups == groups;

  @override
  int get hashCode => groups.hashCode;

  factory Get2.fromJson(Map<String, dynamic> json) => _$Get2FromJson(json);

  Map<String, dynamic> toJson() => _$Get2ToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
