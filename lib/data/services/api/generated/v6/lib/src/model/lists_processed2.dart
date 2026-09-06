//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pihole_v6_api/src/model/lists_processed2_processed.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lists_processed2.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ListsProcessed2 {
  /// Returns a new [ListsProcessed2] instance.
  ListsProcessed2({this.processed});

  @JsonKey(name: r'processed', required: false, includeIfNull: false)
  final ListsProcessed2Processed? processed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListsProcessed2 && other.processed == processed;

  @override
  int get hashCode => (processed == null ? 0 : processed.hashCode);

  factory ListsProcessed2.fromJson(Map<String, dynamic> json) =>
      _$ListsProcessed2FromJson(json);

  Map<String, dynamic> toJson() => _$ListsProcessed2ToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
