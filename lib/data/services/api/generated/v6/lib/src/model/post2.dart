//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pihole_v6_api/src/model/string_or_list.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'post2.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Post2 {
  /// Returns a new [Post2] instance.
  Post2({this.name, this.comment, this.enabled = true});

  @JsonKey(name: r'name', required: false, includeIfNull: false)
  final StringOrList? name;

  /// User-provided free-text comment for this group
  @JsonKey(name: r'comment', required: false, includeIfNull: false)
  final String? comment;

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
      identical(this, other) ||
      other is Post2 &&
          other.name == name &&
          other.comment == comment &&
          other.enabled == enabled;

  @override
  int get hashCode =>
      name.hashCode +
      (comment == null ? 0 : comment.hashCode) +
      enabled.hashCode;

  factory Post2.fromJson(Map<String, dynamic> json) => _$Post2FromJson(json);

  Map<String, dynamic> toJson() => _$Post2ToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
