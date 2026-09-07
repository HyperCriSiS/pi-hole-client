// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_queries200_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GetQueries200ResponseCWProxy {
  GetQueries200Response queries(List<Queries2QueriesInner>? queries);

  GetQueries200Response cursor(int? cursor);

  GetQueries200Response recordsTotal(int? recordsTotal);

  GetQueries200Response recordsFiltered(int? recordsFiltered);

  GetQueries200Response draw(int? draw);

  GetQueries200Response earliestTimestamp(num? earliestTimestamp);

  GetQueries200Response earliestTimestampDisk(num? earliestTimestampDisk);

  GetQueries200Response took(num? took);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GetQueries200Response(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GetQueries200Response(...).copyWith(id: 12, name: "My name")
  /// ````
  GetQueries200Response call({
    List<Queries2QueriesInner>? queries,
    int? cursor,
    int? recordsTotal,
    int? recordsFiltered,
    int? draw,
    num? earliestTimestamp,
    num? earliestTimestampDisk,
    num? took,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGetQueries200Response.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGetQueries200Response.copyWith.fieldName(...)`
class _$GetQueries200ResponseCWProxyImpl
    implements _$GetQueries200ResponseCWProxy {
  const _$GetQueries200ResponseCWProxyImpl(this._value);

  final GetQueries200Response _value;

  @override
  GetQueries200Response queries(List<Queries2QueriesInner>? queries) =>
      this(queries: queries);

  @override
  GetQueries200Response cursor(int? cursor) => this(cursor: cursor);

  @override
  GetQueries200Response recordsTotal(int? recordsTotal) =>
      this(recordsTotal: recordsTotal);

  @override
  GetQueries200Response recordsFiltered(int? recordsFiltered) =>
      this(recordsFiltered: recordsFiltered);

  @override
  GetQueries200Response draw(int? draw) => this(draw: draw);

  @override
  GetQueries200Response earliestTimestamp(num? earliestTimestamp) =>
      this(earliestTimestamp: earliestTimestamp);

  @override
  GetQueries200Response earliestTimestampDisk(num? earliestTimestampDisk) =>
      this(earliestTimestampDisk: earliestTimestampDisk);

  @override
  GetQueries200Response took(num? took) => this(took: took);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GetQueries200Response(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GetQueries200Response(...).copyWith(id: 12, name: "My name")
  /// ````
  GetQueries200Response call({
    Object? queries = const $CopyWithPlaceholder(),
    Object? cursor = const $CopyWithPlaceholder(),
    Object? recordsTotal = const $CopyWithPlaceholder(),
    Object? recordsFiltered = const $CopyWithPlaceholder(),
    Object? draw = const $CopyWithPlaceholder(),
    Object? earliestTimestamp = const $CopyWithPlaceholder(),
    Object? earliestTimestampDisk = const $CopyWithPlaceholder(),
    Object? took = const $CopyWithPlaceholder(),
  }) {
    return GetQueries200Response(
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
      took: took == const $CopyWithPlaceholder()
          ? _value.took
          // ignore: cast_nullable_to_non_nullable
          : took as num?,
    );
  }
}

extension $GetQueries200ResponseCopyWith on GetQueries200Response {
  /// Returns a callable class that can be used as follows: `instanceOfGetQueries200Response.copyWith(...)` or like so:`instanceOfGetQueries200Response.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GetQueries200ResponseCWProxy get copyWith =>
      _$GetQueries200ResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetQueries200Response _$GetQueries200ResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'GetQueries200Response',
  json,
  ($checkedConvert) {
    final val = GetQueries200Response(
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
      took: $checkedConvert('took', (v) => v as num?),
    );
    return val;
  },
  fieldKeyMap: const {
    'earliestTimestamp': 'earliest_timestamp',
    'earliestTimestampDisk': 'earliest_timestamp_disk',
  },
);

Map<String, dynamic> _$GetQueries200ResponseToJson(
  GetQueries200Response instance,
) => <String, dynamic>{
  'queries': ?instance.queries?.map((e) => e.toJson()).toList(),
  'cursor': ?instance.cursor,
  'recordsTotal': ?instance.recordsTotal,
  'recordsFiltered': ?instance.recordsFiltered,
  'draw': ?instance.draw,
  'earliest_timestamp': ?instance.earliestTimestamp,
  'earliest_timestamp_disk': ?instance.earliestTimestampDisk,
  'took': ?instance.took,
};
