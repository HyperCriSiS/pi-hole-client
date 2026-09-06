//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pihole_v6_api/src/model/queries2_queries_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'queries2.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Queries2 {
  /// Returns a new [Queries2] instance.
  Queries2({
    this.queries,

    this.cursor,

    this.recordsTotal,

    this.recordsFiltered,

    this.draw,

    this.earliestTimestamp,

    this.earliestTimestampDisk,
  });

  /// Data array
  @JsonKey(name: r'queries', required: false, includeIfNull: false)
  final List<Queries2QueriesInner>? queries;

  /// Database ID of most recent query to show
  @JsonKey(name: r'cursor', required: false, includeIfNull: false)
  final int? cursor;

  /// Total number of available queries
  @JsonKey(name: r'recordsTotal', required: false, includeIfNull: false)
  final int? recordsTotal;

  /// Number of available queries after filtering
  @JsonKey(name: r'recordsFiltered', required: false, includeIfNull: false)
  final int? recordsFiltered;

  /// DataTables-specific integer (echos input value)
  @JsonKey(name: r'draw', required: false, includeIfNull: false)
  final int? draw;

  /// Earliest timestamp of queries in in-memory database (Unix time)
  @JsonKey(name: r'earliest_timestamp', required: false, includeIfNull: false)
  final num? earliestTimestamp;

  /// Earliest timestamp of queries in on-disk database (Unix time)
  @JsonKey(
    name: r'earliest_timestamp_disk',
    required: false,
    includeIfNull: false,
  )
  final num? earliestTimestampDisk;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Queries2 &&
          other.queries == queries &&
          other.cursor == cursor &&
          other.recordsTotal == recordsTotal &&
          other.recordsFiltered == recordsFiltered &&
          other.draw == draw &&
          other.earliestTimestamp == earliestTimestamp &&
          other.earliestTimestampDisk == earliestTimestampDisk;

  @override
  int get hashCode =>
      queries.hashCode +
      cursor.hashCode +
      recordsTotal.hashCode +
      recordsFiltered.hashCode +
      draw.hashCode +
      earliestTimestamp.hashCode +
      earliestTimestampDisk.hashCode;

  factory Queries2.fromJson(Map<String, dynamic> json) =>
      _$Queries2FromJson(json);

  Map<String, dynamic> toJson() => _$Queries2ToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
