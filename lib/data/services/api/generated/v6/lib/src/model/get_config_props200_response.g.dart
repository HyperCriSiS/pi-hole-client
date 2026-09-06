// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_config_props200_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GetConfigProps200ResponseCWProxy {
  GetConfigProps200Response config(PropsConfig? config);

  GetConfigProps200Response took(num? took);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GetConfigProps200Response(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GetConfigProps200Response(...).copyWith(id: 12, name: "My name")
  /// ````
  GetConfigProps200Response call({PropsConfig? config, num? took});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGetConfigProps200Response.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGetConfigProps200Response.copyWith.fieldName(...)`
class _$GetConfigProps200ResponseCWProxyImpl
    implements _$GetConfigProps200ResponseCWProxy {
  const _$GetConfigProps200ResponseCWProxyImpl(this._value);

  final GetConfigProps200Response _value;

  @override
  GetConfigProps200Response config(PropsConfig? config) => this(config: config);

  @override
  GetConfigProps200Response took(num? took) => this(took: took);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GetConfigProps200Response(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GetConfigProps200Response(...).copyWith(id: 12, name: "My name")
  /// ````
  GetConfigProps200Response call({
    Object? config = const $CopyWithPlaceholder(),
    Object? took = const $CopyWithPlaceholder(),
  }) {
    return GetConfigProps200Response(
      config: config == const $CopyWithPlaceholder()
          ? _value.config
          // ignore: cast_nullable_to_non_nullable
          : config as PropsConfig?,
      took: took == const $CopyWithPlaceholder()
          ? _value.took
          // ignore: cast_nullable_to_non_nullable
          : took as num?,
    );
  }
}

extension $GetConfigProps200ResponseCopyWith on GetConfigProps200Response {
  /// Returns a callable class that can be used as follows: `instanceOfGetConfigProps200Response.copyWith(...)` or like so:`instanceOfGetConfigProps200Response.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GetConfigProps200ResponseCWProxy get copyWith =>
      _$GetConfigProps200ResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetConfigProps200Response _$GetConfigProps200ResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GetConfigProps200Response', json, ($checkedConvert) {
  final val = GetConfigProps200Response(
    config: $checkedConvert(
      'config',
      (v) => v == null ? null : PropsConfig.fromJson(v as Map<String, dynamic>),
    ),
    took: $checkedConvert('took', (v) => v as num?),
  );
  return val;
});

Map<String, dynamic> _$GetConfigProps200ResponseToJson(
  GetConfigProps200Response instance,
) => <String, dynamic>{
  'config': ?instance.config?.toJson(),
  'took': ?instance.took,
};
