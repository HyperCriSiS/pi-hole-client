// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get3_clients_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Get3ClientsInnerCWProxy {
  Get3ClientsInner client(String? client);

  Get3ClientsInner comment(String? comment);

  Get3ClientsInner groups(List<int>? groups);

  Get3ClientsInner id(int? id);

  Get3ClientsInner dateAdded(int? dateAdded);

  Get3ClientsInner dateModified(int? dateModified);

  Get3ClientsInner name(String? name);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Get3ClientsInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Get3ClientsInner(...).copyWith(id: 12, name: "My name")
  /// ````
  Get3ClientsInner call({
    String? client,
    String? comment,
    List<int>? groups,
    int? id,
    int? dateAdded,
    int? dateModified,
    String? name,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGet3ClientsInner.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGet3ClientsInner.copyWith.fieldName(...)`
class _$Get3ClientsInnerCWProxyImpl implements _$Get3ClientsInnerCWProxy {
  const _$Get3ClientsInnerCWProxyImpl(this._value);

  final Get3ClientsInner _value;

  @override
  Get3ClientsInner client(String? client) => this(client: client);

  @override
  Get3ClientsInner comment(String? comment) => this(comment: comment);

  @override
  Get3ClientsInner groups(List<int>? groups) => this(groups: groups);

  @override
  Get3ClientsInner id(int? id) => this(id: id);

  @override
  Get3ClientsInner dateAdded(int? dateAdded) => this(dateAdded: dateAdded);

  @override
  Get3ClientsInner dateModified(int? dateModified) =>
      this(dateModified: dateModified);

  @override
  Get3ClientsInner name(String? name) => this(name: name);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Get3ClientsInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Get3ClientsInner(...).copyWith(id: 12, name: "My name")
  /// ````
  Get3ClientsInner call({
    Object? client = const $CopyWithPlaceholder(),
    Object? comment = const $CopyWithPlaceholder(),
    Object? groups = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? dateAdded = const $CopyWithPlaceholder(),
    Object? dateModified = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return Get3ClientsInner(
      client: client == const $CopyWithPlaceholder()
          ? _value.client
          // ignore: cast_nullable_to_non_nullable
          : client as String?,
      comment: comment == const $CopyWithPlaceholder()
          ? _value.comment
          // ignore: cast_nullable_to_non_nullable
          : comment as String?,
      groups: groups == const $CopyWithPlaceholder()
          ? _value.groups
          // ignore: cast_nullable_to_non_nullable
          : groups as List<int>?,
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
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
    );
  }
}

extension $Get3ClientsInnerCopyWith on Get3ClientsInner {
  /// Returns a callable class that can be used as follows: `instanceOfGet3ClientsInner.copyWith(...)` or like so:`instanceOfGet3ClientsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Get3ClientsInnerCWProxy get copyWith => _$Get3ClientsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Get3ClientsInner _$Get3ClientsInnerFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'Get3ClientsInner',
      json,
      ($checkedConvert) {
        final val = Get3ClientsInner(
          client: $checkedConvert('client', (v) => v as String?),
          comment: $checkedConvert('comment', (v) => v as String?),
          groups: $checkedConvert(
            'groups',
            (v) =>
                (v as List<dynamic>?)
                    ?.map((e) => (e as num).toInt())
                    .toList() ??
                [0],
          ),
          id: $checkedConvert('id', (v) => (v as num?)?.toInt()),
          dateAdded: $checkedConvert('date_added', (v) => (v as num?)?.toInt()),
          dateModified: $checkedConvert(
            'date_modified',
            (v) => (v as num?)?.toInt(),
          ),
          name: $checkedConvert('name', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'dateAdded': 'date_added',
        'dateModified': 'date_modified',
      },
    );

Map<String, dynamic> _$Get3ClientsInnerToJson(Get3ClientsInner instance) =>
    <String, dynamic>{
      'client': ?instance.client,
      'comment': ?instance.comment,
      'groups': ?instance.groups,
      'id': ?instance.id,
      'date_added': ?instance.dateAdded,
      'date_modified': ?instance.dateModified,
      'name': ?instance.name,
    };
