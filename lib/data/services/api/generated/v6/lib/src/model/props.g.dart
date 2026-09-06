// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'props.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PropsCWProxy {
  Props config(PropsConfig? config);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Props(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Props(...).copyWith(id: 12, name: "My name")
  /// ````
  Props call({PropsConfig? config});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfProps.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfProps.copyWith.fieldName(...)`
class _$PropsCWProxyImpl implements _$PropsCWProxy {
  const _$PropsCWProxyImpl(this._value);

  final Props _value;

  @override
  Props config(PropsConfig? config) => this(config: config);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Props(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Props(...).copyWith(id: 12, name: "My name")
  /// ````
  Props call({Object? config = const $CopyWithPlaceholder()}) {
    return Props(
      config: config == const $CopyWithPlaceholder()
          ? _value.config
          // ignore: cast_nullable_to_non_nullable
          : config as PropsConfig?,
    );
  }
}

extension $PropsCopyWith on Props {
  /// Returns a callable class that can be used as follows: `instanceOfProps.copyWith(...)` or like so:`instanceOfProps.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PropsCWProxy get copyWith => _$PropsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Props _$PropsFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Props',
  json,
  ($checkedConvert) {
    final val = Props(
      config: $checkedConvert(
        'config',
        (v) =>
            v == null ? null : PropsConfig.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
);

Map<String, dynamic> _$PropsToJson(Props instance) => <String, dynamic>{
  'config': ?instance.config?.toJson(),
};
