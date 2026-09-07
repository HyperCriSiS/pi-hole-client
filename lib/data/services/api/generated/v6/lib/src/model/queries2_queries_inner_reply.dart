//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'queries2_queries_inner_reply.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Queries2QueriesInnerReply {
  /// Returns a new [Queries2QueriesInnerReply] instance.
  Queries2QueriesInnerReply({this.type, this.time});

  /// Reply type
  @JsonKey(name: r'type', required: false, includeIfNull: false)
  final String? type;

  /// Time until the response was received (ms, negative if N/A)
  @JsonKey(name: r'time', required: false, includeIfNull: false)
  final num? time;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Queries2QueriesInnerReply &&
          other.type == type &&
          other.time == time;

  @override
  int get hashCode => (type == null ? 0 : type.hashCode) + time.hashCode;

  factory Queries2QueriesInnerReply.fromJson(Map<String, dynamic> json) =>
      _$Queries2QueriesInnerReplyFromJson(json);

  Map<String, dynamic> toJson() => _$Queries2QueriesInnerReplyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
