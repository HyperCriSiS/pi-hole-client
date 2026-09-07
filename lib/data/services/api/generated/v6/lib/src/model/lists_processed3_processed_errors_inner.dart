//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lists_processed3_processed_errors_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ListsProcessed3ProcessedErrorsInner {
  /// Returns a new [ListsProcessed3ProcessedErrorsInner] instance.
  ListsProcessed3ProcessedErrorsInner({this.item, this.error});

  /// Client that could not be added to the database
  @JsonKey(name: r'item', required: false, includeIfNull: false)
  final String? item;

  /// Error message
  @JsonKey(name: r'error', required: false, includeIfNull: false)
  final String? error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListsProcessed3ProcessedErrorsInner &&
          other.item == item &&
          other.error == error;

  @override
  int get hashCode => item.hashCode + error.hashCode;

  factory ListsProcessed3ProcessedErrorsInner.fromJson(
    Map<String, dynamic> json,
  ) => _$ListsProcessed3ProcessedErrorsInnerFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ListsProcessed3ProcessedErrorsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
