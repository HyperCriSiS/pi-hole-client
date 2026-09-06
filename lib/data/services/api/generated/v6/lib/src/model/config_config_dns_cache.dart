//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'config_config_dns_cache.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ConfigConfigDnsCache {
  /// Returns a new [ConfigConfigDnsCache] instance.
  ConfigConfigDnsCache({
    this.size,

    this.optimizer,

    this.upstreamBlockedTTL,

    this.rrtype,
  });

  @JsonKey(name: r'size', required: false, includeIfNull: false)
  final int? size;

  @JsonKey(name: r'optimizer', required: false, includeIfNull: false)
  final int? optimizer;

  @JsonKey(name: r'upstreamBlockedTTL', required: false, includeIfNull: false)
  final int? upstreamBlockedTTL;

  @JsonKey(name: r'rrtype', required: false, includeIfNull: false)
  final String? rrtype;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfigConfigDnsCache &&
          other.size == size &&
          other.optimizer == optimizer &&
          other.upstreamBlockedTTL == upstreamBlockedTTL &&
          other.rrtype == rrtype;

  @override
  int get hashCode =>
      size.hashCode +
      optimizer.hashCode +
      upstreamBlockedTTL.hashCode +
      rrtype.hashCode;

  factory ConfigConfigDnsCache.fromJson(Map<String, dynamic> json) =>
      _$ConfigConfigDnsCacheFromJson(json);

  Map<String, dynamic> toJson() => _$ConfigConfigDnsCacheToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
