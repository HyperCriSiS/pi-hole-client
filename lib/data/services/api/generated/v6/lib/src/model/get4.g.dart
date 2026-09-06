// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get4.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Get4CWProxy {
  Get4 lists(List<Get4ListsInner>? lists);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Get4(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Get4(...).copyWith(id: 12, name: "My name")
  /// ````
  Get4 call({List<Get4ListsInner>? lists});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGet4.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGet4.copyWith.fieldName(...)`
class _$Get4CWProxyImpl implements _$Get4CWProxy {
  const _$Get4CWProxyImpl(this._value);

  final Get4 _value;

  @override
  Get4 lists(List<Get4ListsInner>? lists) => this(lists: lists);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Get4(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Get4(...).copyWith(id: 12, name: "My name")
  /// ````
  Get4 call({Object? lists = const $CopyWithPlaceholder()}) {
    return Get4(
      lists: lists == const $CopyWithPlaceholder()
          ? _value.lists
          // ignore: cast_nullable_to_non_nullable
          : lists as List<Get4ListsInner>?,
    );
  }
}

extension $Get4CopyWith on Get4 {
  /// Returns a callable class that can be used as follows: `instanceOfGet4.copyWith(...)` or like so:`instanceOfGet4.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Get4CWProxy get copyWith => _$Get4CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Get4 _$Get4FromJson(Map<String, dynamic> json) =>
    $checkedCreate('Get4', json, ($checkedConvert) {
      final val = Get4(
        lists: $checkedConvert(
          'lists',
          (v) => (v as List<dynamic>?)
              ?.map((e) => Get4ListsInner.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$Get4ToJson(Get4 instance) => <String, dynamic>{
  'lists': ?instance.lists?.map((e) => e.toJson()).toList(),
};
