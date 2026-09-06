//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'suggestions2_clients_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Suggestions2ClientsInner {
  /// Returns a new [Suggestions2ClientsInner] instance.
  Suggestions2ClientsInner({
    this.hwaddr,

    this.macVendor,

    this.lastQuery,

    this.addresses,

    this.names,
  });

  @JsonKey(name: r'hwaddr', required: false, includeIfNull: false)
  final String? hwaddr;

  @JsonKey(name: r'macVendor', required: false, includeIfNull: false)
  final String? macVendor;

  @JsonKey(name: r'lastQuery', required: false, includeIfNull: false)
  final int? lastQuery;

  /// Comma-separated list of IP addresses
  @JsonKey(name: r'addresses', required: false, includeIfNull: false)
  final String? addresses;

  /// Comma-separated list of hostnames (if available)
  @JsonKey(name: r'names', required: false, includeIfNull: false)
  final String? names;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Suggestions2ClientsInner &&
          other.hwaddr == hwaddr &&
          other.macVendor == macVendor &&
          other.lastQuery == lastQuery &&
          other.addresses == addresses &&
          other.names == names;

  @override
  int get hashCode =>
      (hwaddr == null ? 0 : hwaddr.hashCode) +
      (macVendor == null ? 0 : macVendor.hashCode) +
      lastQuery.hashCode +
      (addresses == null ? 0 : addresses.hashCode) +
      (names == null ? 0 : names.hashCode);

  factory Suggestions2ClientsInner.fromJson(Map<String, dynamic> json) =>
      _$Suggestions2ClientsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$Suggestions2ClientsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
