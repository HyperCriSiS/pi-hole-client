//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lists_processed2_processed_success_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ListsProcessed2ProcessedSuccessInner {
  /// Returns a new [ListsProcessed2ProcessedSuccessInner] instance.
  ListsProcessed2ProcessedSuccessInner({this.item});

  /// Group that was added to the database
  @JsonKey(name: r'item', required: false, includeIfNull: false)
  final String? item;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListsProcessed2ProcessedSuccessInner && other.item == item;

  @override
  int get hashCode => item.hashCode;

  factory ListsProcessed2ProcessedSuccessInner.fromJson(
    Map<String, dynamic> json,
  ) => _$ListsProcessed2ProcessedSuccessInnerFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ListsProcessed2ProcessedSuccessInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
