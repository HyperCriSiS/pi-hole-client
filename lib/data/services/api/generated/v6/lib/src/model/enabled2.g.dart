// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enabled2.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Enabled2CWProxy {
  Enabled2 enabled(bool? enabled);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Enabled2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Enabled2(...).copyWith(id: 12, name: "My name")
  /// ````
  Enabled2 call({bool? enabled});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfEnabled2.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfEnabled2.copyWith.fieldName(...)`
class _$Enabled2CWProxyImpl implements _$Enabled2CWProxy {
  const _$Enabled2CWProxyImpl(this._value);

  final Enabled2 _value;

  @override
  Enabled2 enabled(bool? enabled) => this(enabled: enabled);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Enabled2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Enabled2(...).copyWith(id: 12, name: "My name")
  /// ````
  Enabled2 call({Object? enabled = const $CopyWithPlaceholder()}) {
    return Enabled2(
      enabled: enabled == const $CopyWithPlaceholder()
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool?,
    );
  }
}

extension $Enabled2CopyWith on Enabled2 {
  /// Returns a callable class that can be used as follows: `instanceOfEnabled2.copyWith(...)` or like so:`instanceOfEnabled2.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Enabled2CWProxy get copyWith => _$Enabled2CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Enabled2 _$Enabled2FromJson(Map<String, dynamic> json) =>
    $checkedCreate('Enabled2', json, ($checkedConvert) {
      final val = Enabled2(
        enabled: $checkedConvert('enabled', (v) => v as bool? ?? true),
      );
      return val;
    });

Map<String, dynamic> _$Enabled2ToJson(Enabled2 instance) => <String, dynamic>{
  'enabled': ?instance.enabled,
};
