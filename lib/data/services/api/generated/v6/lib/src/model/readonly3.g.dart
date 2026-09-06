// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'readonly3.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Readonly3CWProxy {
  Readonly3 id(int? id);

  Readonly3 dateAdded(int? dateAdded);

  Readonly3 dateModified(int? dateModified);

  Readonly3 name(String? name);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Readonly3(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Readonly3(...).copyWith(id: 12, name: "My name")
  /// ````
  Readonly3 call({int? id, int? dateAdded, int? dateModified, String? name});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfReadonly3.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfReadonly3.copyWith.fieldName(...)`
class _$Readonly3CWProxyImpl implements _$Readonly3CWProxy {
  const _$Readonly3CWProxyImpl(this._value);

  final Readonly3 _value;

  @override
  Readonly3 id(int? id) => this(id: id);

  @override
  Readonly3 dateAdded(int? dateAdded) => this(dateAdded: dateAdded);

  @override
  Readonly3 dateModified(int? dateModified) => this(dateModified: dateModified);

  @override
  Readonly3 name(String? name) => this(name: name);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Readonly3(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Readonly3(...).copyWith(id: 12, name: "My name")
  /// ````
  Readonly3 call({
    Object? id = const $CopyWithPlaceholder(),
    Object? dateAdded = const $CopyWithPlaceholder(),
    Object? dateModified = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return Readonly3(
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

extension $Readonly3CopyWith on Readonly3 {
  /// Returns a callable class that can be used as follows: `instanceOfReadonly3.copyWith(...)` or like so:`instanceOfReadonly3.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Readonly3CWProxy get copyWith => _$Readonly3CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Readonly3 _$Readonly3FromJson(Map<String, dynamic> json) => $checkedCreate(
  'Readonly3',
  json,
  ($checkedConvert) {
    final val = Readonly3(
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

Map<String, dynamic> _$Readonly3ToJson(Readonly3 instance) => <String, dynamic>{
  'id': ?instance.id,
  'date_added': ?instance.dateAdded,
  'date_modified': ?instance.dateModified,
  'name': ?instance.name,
};
