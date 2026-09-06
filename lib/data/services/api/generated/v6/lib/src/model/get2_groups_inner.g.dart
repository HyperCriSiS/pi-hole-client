// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get2_groups_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Get2GroupsInnerCWProxy {
  Get2GroupsInner name(String? name);

  Get2GroupsInner comment(String? comment);

  Get2GroupsInner enabled(bool? enabled);

  Get2GroupsInner id(int? id);

  Get2GroupsInner dateAdded(int? dateAdded);

  Get2GroupsInner dateModified(int? dateModified);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Get2GroupsInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Get2GroupsInner(...).copyWith(id: 12, name: "My name")
  /// ````
  Get2GroupsInner call({
    String? name,
    String? comment,
    bool? enabled,
    int? id,
    int? dateAdded,
    int? dateModified,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGet2GroupsInner.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGet2GroupsInner.copyWith.fieldName(...)`
class _$Get2GroupsInnerCWProxyImpl implements _$Get2GroupsInnerCWProxy {
  const _$Get2GroupsInnerCWProxyImpl(this._value);

  final Get2GroupsInner _value;

  @override
  Get2GroupsInner name(String? name) => this(name: name);

  @override
  Get2GroupsInner comment(String? comment) => this(comment: comment);

  @override
  Get2GroupsInner enabled(bool? enabled) => this(enabled: enabled);

  @override
  Get2GroupsInner id(int? id) => this(id: id);

  @override
  Get2GroupsInner dateAdded(int? dateAdded) => this(dateAdded: dateAdded);

  @override
  Get2GroupsInner dateModified(int? dateModified) =>
      this(dateModified: dateModified);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Get2GroupsInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Get2GroupsInner(...).copyWith(id: 12, name: "My name")
  /// ````
  Get2GroupsInner call({
    Object? name = const $CopyWithPlaceholder(),
    Object? comment = const $CopyWithPlaceholder(),
    Object? enabled = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? dateAdded = const $CopyWithPlaceholder(),
    Object? dateModified = const $CopyWithPlaceholder(),
  }) {
    return Get2GroupsInner(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
      comment: comment == const $CopyWithPlaceholder()
          ? _value.comment
          // ignore: cast_nullable_to_non_nullable
          : comment as String?,
      enabled: enabled == const $CopyWithPlaceholder()
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool?,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as int?,
      dateAdded: dateAdded == const $CopyWithPlaceholder()
          ? _value.dateAdded
          // ignore: cast_nullable_to_non_nullable
          : dateAdded as int?,
      dateModified: dateModified == const $CopyWithPlaceholder()
          ? _value.dateModified
          // ignore: cast_nullable_to_non_nullable
          : dateModified as int?,
    );
  }
}

extension $Get2GroupsInnerCopyWith on Get2GroupsInner {
  /// Returns a callable class that can be used as follows: `instanceOfGet2GroupsInner.copyWith(...)` or like so:`instanceOfGet2GroupsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Get2GroupsInnerCWProxy get copyWith => _$Get2GroupsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Get2GroupsInner _$Get2GroupsInnerFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'Get2GroupsInner',
      json,
      ($checkedConvert) {
        final val = Get2GroupsInner(
          name: $checkedConvert('name', (v) => v as String?),
          comment: $checkedConvert('comment', (v) => v as String?),
          enabled: $checkedConvert('enabled', (v) => v as bool? ?? true),
          id: $checkedConvert('id', (v) => (v as num?)?.toInt()),
          dateAdded: $checkedConvert('date_added', (v) => (v as num?)?.toInt()),
          dateModified: $checkedConvert(
            'date_modified',
            (v) => (v as num?)?.toInt(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'dateAdded': 'date_added',
        'dateModified': 'date_modified',
      },
    );

Map<String, dynamic> _$Get2GroupsInnerToJson(Get2GroupsInner instance) =>
    <String, dynamic>{
      'name': ?instance.name,
      'comment': ?instance.comment,
      'enabled': ?instance.enabled,
      'id': ?instance.id,
      'date_added': ?instance.dateAdded,
      'date_modified': ?instance.dateModified,
    };
