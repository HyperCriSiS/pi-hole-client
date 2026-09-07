//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lists_processed4_processed_errors_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ListsProcessed4ProcessedErrorsInner {
  /// Returns a new [ListsProcessed4ProcessedErrorsInner] instance.
  ListsProcessed4ProcessedErrorsInner({this.item, this.error});

  /// List that could not be added to the database
  @JsonKey(name: r'item', required: false, includeIfNull: false)
  final String? item;

  /// Error message
  @JsonKey(name: r'error', required: false, includeIfNull: false)
  final String? error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListsProcessed4ProcessedErrorsInner &&
          other.item == item &&
          other.error == error;

  @override
  int get hashCode => item.hashCode + error.hashCode;

  factory ListsProcessed4ProcessedErrorsInner.fromJson(
    Map<String, dynamic> json,
  ) => _$ListsProcessed4ProcessedErrorsInnerFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ListsProcessed4ProcessedErrorsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
