//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'comment4.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Comment4 {
  /// Returns a new [Comment4] instance.
  Comment4({this.comment});

  /// User-provided free-text comment for this list
  @JsonKey(name: r'comment', required: false, includeIfNull: false)
  final String? comment;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Comment4 && other.comment == comment;

  @override
  int get hashCode => (comment == null ? 0 : comment.hashCode);

  factory Comment4.fromJson(Map<String, dynamic> json) =>
      _$Comment4FromJson(json);

  Map<String, dynamic> toJson() => _$Comment4ToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
