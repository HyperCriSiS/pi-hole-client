// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'props_config_read_only_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PropsConfigReadOnlyInnerCWProxy {
  PropsConfigReadOnlyInner key(String? key);

  PropsConfigReadOnlyInner reason(String? reason);

  PropsConfigReadOnlyInner description(String? description);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PropsConfigReadOnlyInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PropsConfigReadOnlyInner(...).copyWith(id: 12, name: "My name")
  /// ````
  PropsConfigReadOnlyInner call({
    String? key,
    String? reason,
    String? description,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPropsConfigReadOnlyInner.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPropsConfigReadOnlyInner.copyWith.fieldName(...)`
class _$PropsConfigReadOnlyInnerCWProxyImpl
    implements _$PropsConfigReadOnlyInnerCWProxy {
  const _$PropsConfigReadOnlyInnerCWProxyImpl(this._value);

  final PropsConfigReadOnlyInner _value;

  @override
  PropsConfigReadOnlyInner key(String? key) => this(key: key);

  @override
  PropsConfigReadOnlyInner reason(String? reason) => this(reason: reason);

  @override
  PropsConfigReadOnlyInner description(String? description) =>
      this(description: description);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PropsConfigReadOnlyInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PropsConfigReadOnlyInner(...).copyWith(id: 12, name: "My name")
  /// ````
  PropsConfigReadOnlyInner call({
    Object? key = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
  }) {
    return PropsConfigReadOnlyInner(
      key: key == const $CopyWithPlaceholder()
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as String?,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String?,
      description: description == const $CopyWithPlaceholder()
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String?,
    );
  }
}

extension $PropsConfigReadOnlyInnerCopyWith on PropsConfigReadOnlyInner {
  /// Returns a callable class that can be used as follows: `instanceOfPropsConfigReadOnlyInner.copyWith(...)` or like so:`instanceOfPropsConfigReadOnlyInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PropsConfigReadOnlyInnerCWProxy get copyWith =>
      _$PropsConfigReadOnlyInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PropsConfigReadOnlyInner _$PropsConfigReadOnlyInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PropsConfigReadOnlyInner', json, ($checkedConvert) {
  final val = PropsConfigReadOnlyInner(
    key: $checkedConvert('key', (v) => v as String?),
    reason: $checkedConvert('reason', (v) => v as String?),
    description: $checkedConvert('description', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$PropsConfigReadOnlyInnerToJson(
  PropsConfigReadOnlyInner instance,
) => <String, dynamic>{
  'key': ?instance.key,
  'reason': ?instance.reason,
  'description': ?instance.description,
};
