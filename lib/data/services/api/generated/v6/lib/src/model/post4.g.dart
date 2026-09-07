// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post4.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Post4CWProxy {
  Post4 address(StringOrList? address);

  Post4 comment(String? comment);

  Post4 groups(List<int>? groups);

  Post4 enabled(bool? enabled);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Post4(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Post4(...).copyWith(id: 12, name: "My name")
  /// ````
  Post4 call({
    StringOrList? address,
    String? comment,
    List<int>? groups,
    bool? enabled,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPost4.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPost4.copyWith.fieldName(...)`
class _$Post4CWProxyImpl implements _$Post4CWProxy {
  const _$Post4CWProxyImpl(this._value);

  final Post4 _value;

  @override
  Post4 address(StringOrList? address) => this(address: address);

  @override
  Post4 comment(String? comment) => this(comment: comment);

  @override
  Post4 groups(List<int>? groups) => this(groups: groups);

  @override
  Post4 enabled(bool? enabled) => this(enabled: enabled);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Post4(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Post4(...).copyWith(id: 12, name: "My name")
  /// ````
  Post4 call({
    Object? address = const $CopyWithPlaceholder(),
    Object? comment = const $CopyWithPlaceholder(),
    Object? groups = const $CopyWithPlaceholder(),
    Object? enabled = const $CopyWithPlaceholder(),
  }) {
    return Post4(
      address: address == const $CopyWithPlaceholder()
          ? _value.address
          // ignore: cast_nullable_to_non_nullable
          : address as StringOrList?,
      comment: comment == const $CopyWithPlaceholder()
          ? _value.comment
          // ignore: cast_nullable_to_non_nullable
          : comment as String?,
      groups: groups == const $CopyWithPlaceholder()
          ? _value.groups
          // ignore: cast_nullable_to_non_nullable
          : groups as List<int>?,
      enabled: enabled == const $CopyWithPlaceholder()
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool?,
    );
  }
}

extension $Post4CopyWith on Post4 {
  /// Returns a callable class that can be used as follows: `instanceOfPost4.copyWith(...)` or like so:`instanceOfPost4.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Post4CWProxy get copyWith => _$Post4CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Post4 _$Post4FromJson(Map<String, dynamic> json) =>
    $checkedCreate('Post4', json, ($checkedConvert) {
      final val = Post4(
        address: $checkedConvert(
          'address',
          (v) => v == null ? null : StringOrList.fromJson(v),
        ),
        comment: $checkedConvert('comment', (v) => v as String?),
        groups: $checkedConvert(
          'groups',
          (v) =>
              (v as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ??
              [0],
        ),
        enabled: $checkedConvert('enabled', (v) => v as bool? ?? true),
      );
      return val;
    });

Map<String, dynamic> _$Post4ToJson(Post4 instance) => <String, dynamic>{
  'address': ?instance.address?.toJson(),
  'comment': ?instance.comment,
  'groups': ?instance.groups,
  'enabled': ?instance.enabled,
};
