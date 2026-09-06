//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'groups2.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Groups2 {
  /// Returns a new [Groups2] instance.
  Groups2({this.groups = const [0]});

  /// Array of group IDs
  @JsonKey(
    defaultValue: [0],
    name: r'groups',
    required: false,
    includeIfNull: false,
  )
  final List<int>? groups;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Groups2 && other.groups == groups;

  @override
  int get hashCode => groups.hashCode;

  factory Groups2.fromJson(Map<String, dynamic> json) =>
      _$Groups2FromJson(json);

  Map<String, dynamic> toJson() => _$Groups2ToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
