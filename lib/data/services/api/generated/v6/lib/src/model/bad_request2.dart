//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pihole_v6_api/src/model/bad_request2_error.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bad_request2.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BadRequest2 {
  /// Returns a new [BadRequest2] instance.
  BadRequest2({this.error});

  @JsonKey(name: r'error', required: false, includeIfNull: false)
  final BadRequest2Error? error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BadRequest2 && other.error == error;

  @override
  int get hashCode => error.hashCode;

  factory BadRequest2.fromJson(Map<String, dynamic> json) =>
      _$BadRequest2FromJson(json);

  Map<String, dynamic> toJson() => _$BadRequest2ToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
