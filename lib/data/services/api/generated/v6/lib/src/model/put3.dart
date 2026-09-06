//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'put3.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Put3 {
  /// Returns a new [Put3] instance.
  Put3({this.comment, this.groups = const [0]});

  /// User-provided free-text comment for this client
  @JsonKey(name: r'comment', required: false, includeIfNull: false)
  final String? comment;

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
      identical(this, other) ||
      other is Put3 && other.comment == comment && other.groups == groups;

  @override
  int get hashCode =>
      (comment == null ? 0 : comment.hashCode) + groups.hashCode;

  factory Put3.fromJson(Map<String, dynamic> json) => _$Put3FromJson(json);

  Map<String, dynamic> toJson() => _$Put3ToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
