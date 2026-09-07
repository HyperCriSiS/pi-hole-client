//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'readonly2.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Readonly2 {
  /// Returns a new [Readonly2] instance.
  Readonly2({this.id, this.dateAdded, this.dateModified});

  /// Database ID
  @JsonKey(name: r'id', required: false, includeIfNull: false)
  final int? id;

  /// Unix timestamp of item addition
  @JsonKey(name: r'date_added', required: false, includeIfNull: false)
  final int? dateAdded;

  /// Unix timestamp of last item modification
  @JsonKey(name: r'date_modified', required: false, includeIfNull: false)
  final int? dateModified;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Readonly2 &&
          other.id == id &&
          other.dateAdded == dateAdded &&
          other.dateModified == dateModified;

  @override
  int get hashCode => id.hashCode + dateAdded.hashCode + dateModified.hashCode;

  factory Readonly2.fromJson(Map<String, dynamic> json) =>
      _$Readonly2FromJson(json);

  Map<String, dynamic> toJson() => _$Readonly2ToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
