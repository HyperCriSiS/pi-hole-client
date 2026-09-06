// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queries2_queries_inner_client.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Queries2QueriesInnerClientCWProxy {
  Queries2QueriesInnerClient ip(String? ip);

  Queries2QueriesInnerClient name(String? name);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Queries2QueriesInnerClient(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Queries2QueriesInnerClient(...).copyWith(id: 12, name: "My name")
  /// ````
  Queries2QueriesInnerClient call({String? ip, String? name});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfQueries2QueriesInnerClient.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfQueries2QueriesInnerClient.copyWith.fieldName(...)`
class _$Queries2QueriesInnerClientCWProxyImpl
    implements _$Queries2QueriesInnerClientCWProxy {
  const _$Queries2QueriesInnerClientCWProxyImpl(this._value);

  final Queries2QueriesInnerClient _value;

  @override
  Queries2QueriesInnerClient ip(String? ip) => this(ip: ip);

  @override
  Queries2QueriesInnerClient name(String? name) => this(name: name);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Queries2QueriesInnerClient(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Queries2QueriesInnerClient(...).copyWith(id: 12, name: "My name")
  /// ````
  Queries2QueriesInnerClient call({
    Object? ip = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return Queries2QueriesInnerClient(
      ip: ip == const $CopyWithPlaceholder()
          ? _value.ip
          // ignore: cast_nullable_to_non_nullable
          : ip as String?,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
    );
  }
}

extension $Queries2QueriesInnerClientCopyWith on Queries2QueriesInnerClient {
  /// Returns a callable class that can be used as follows: `instanceOfQueries2QueriesInnerClient.copyWith(...)` or like so:`instanceOfQueries2QueriesInnerClient.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Queries2QueriesInnerClientCWProxy get copyWith =>
      _$Queries2QueriesInnerClientCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Queries2QueriesInnerClient _$Queries2QueriesInnerClientFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('Queries2QueriesInnerClient', json, ($checkedConvert) {
  final val = Queries2QueriesInnerClient(
    ip: $checkedConvert('ip', (v) => v as String?),
    name: $checkedConvert('name', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$Queries2QueriesInnerClientToJson(
  Queries2QueriesInnerClient instance,
) => <String, dynamic>{'ip': ?instance.ip, 'name': ?instance.name};
