// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_domain200_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GetDomain200ResponseCWProxy {
  GetDomain200Response domains(List<GetDomainsInner>? domains);

  GetDomain200Response took(num? took);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GetDomain200Response(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GetDomain200Response(...).copyWith(id: 12, name: "My name")
  /// ````
  GetDomain200Response call({List<GetDomainsInner>? domains, num? took});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGetDomain200Response.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGetDomain200Response.copyWith.fieldName(...)`
class _$GetDomain200ResponseCWProxyImpl
    implements _$GetDomain200ResponseCWProxy {
  const _$GetDomain200ResponseCWProxyImpl(this._value);

  final GetDomain200Response _value;

  @override
  GetDomain200Response domains(List<GetDomainsInner>? domains) =>
      this(domains: domains);

  @override
  GetDomain200Response took(num? took) => this(took: took);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GetDomain200Response(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GetDomain200Response(...).copyWith(id: 12, name: "My name")
  /// ````
  GetDomain200Response call({
    Object? domains = const $CopyWithPlaceholder(),
    Object? took = const $CopyWithPlaceholder(),
  }) {
    return GetDomain200Response(
      domains: domains == const $CopyWithPlaceholder()
          ? _value.domains
          // ignore: cast_nullable_to_non_nullable
          : domains as List<GetDomainsInner>?,
      took: took == const $CopyWithPlaceholder()
          ? _value.took
          // ignore: cast_nullable_to_non_nullable
          : took as num?,
    );
  }
}

extension $GetDomain200ResponseCopyWith on GetDomain200Response {
  /// Returns a callable class that can be used as follows: `instanceOfGetDomain200Response.copyWith(...)` or like so:`instanceOfGetDomain200Response.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GetDomain200ResponseCWProxy get copyWith =>
      _$GetDomain200ResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetDomain200Response _$GetDomain200ResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GetDomain200Response', json, ($checkedConvert) {
  final val = GetDomain200Response(
    domains: $checkedConvert(
      'domains',
      (v) => (v as List<dynamic>?)
          ?.map((e) => GetDomainsInner.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    took: $checkedConvert('took', (v) => v as num?),
  );
  return val;
});

Map<String, dynamic> _$GetDomain200ResponseToJson(
  GetDomain200Response instance,
) => <String, dynamic>{
  'domains': ?instance.domains?.map((e) => e.toJson()).toList(),
  'took': ?instance.took,
};
