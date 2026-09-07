//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lists_processed3_processed_success_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ListsProcessed3ProcessedSuccessInner {
  /// Returns a new [ListsProcessed3ProcessedSuccessInner] instance.
  ListsProcessed3ProcessedSuccessInner({this.item});

  /// Client that was added to the database
  @JsonKey(name: r'item', required: false, includeIfNull: false)
  final String? item;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListsProcessed3ProcessedSuccessInner && other.item == item;

  @override
  int get hashCode => item.hashCode;

  factory ListsProcessed3ProcessedSuccessInner.fromJson(
    Map<String, dynamic> json,
  ) => _$ListsProcessed3ProcessedSuccessInnerFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ListsProcessed3ProcessedSuccessInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
