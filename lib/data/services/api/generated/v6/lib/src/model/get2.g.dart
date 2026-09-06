// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get2.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Get2CWProxy {
  Get2 groups(List<Get2GroupsInner>? groups);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Get2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Get2(...).copyWith(id: 12, name: "My name")
  /// ````
  Get2 call({List<Get2GroupsInner>? groups});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGet2.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGet2.copyWith.fieldName(...)`
class _$Get2CWProxyImpl implements _$Get2CWProxy {
  const _$Get2CWProxyImpl(this._value);

  final Get2 _value;

  @override
  Get2 groups(List<Get2GroupsInner>? groups) => this(groups: groups);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Get2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Get2(...).copyWith(id: 12, name: "My name")
  /// ````
  Get2 call({Object? groups = const $CopyWithPlaceholder()}) {
    return Get2(
      groups: groups == const $CopyWithPlaceholder()
          ? _value.groups
          // ignore: cast_nullable_to_non_nullable
          : groups as List<Get2GroupsInner>?,
    );
  }
}

extension $Get2CopyWith on Get2 {
  /// Returns a callable class that can be used as follows: `instanceOfGet2.copyWith(...)` or like so:`instanceOfGet2.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Get2CWProxy get copyWith => _$Get2CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Get2 _$Get2FromJson(Map<String, dynamic> json) =>
    $checkedCreate('Get2', json, ($checkedConvert) {
      final val = Get2(
        groups: $checkedConvert(
          'groups',
          (v) => (v as List<dynamic>?)
              ?.map((e) => Get2GroupsInner.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$Get2ToJson(Get2 instance) => <String, dynamic>{
  'groups': ?instance.groups?.map((e) => e.toJson()).toList(),
};
