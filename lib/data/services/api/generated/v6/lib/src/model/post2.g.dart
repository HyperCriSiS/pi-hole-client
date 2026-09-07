// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post2.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Post2CWProxy {
  Post2 name(StringOrList? name);

  Post2 comment(String? comment);

  Post2 enabled(bool? enabled);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Post2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Post2(...).copyWith(id: 12, name: "My name")
  /// ````
  Post2 call({StringOrList? name, String? comment, bool? enabled});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPost2.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPost2.copyWith.fieldName(...)`
class _$Post2CWProxyImpl implements _$Post2CWProxy {
  const _$Post2CWProxyImpl(this._value);

  final Post2 _value;

  @override
  Post2 name(StringOrList? name) => this(name: name);

  @override
  Post2 comment(String? comment) => this(comment: comment);

  @override
  Post2 enabled(bool? enabled) => this(enabled: enabled);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Post2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Post2(...).copyWith(id: 12, name: "My name")
  /// ````
  Post2 call({
    Object? name = const $CopyWithPlaceholder(),
    Object? comment = const $CopyWithPlaceholder(),
    Object? enabled = const $CopyWithPlaceholder(),
  }) {
    return Post2(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as StringOrList?,
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

extension $Post2CopyWith on Post2 {
  /// Returns a callable class that can be used as follows: `instanceOfPost2.copyWith(...)` or like so:`instanceOfPost2.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Post2CWProxy get copyWith => _$Post2CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Post2 _$Post2FromJson(Map<String, dynamic> json) =>
    $checkedCreate('Post2', json, ($checkedConvert) {
      final val = Post2(
        name: $checkedConvert(
          'name',
          (v) => v == null ? null : StringOrList.fromJson(v),
        ),
        comment: $checkedConvert('comment', (v) => v as String?),
        enabled: $checkedConvert('enabled', (v) => v as bool? ?? true),
      );
      return val;
    });

Map<String, dynamic> _$Post2ToJson(Post2 instance) => <String, dynamic>{
  'name': ?instance.name?.toJson(),
  'comment': ?instance.comment,
  'enabled': ?instance.enabled,
};
