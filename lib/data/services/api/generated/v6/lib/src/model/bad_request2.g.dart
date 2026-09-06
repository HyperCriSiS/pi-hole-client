// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bad_request2.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BadRequest2CWProxy {
  BadRequest2 error(BadRequest2Error? error);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BadRequest2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BadRequest2(...).copyWith(id: 12, name: "My name")
  /// ````
  BadRequest2 call({BadRequest2Error? error});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfBadRequest2.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfBadRequest2.copyWith.fieldName(...)`
class _$BadRequest2CWProxyImpl implements _$BadRequest2CWProxy {
  const _$BadRequest2CWProxyImpl(this._value);

  final BadRequest2 _value;

  @override
  BadRequest2 error(BadRequest2Error? error) => this(error: error);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BadRequest2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BadRequest2(...).copyWith(id: 12, name: "My name")
  /// ````
  BadRequest2 call({Object? error = const $CopyWithPlaceholder()}) {
    return BadRequest2(
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as BadRequest2Error?,
    );
  }
}

extension $BadRequest2CopyWith on BadRequest2 {
  /// Returns a callable class that can be used as follows: `instanceOfBadRequest2.copyWith(...)` or like so:`instanceOfBadRequest2.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BadRequest2CWProxy get copyWith => _$BadRequest2CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BadRequest2 _$BadRequest2FromJson(Map<String, dynamic> json) =>
    $checkedCreate('BadRequest2', json, ($checkedConvert) {
      final val = BadRequest2(
        error: $checkedConvert(
          'error',
          (v) => v == null
              ? null
              : BadRequest2Error.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$BadRequest2ToJson(BadRequest2 instance) =>
    <String, dynamic>{'error': ?instance.error?.toJson()};
