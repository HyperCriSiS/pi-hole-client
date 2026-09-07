// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'groups2.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Groups2CWProxy {
  Groups2 groups(List<int>? groups);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Groups2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Groups2(...).copyWith(id: 12, name: "My name")
  /// ````
  Groups2 call({List<int>? groups});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGroups2.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGroups2.copyWith.fieldName(...)`
class _$Groups2CWProxyImpl implements _$Groups2CWProxy {
  const _$Groups2CWProxyImpl(this._value);

  final Groups2 _value;

  @override
  Groups2 groups(List<int>? groups) => this(groups: groups);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Groups2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Groups2(...).copyWith(id: 12, name: "My name")
  /// ````
  Groups2 call({Object? groups = const $CopyWithPlaceholder()}) {
    return Groups2(
      groups: groups == const $CopyWithPlaceholder()
          ? _value.groups
          // ignore: cast_nullable_to_non_nullable
          : groups as List<int>?,
    );
  }
}

extension $Groups2CopyWith on Groups2 {
  /// Returns a callable class that can be used as follows: `instanceOfGroups2.copyWith(...)` or like so:`instanceOfGroups2.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Groups2CWProxy get copyWith => _$Groups2CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Groups2 _$Groups2FromJson(Map<String, dynamic> json) =>
    $checkedCreate('Groups2', json, ($checkedConvert) {
      final val = Groups2(
        groups: $checkedConvert(
          'groups',
          (v) =>
              (v as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ??
              [0],
        ),
      );
      return val;
    });

Map<String, dynamic> _$Groups2ToJson(Groups2 instance) => <String, dynamic>{
  'groups': ?instance.groups,
};
