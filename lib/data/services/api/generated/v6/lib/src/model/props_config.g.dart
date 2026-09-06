// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'props_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PropsConfigCWProxy {
  PropsConfig readOnly(List<PropsConfigReadOnlyInner>? readOnly);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PropsConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PropsConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  PropsConfig call({List<PropsConfigReadOnlyInner>? readOnly});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPropsConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPropsConfig.copyWith.fieldName(...)`
class _$PropsConfigCWProxyImpl implements _$PropsConfigCWProxy {
  const _$PropsConfigCWProxyImpl(this._value);

  final PropsConfig _value;

  @override
  PropsConfig readOnly(List<PropsConfigReadOnlyInner>? readOnly) =>
      this(readOnly: readOnly);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PropsConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PropsConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  PropsConfig call({Object? readOnly = const $CopyWithPlaceholder()}) {
    return PropsConfig(
      readOnly: readOnly == const $CopyWithPlaceholder()
          ? _value.readOnly
          // ignore: cast_nullable_to_non_nullable
          : readOnly as List<PropsConfigReadOnlyInner>?,
    );
  }
}

extension $PropsConfigCopyWith on PropsConfig {
  /// Returns a callable class that can be used as follows: `instanceOfPropsConfig.copyWith(...)` or like so:`instanceOfPropsConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PropsConfigCWProxy get copyWith => _$PropsConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PropsConfig _$PropsConfigFromJson(Map<String, dynamic> json) => $checkedCreate(
  'PropsConfig',
  json,
  ($checkedConvert) {
    final val = PropsConfig(
      readOnly: $checkedConvert(
        'read_only',
        (v) => (v as List<dynamic>?)
            ?.map(
              (e) =>
                  PropsConfigReadOnlyInner.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'readOnly': 'read_only'},
);

Map<String, dynamic> _$PropsConfigToJson(PropsConfig instance) =>
    <String, dynamic>{
      'read_only': ?instance.readOnly?.map((e) => e.toJson()).toList(),
    };
