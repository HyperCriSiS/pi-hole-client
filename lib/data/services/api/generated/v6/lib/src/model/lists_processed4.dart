//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pihole_v6_api/src/model/lists_processed4_processed.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lists_processed4.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ListsProcessed4 {
  /// Returns a new [ListsProcessed4] instance.
  ListsProcessed4({this.processed});

  @JsonKey(name: r'processed', required: false, includeIfNull: false)
  final ListsProcessed4Processed? processed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListsProcessed4 && other.processed == processed;

  @override
  int get hashCode => (processed == null ? 0 : processed.hashCode);

  factory ListsProcessed4.fromJson(Map<String, dynamic> json) =>
      _$ListsProcessed4FromJson(json);

  Map<String, dynamic> toJson() => _$ListsProcessed4ToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
