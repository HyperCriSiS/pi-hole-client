// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queries2_queries_inner_ede.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Queries2QueriesInnerEdeCWProxy {
  Queries2QueriesInnerEde code(int? code);

  Queries2QueriesInnerEde text(String? text);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Queries2QueriesInnerEde(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Queries2QueriesInnerEde(...).copyWith(id: 12, name: "My name")
  /// ````
  Queries2QueriesInnerEde call({int? code, String? text});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfQueries2QueriesInnerEde.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfQueries2QueriesInnerEde.copyWith.fieldName(...)`
class _$Queries2QueriesInnerEdeCWProxyImpl
    implements _$Queries2QueriesInnerEdeCWProxy {
  const _$Queries2QueriesInnerEdeCWProxyImpl(this._value);

  final Queries2QueriesInnerEde _value;

  @override
  Queries2QueriesInnerEde code(int? code) => this(code: code);

  @override
  Queries2QueriesInnerEde text(String? text) => this(text: text);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Queries2QueriesInnerEde(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Queries2QueriesInnerEde(...).copyWith(id: 12, name: "My name")
  /// ````
  Queries2QueriesInnerEde call({
    Object? code = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
  }) {
    return Queries2QueriesInnerEde(
      code: code == const $CopyWithPlaceholder()
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as int?,
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String?,
    );
  }
}

extension $Queries2QueriesInnerEdeCopyWith on Queries2QueriesInnerEde {
  /// Returns a callable class that can be used as follows: `instanceOfQueries2QueriesInnerEde.copyWith(...)` or like so:`instanceOfQueries2QueriesInnerEde.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Queries2QueriesInnerEdeCWProxy get copyWith =>
      _$Queries2QueriesInnerEdeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Queries2QueriesInnerEde _$Queries2QueriesInnerEdeFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('Queries2QueriesInnerEde', json, ($checkedConvert) {
  final val = Queries2QueriesInnerEde(
    code: $checkedConvert('code', (v) => (v as num?)?.toInt()),
    text: $checkedConvert('text', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$Queries2QueriesInnerEdeToJson(
  Queries2QueriesInnerEde instance,
) => <String, dynamic>{'code': ?instance.code, 'text': ?instance.text};
