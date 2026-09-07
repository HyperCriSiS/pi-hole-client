// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'readonly2.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Readonly2CWProxy {
  Readonly2 id(int? id);

  Readonly2 dateAdded(int? dateAdded);

  Readonly2 dateModified(int? dateModified);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Readonly2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Readonly2(...).copyWith(id: 12, name: "My name")
  /// ````
  Readonly2 call({int? id, int? dateAdded, int? dateModified});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfReadonly2.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfReadonly2.copyWith.fieldName(...)`
class _$Readonly2CWProxyImpl implements _$Readonly2CWProxy {
  const _$Readonly2CWProxyImpl(this._value);

  final Readonly2 _value;

  @override
  Readonly2 id(int? id) => this(id: id);

  @override
  Readonly2 dateAdded(int? dateAdded) => this(dateAdded: dateAdded);

  @override
  Readonly2 dateModified(int? dateModified) => this(dateModified: dateModified);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Readonly2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Readonly2(...).copyWith(id: 12, name: "My name")
  /// ````
  Readonly2 call({
    Object? id = const $CopyWithPlaceholder(),
    Object? dateAdded = const $CopyWithPlaceholder(),
    Object? dateModified = const $CopyWithPlaceholder(),
  }) {
    return Readonly2(
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

extension $Readonly2CopyWith on Readonly2 {
  /// Returns a callable class that can be used as follows: `instanceOfReadonly2.copyWith(...)` or like so:`instanceOfReadonly2.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Readonly2CWProxy get copyWith => _$Readonly2CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Readonly2 _$Readonly2FromJson(Map<String, dynamic> json) => $checkedCreate(
  'Readonly2',
  json,
  ($checkedConvert) {
    final val = Readonly2(
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

Map<String, dynamic> _$Readonly2ToJson(Readonly2 instance) => <String, dynamic>{
  'id': ?instance.id,
  'date_added': ?instance.dateAdded,
  'date_modified': ?instance.dateModified,
};
