//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'queries2_queries_inner_client.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Queries2QueriesInnerClient {
  /// Returns a new [Queries2QueriesInnerClient] instance.
  Queries2QueriesInnerClient({this.ip, this.name});

  /// Requesting client's IP address
  @JsonKey(name: r'ip', required: false, includeIfNull: false)
  final String? ip;

  /// Requesting client's hostname (if available)
  @JsonKey(name: r'name', required: false, includeIfNull: false)
  final String? name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Queries2QueriesInnerClient &&
          other.ip == ip &&
          other.name == name;

  @override
  int get hashCode => ip.hashCode + (name == null ? 0 : name.hashCode);

  factory Queries2QueriesInnerClient.fromJson(Map<String, dynamic> json) =>
      _$Queries2QueriesInnerClientFromJson(json);

  Map<String, dynamic> toJson() => _$Queries2QueriesInnerClientToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
