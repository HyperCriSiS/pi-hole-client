//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'post5.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Post5 {
  /// Returns a new [Post5] instance.
  Post5({this.processed});

  @JsonKey(name: r'processed', required: false, includeIfNull: false)
  final List<String>? processed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Post5 && other.processed == processed;

  @override
  int get hashCode => processed.hashCode;

  factory Post5.fromJson(Map<String, dynamic> json) => _$Post5FromJson(json);

  Map<String, dynamic> toJson() => _$Post5ToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
