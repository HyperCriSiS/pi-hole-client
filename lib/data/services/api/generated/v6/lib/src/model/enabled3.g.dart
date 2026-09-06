// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enabled3.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Enabled3CWProxy {
  Enabled3 enabled(bool? enabled);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Enabled3(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Enabled3(...).copyWith(id: 12, name: "My name")
  /// ````
  Enabled3 call({bool? enabled});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfEnabled3.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfEnabled3.copyWith.fieldName(...)`
class _$Enabled3CWProxyImpl implements _$Enabled3CWProxy {
  const _$Enabled3CWProxyImpl(this._value);

  final Enabled3 _value;

  @override
  Enabled3 enabled(bool? enabled) => this(enabled: enabled);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Enabled3(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Enabled3(...).copyWith(id: 12, name: "My name")
  /// ````
  Enabled3 call({Object? enabled = const $CopyWithPlaceholder()}) {
    return Enabled3(
      enabled: enabled == const $CopyWithPlaceholder()
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool?,
    );
  }
}

extension $Enabled3CopyWith on Enabled3 {
  /// Returns a callable class that can be used as follows: `instanceOfEnabled3.copyWith(...)` or like so:`instanceOfEnabled3.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Enabled3CWProxy get copyWith => _$Enabled3CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Enabled3 _$Enabled3FromJson(Map<String, dynamic> json) =>
    $checkedCreate('Enabled3', json, ($checkedConvert) {
      final val = Enabled3(
        enabled: $checkedConvert('enabled', (v) => v as bool? ?? true),
      );
      return val;
    });

Map<String, dynamic> _$Enabled3ToJson(Enabled3 instance) => <String, dynamic>{
  'enabled': ?instance.enabled,
};
