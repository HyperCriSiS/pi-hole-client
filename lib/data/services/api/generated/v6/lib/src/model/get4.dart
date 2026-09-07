//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pihole_v6_api/src/model/get4_lists_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'get4.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Get4 {
  /// Returns a new [Get4] instance.
  Get4({this.lists});

  /// Array of lists
  @JsonKey(name: r'lists', required: false, includeIfNull: false)
  final List<Get4ListsInner>? lists;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Get4 && other.lists == lists;

  @override
  int get hashCode => lists.hashCode;

  factory Get4.fromJson(Map<String, dynamic> json) => _$Get4FromJson(json);

  Map<String, dynamic> toJson() => _$Get4ToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
