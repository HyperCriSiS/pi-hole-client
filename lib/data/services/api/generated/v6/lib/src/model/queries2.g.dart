// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queries2.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Queries2CWProxy {
  Queries2 queries(List<Queries2QueriesInner>? queries);

  Queries2 cursor(int? cursor);

  Queries2 recordsTotal(int? recordsTotal);

  Queries2 recordsFiltered(int? recordsFiltered);

  Queries2 draw(int? draw);

  Queries2 earliestTimestamp(num? earliestTimestamp);

  Queries2 earliestTimestampDisk(num? earliestTimestampDisk);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Queries2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Queries2(...).copyWith(id: 12, name: "My name")
  /// ````
  Queries2 call({
    List<Queries2QueriesInner>? queries,
    int? cursor,
    int? recordsTotal,
    int? recordsFiltered,
    int? draw,
    num? earliestTimestamp,
    num? earliestTimestampDisk,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfQueries2.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfQueries2.copyWith.fieldName(...)`
class _$Queries2CWProxyImpl implements _$Queries2CWProxy {
  const _$Queries2CWProxyImpl(this._value);

  final Queries2 _value;

  @override
  Queries2 queries(List<Queries2QueriesInner>? queries) =>
      this(queries: queries);

  @override
  Queries2 cursor(int? cursor) => this(cursor: cursor);

  @override
  Queries2 recordsTotal(int? recordsTotal) => this(recordsTotal: recordsTotal);

  @override
  Queries2 recordsFiltered(int? recordsFiltered) =>
      this(recordsFiltered: recordsFiltered);

  @override
  Queries2 draw(int? draw) => this(draw: draw);

  @override
  Queries2 earliestTimestamp(num? earliestTimestamp) =>
      this(earliestTimestamp: earliestTimestamp);

  @override
  Queries2 earliestTimestampDisk(num? earliestTimestampDisk) =>
      this(earliestTimestampDisk: earliestTimestampDisk);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Queries2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Queries2(...).copyWith(id: 12, name: "My name")
  /// ````
  Queries2 call({
    Object? queries = const $CopyWithPlaceholder(),
    Object? cursor = const $CopyWithPlaceholder(),
    Object? recordsTotal = const $CopyWithPlaceholder(),
    Object? recordsFiltered = const $CopyWithPlaceholder(),
    Object? draw = const $CopyWithPlaceholder(),
    Object? earliestTimestamp = const $CopyWithPlaceholder(),
    Object? earliestTimestampDisk = const $CopyWithPlaceholder(),
  }) {
    return Queries2(
      queries: queries == const $CopyWithPlaceholder()
          ? _value.queries
          // ignore: cast_nullable_to_non_nullable
          : queries as List<Queries2QueriesInner>?,
      cursor: cursor == const $CopyWithPlaceholder()
          ? _value.cursor
          // ignore: cast_nullable_to_non_nullable
          : cursor as int?,
      recordsTotal: recordsTotal == const $CopyWithPlaceholder()
          ? _value.recordsTotal
          // ignore: cast_nullable_to_non_nullable
          : recordsTotal as int?,
      recordsFiltered: recordsFiltered == const $CopyWithPlaceholder()
          ? _value.recordsFiltered
          // ignore: cast_nullable_to_non_nullable
          : recordsFiltered as int?,
      draw: draw == const $CopyWithPlaceholder()
          ? _value.draw
          // ignore: cast_nullable_to_non_nullable
          : draw as int?,
      earliestTimestamp: earliestTimestamp == const $CopyWithPlaceholder()
          ? _value.earliestTimestamp
          // ignore: cast_nullable_to_non_nullable
          : earliestTimestamp as num?,
      earliestTimestampDisk:
          earliestTimestampDisk == const $CopyWithPlaceholder()
          ? _value.earliestTimestampDisk
          // ignore: cast_nullable_to_non_nullable
          : earliestTimestampDisk as num?,
    );
  }
}

extension $Queries2CopyWith on Queries2 {
  /// Returns a callable class that can be used as follows: `instanceOfQueries2.copyWith(...)` or like so:`instanceOfQueries2.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Queries2CWProxy get copyWith => _$Queries2CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Queries2 _$Queries2FromJson(Map<String, dynamic> json) => $checkedCreate(
  'Queries2',
  json,
  ($checkedConvert) {
    final val = Queries2(
      queries: $checkedConvert(
        'queries',
        (v) => (v as List<dynamic>?)
            ?.map(
              (e) => Queries2QueriesInner.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      cursor: $checkedConvert('cursor', (v) => (v as num?)?.toInt()),
      recordsTotal: $checkedConvert(
        'recordsTotal',
        (v) => (v as num?)?.toInt(),
      ),
      recordsFiltered: $checkedConvert(
        'recordsFiltered',
        (v) => (v as num?)?.toInt(),
      ),
      draw: $checkedConvert('draw', (v) => (v as num?)?.toInt()),
      earliestTimestamp: $checkedConvert(
        'earliest_timestamp',
        (v) => v as num?,
      ),
      earliestTimestampDisk: $checkedConvert(
        'earliest_timestamp_disk',
        (v) => v as num?,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'earliestTimestamp': 'earliest_timestamp',
    'earliestTimestampDisk': 'earliest_timestamp_disk',
  },
);

Map<String, dynamic> _$Queries2ToJson(Queries2 instance) => <String, dynamic>{
  'queries': ?instance.queries?.map((e) => e.toJson()).toList(),
  'cursor': ?instance.cursor,
  'recordsTotal': ?instance.recordsTotal,
  'recordsFiltered': ?instance.recordsFiltered,
  'draw': ?instance.draw,
  'earliest_timestamp': ?instance.earliestTimestamp,
  'earliest_timestamp_disk': ?instance.earliestTimestampDisk,
};
