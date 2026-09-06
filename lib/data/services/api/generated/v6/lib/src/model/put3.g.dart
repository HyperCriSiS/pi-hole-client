// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'put3.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Put3CWProxy {
  Put3 comment(String? comment);

  Put3 groups(List<int>? groups);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Put3(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Put3(...).copyWith(id: 12, name: "My name")
  /// ````
  Put3 call({String? comment, List<int>? groups});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPut3.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPut3.copyWith.fieldName(...)`
class _$Put3CWProxyImpl implements _$Put3CWProxy {
  const _$Put3CWProxyImpl(this._value);

  final Put3 _value;

  @override
  Put3 comment(String? comment) => this(comment: comment);

  @override
  Put3 groups(List<int>? groups) => this(groups: groups);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Put3(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Put3(...).copyWith(id: 12, name: "My name")
  /// ````
  Put3 call({
    Object? comment = const $CopyWithPlaceholder(),
    Object? groups = const $CopyWithPlaceholder(),
  }) {
    return Put3(
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

extension $Put3CopyWith on Put3 {
  /// Returns a callable class that can be used as follows: `instanceOfPut3.copyWith(...)` or like so:`instanceOfPut3.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Put3CWProxy get copyWith => _$Put3CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Put3 _$Put3FromJson(Map<String, dynamic> json) => $checkedCreate('Put3', json, (
  $checkedConvert,
) {
  final val = Put3(
    comment: $checkedConvert('comment', (v) => v as String?),
    groups: $checkedConvert(
      'groups',
      (v) =>
          (v as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [0],
    ),
  );
  return val;
});

Map<String, dynamic> _$Put3ToJson(Put3 instance) => <String, dynamic>{
  'comment': ?instance.comment,
  'groups': ?instance.groups,
};
