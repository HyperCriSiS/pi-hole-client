//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'queries2_queries_inner_ede.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Queries2QueriesInnerEde {
  /// Returns a new [Queries2QueriesInnerEde] instance.
  Queries2QueriesInnerEde({this.code, this.text});

  /// EDE code
  @JsonKey(name: r'code', required: false, includeIfNull: false)
  final int? code;

  /// EDE message (if available)
  @JsonKey(name: r'text', required: false, includeIfNull: false)
  final String? text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Queries2QueriesInnerEde &&
          other.code == code &&
          other.text == text;

  @override
  int get hashCode => code.hashCode + (text == null ? 0 : text.hashCode);

  factory Queries2QueriesInnerEde.fromJson(Map<String, dynamic> json) =>
      _$Queries2QueriesInnerEdeFromJson(json);

  Map<String, dynamic> toJson() => _$Queries2QueriesInnerEdeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
