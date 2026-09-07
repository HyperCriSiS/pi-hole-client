// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queries2_queries_inner_reply.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Queries2QueriesInnerReplyCWProxy {
  Queries2QueriesInnerReply type(String? type);

  Queries2QueriesInnerReply time(num? time);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Queries2QueriesInnerReply(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Queries2QueriesInnerReply(...).copyWith(id: 12, name: "My name")
  /// ````
  Queries2QueriesInnerReply call({String? type, num? time});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfQueries2QueriesInnerReply.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfQueries2QueriesInnerReply.copyWith.fieldName(...)`
class _$Queries2QueriesInnerReplyCWProxyImpl
    implements _$Queries2QueriesInnerReplyCWProxy {
  const _$Queries2QueriesInnerReplyCWProxyImpl(this._value);

  final Queries2QueriesInnerReply _value;

  @override
  Queries2QueriesInnerReply type(String? type) => this(type: type);

  @override
  Queries2QueriesInnerReply time(num? time) => this(time: time);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Queries2QueriesInnerReply(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Queries2QueriesInnerReply(...).copyWith(id: 12, name: "My name")
  /// ````
  Queries2QueriesInnerReply call({
    Object? type = const $CopyWithPlaceholder(),
    Object? time = const $CopyWithPlaceholder(),
  }) {
    return Queries2QueriesInnerReply(
      type: type == const $CopyWithPlaceholder()
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as String?,
      time: time == const $CopyWithPlaceholder()
          ? _value.time
          // ignore: cast_nullable_to_non_nullable
          : time as num?,
    );
  }
}

extension $Queries2QueriesInnerReplyCopyWith on Queries2QueriesInnerReply {
  /// Returns a callable class that can be used as follows: `instanceOfQueries2QueriesInnerReply.copyWith(...)` or like so:`instanceOfQueries2QueriesInnerReply.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Queries2QueriesInnerReplyCWProxy get copyWith =>
      _$Queries2QueriesInnerReplyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Queries2QueriesInnerReply _$Queries2QueriesInnerReplyFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('Queries2QueriesInnerReply', json, ($checkedConvert) {
  final val = Queries2QueriesInnerReply(
    type: $checkedConvert('type', (v) => v as String?),
    time: $checkedConvert('time', (v) => v as num?),
  );
  return val;
});

Map<String, dynamic> _$Queries2QueriesInnerReplyToJson(
  Queries2QueriesInnerReply instance,
) => <String, dynamic>{'type': ?instance.type, 'time': ?instance.time};
