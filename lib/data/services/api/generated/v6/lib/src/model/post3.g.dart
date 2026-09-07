// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post3.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Post3CWProxy {
  Post3 client(StringOrList? client);

  Post3 comment(String? comment);

  Post3 groups(List<int>? groups);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Post3(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Post3(...).copyWith(id: 12, name: "My name")
  /// ````
  Post3 call({StringOrList? client, String? comment, List<int>? groups});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPost3.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPost3.copyWith.fieldName(...)`
class _$Post3CWProxyImpl implements _$Post3CWProxy {
  const _$Post3CWProxyImpl(this._value);

  final Post3 _value;

  @override
  Post3 client(StringOrList? client) => this(client: client);

  @override
  Post3 comment(String? comment) => this(comment: comment);

  @override
  Post3 groups(List<int>? groups) => this(groups: groups);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Post3(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Post3(...).copyWith(id: 12, name: "My name")
  /// ````
  Post3 call({
    Object? client = const $CopyWithPlaceholder(),
    Object? comment = const $CopyWithPlaceholder(),
    Object? groups = const $CopyWithPlaceholder(),
  }) {
    return Post3(
      client: client == const $CopyWithPlaceholder()
          ? _value.client
          // ignore: cast_nullable_to_non_nullable
          : client as StringOrList?,
      comment: comment == const $CopyWithPlaceholder()
          ? _value.comment
          // ignore: cast_nullable_to_non_nullable
          : comment as String?,
      groups: groups == const $CopyWithPlaceholder()
          ? _value.groups
          // ignore: cast_nullable_to_non_nullable
          : groups as List<int>?,
    );
  }
}

extension $Post3CopyWith on Post3 {
  /// Returns a callable class that can be used as follows: `instanceOfPost3.copyWith(...)` or like so:`instanceOfPost3.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Post3CWProxy get copyWith => _$Post3CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Post3 _$Post3FromJson(Map<String, dynamic> json) =>
    $checkedCreate('Post3', json, ($checkedConvert) {
      final val = Post3(
        client: $checkedConvert(
          'client',
          (v) => v == null ? null : StringOrList.fromJson(v),
        ),
        comment: $checkedConvert('comment', (v) => v as String?),
        groups: $checkedConvert(
          'groups',
          (v) =>
              (v as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ??
              [0],
        ),
      );
      return val;
    });

Map<String, dynamic> _$Post3ToJson(Post3 instance) => <String, dynamic>{
  'client': ?instance.client?.toJson(),
  'comment': ?instance.comment,
  'groups': ?instance.groups,
};
