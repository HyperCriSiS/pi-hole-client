//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pihole_v6_api/src/model/get_domains_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'get_domain200_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GetDomain200Response {
  /// Returns a new [GetDomain200Response] instance.
  GetDomain200Response({this.domains, this.took});

  /// Array of domains
  @JsonKey(name: r'domains', required: false, includeIfNull: false)
  final List<GetDomainsInner>? domains;

  /// Time in seconds it took to process the request
  @JsonKey(name: r'took', required: false, includeIfNull: false)
  final num? took;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetDomain200Response &&
          other.domains == domains &&
          other.took == took;

  @override
  int get hashCode => domains.hashCode + took.hashCode;

  factory GetDomain200Response.fromJson(Map<String, dynamic> json) =>
      _$GetDomain200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GetDomain200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
