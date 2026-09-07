//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pihole_v6_api/src/model/lists_processed3_processed_errors_inner.dart';
import 'package:pihole_v6_api/src/model/lists_processed3_processed_success_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lists_processed3_processed.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ListsProcessed3Processed {
  /// Returns a new [ListsProcessed3Processed] instance.
  ListsProcessed3Processed({this.success, this.errors});

  /// Array of clients that were successfully added to the database.
  @JsonKey(name: r'success', required: false, includeIfNull: false)
  final List<ListsProcessed3ProcessedSuccessInner>? success;

  /// Array of errors that occurred during processing.
  @JsonKey(name: r'errors', required: false, includeIfNull: false)
  final List<ListsProcessed3ProcessedErrorsInner>? errors;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListsProcessed3Processed &&
          other.success == success &&
          other.errors == errors;

  @override
  int get hashCode => success.hashCode + errors.hashCode;

  factory ListsProcessed3Processed.fromJson(Map<String, dynamic> json) =>
      _$ListsProcessed3ProcessedFromJson(json);

  Map<String, dynamic> toJson() => _$ListsProcessed3ProcessedToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
