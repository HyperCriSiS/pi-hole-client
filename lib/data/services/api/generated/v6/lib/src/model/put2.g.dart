// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'put2.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Put2CWProxy {
  Put2 name(String? name);

  Put2 comment(String? comment);

  Put2 enabled(bool? enabled);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Put2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Put2(...).copyWith(id: 12, name: "My name")
  /// ````
  Put2 call({String? name, String? comment, bool? enabled});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPut2.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPut2.copyWith.fieldName(...)`
class _$Put2CWProxyImpl implements _$Put2CWProxy {
  const _$Put2CWProxyImpl(this._value);

  final Put2 _value;

  @override
  Put2 name(String? name) => this(name: name);

  @override
  Put2 comment(String? comment) => this(comment: comment);

  @override
  Put2 enabled(bool? enabled) => this(enabled: enabled);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Put2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Put2(...).copyWith(id: 12, name: "My name")
  /// ````
  Put2 call({
    Object? name = const $CopyWithPlaceholder(),
    Object? comment = const $CopyWithPlaceholder(),
    Object? enabled = const $CopyWithPlaceholder(),
  }) {
    return Put2(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
      comment: comment == const $CopyWithPlaceholder()
          ? _value.comment
          // ignore: cast_nullable_to_non_nullable
          : comment as String?,
      enabled: enabled == const $CopyWithPlaceholder()
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool?,
    );
  }
}

extension $Put2CopyWith on Put2 {
  /// Returns a callable class that can be used as follows: `instanceOfPut2.copyWith(...)` or like so:`instanceOfPut2.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Put2CWProxy get copyWith => _$Put2CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Put2 _$Put2FromJson(Map<String, dynamic> json) =>
    $checkedCreate('Put2', json, ($checkedConvert) {
      final val = Put2(
        name: $checkedConvert('name', (v) => v as String?),
        comment: $checkedConvert('comment', (v) => v as String?),
        enabled: $checkedConvert('enabled', (v) => v as bool? ?? true),
      );
      return val;
    });

Map<String, dynamic> _$Put2ToJson(Put2 instance) => <String, dynamic>{
  'name': ?instance.name,
  'comment': ?instance.comment,
  'enabled': ?instance.enabled,
};
