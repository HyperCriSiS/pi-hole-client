// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'put4.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Put4CWProxy {
  Put4 comment(String? comment);

  Put4 type(Put4TypeEnum? type);

  Put4 groups(List<int>? groups);

  Put4 enabled(bool? enabled);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Put4(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Put4(...).copyWith(id: 12, name: "My name")
  /// ````
  Put4 call({
    String? comment,
    Put4TypeEnum? type,
    List<int>? groups,
    bool? enabled,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPut4.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPut4.copyWith.fieldName(...)`
class _$Put4CWProxyImpl implements _$Put4CWProxy {
  const _$Put4CWProxyImpl(this._value);

  final Put4 _value;

  @override
  Put4 comment(String? comment) => this(comment: comment);

  @override
  Put4 type(Put4TypeEnum? type) => this(type: type);

  @override
  Put4 groups(List<int>? groups) => this(groups: groups);

  @override
  Put4 enabled(bool? enabled) => this(enabled: enabled);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Put4(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Put4(...).copyWith(id: 12, name: "My name")
  /// ````
  Put4 call({
    Object? comment = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? groups = const $CopyWithPlaceholder(),
    Object? enabled = const $CopyWithPlaceholder(),
  }) {
    return Put4(
      comment: comment == const $CopyWithPlaceholder()
          ? _value.comment
          // ignore: cast_nullable_to_non_nullable
          : comment as String?,
      type: type == const $CopyWithPlaceholder()
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as Put4TypeEnum?,
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

extension $Put4CopyWith on Put4 {
  /// Returns a callable class that can be used as follows: `instanceOfPut4.copyWith(...)` or like so:`instanceOfPut4.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Put4CWProxy get copyWith => _$Put4CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Put4 _$Put4FromJson(Map<String, dynamic> json) => $checkedCreate('Put4', json, (
  $checkedConvert,
) {
  final val = Put4(
    comment: $checkedConvert('comment', (v) => v as String?),
    type: $checkedConvert(
      'type',
      (v) => $enumDecodeNullable(_$Put4TypeEnumEnumMap, v),
    ),
    groups: $checkedConvert(
      'groups',
      (v) =>
          (v as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [0],
    ),
    enabled: $checkedConvert('enabled', (v) => v as bool? ?? true),
  );
  return val;
});

Map<String, dynamic> _$Put4ToJson(Put4 instance) => <String, dynamic>{
  'comment': ?instance.comment,
  'type': ?_$Put4TypeEnumEnumMap[instance.type],
  'groups': ?instance.groups,
  'enabled': ?instance.enabled,
};

const _$Put4TypeEnumEnumMap = {
  Put4TypeEnum.allow: 'allow',
  Put4TypeEnum.block: 'block',
};
