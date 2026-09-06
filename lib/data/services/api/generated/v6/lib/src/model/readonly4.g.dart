// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'readonly4.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Readonly4CWProxy {
  Readonly4 id(int? id);

  Readonly4 dateAdded(int? dateAdded);

  Readonly4 dateModified(int? dateModified);

  Readonly4 dateUpdated(int? dateUpdated);

  Readonly4 number(int? number);

  Readonly4 invalidDomains(int? invalidDomains);

  Readonly4 abpEntries(int? abpEntries);

  Readonly4 status(int? status);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Readonly4(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Readonly4(...).copyWith(id: 12, name: "My name")
  /// ````
  Readonly4 call({
    int? id,
    int? dateAdded,
    int? dateModified,
    int? dateUpdated,
    int? number,
    int? invalidDomains,
    int? abpEntries,
    int? status,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfReadonly4.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfReadonly4.copyWith.fieldName(...)`
class _$Readonly4CWProxyImpl implements _$Readonly4CWProxy {
  const _$Readonly4CWProxyImpl(this._value);

  final Readonly4 _value;

  @override
  Readonly4 id(int? id) => this(id: id);

  @override
  Readonly4 dateAdded(int? dateAdded) => this(dateAdded: dateAdded);

  @override
  Readonly4 dateModified(int? dateModified) => this(dateModified: dateModified);

  @override
  Readonly4 dateUpdated(int? dateUpdated) => this(dateUpdated: dateUpdated);

  @override
  Readonly4 number(int? number) => this(number: number);

  @override
  Readonly4 invalidDomains(int? invalidDomains) =>
      this(invalidDomains: invalidDomains);

  @override
  Readonly4 abpEntries(int? abpEntries) => this(abpEntries: abpEntries);

  @override
  Readonly4 status(int? status) => this(status: status);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Readonly4(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Readonly4(...).copyWith(id: 12, name: "My name")
  /// ````
  Readonly4 call({
    Object? id = const $CopyWithPlaceholder(),
    Object? dateAdded = const $CopyWithPlaceholder(),
    Object? dateModified = const $CopyWithPlaceholder(),
    Object? dateUpdated = const $CopyWithPlaceholder(),
    Object? number = const $CopyWithPlaceholder(),
    Object? invalidDomains = const $CopyWithPlaceholder(),
    Object? abpEntries = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
  }) {
    return Readonly4(
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
      dateUpdated: dateUpdated == const $CopyWithPlaceholder()
          ? _value.dateUpdated
          // ignore: cast_nullable_to_non_nullable
          : dateUpdated as int?,
      number: number == const $CopyWithPlaceholder()
          ? _value.number
          // ignore: cast_nullable_to_non_nullable
          : number as int?,
      invalidDomains: invalidDomains == const $CopyWithPlaceholder()
          ? _value.invalidDomains
          // ignore: cast_nullable_to_non_nullable
          : invalidDomains as int?,
      abpEntries: abpEntries == const $CopyWithPlaceholder()
          ? _value.abpEntries
          // ignore: cast_nullable_to_non_nullable
          : abpEntries as int?,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as int?,
    );
  }
}

extension $Readonly4CopyWith on Readonly4 {
  /// Returns a callable class that can be used as follows: `instanceOfReadonly4.copyWith(...)` or like so:`instanceOfReadonly4.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Readonly4CWProxy get copyWith => _$Readonly4CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Readonly4 _$Readonly4FromJson(Map<String, dynamic> json) => $checkedCreate(
  'Readonly4',
  json,
  ($checkedConvert) {
    final val = Readonly4(
      id: $checkedConvert('id', (v) => (v as num?)?.toInt()),
      dateAdded: $checkedConvert('date_added', (v) => (v as num?)?.toInt()),
      dateModified: $checkedConvert(
        'date_modified',
        (v) => (v as num?)?.toInt(),
      ),
      dateUpdated: $checkedConvert('date_updated', (v) => (v as num?)?.toInt()),
      number: $checkedConvert('number', (v) => (v as num?)?.toInt()),
      invalidDomains: $checkedConvert(
        'invalid_domains',
        (v) => (v as num?)?.toInt(),
      ),
      abpEntries: $checkedConvert('abp_entries', (v) => (v as num?)?.toInt()),
      status: $checkedConvert('status', (v) => (v as num?)?.toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'dateAdded': 'date_added',
    'dateModified': 'date_modified',
    'dateUpdated': 'date_updated',
    'invalidDomains': 'invalid_domains',
    'abpEntries': 'abp_entries',
  },
);

Map<String, dynamic> _$Readonly4ToJson(Readonly4 instance) => <String, dynamic>{
  'id': ?instance.id,
  'date_added': ?instance.dateAdded,
  'date_modified': ?instance.dateModified,
  'date_updated': ?instance.dateUpdated,
  'number': ?instance.number,
  'invalid_domains': ?instance.invalidDomains,
  'abp_entries': ?instance.abpEntries,
  'status': ?instance.status,
};
