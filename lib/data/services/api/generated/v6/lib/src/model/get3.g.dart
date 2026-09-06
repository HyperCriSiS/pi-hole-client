// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get3.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Get3CWProxy {
  Get3 clients(List<Get3ClientsInner>? clients);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Get3(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Get3(...).copyWith(id: 12, name: "My name")
  /// ````
  Get3 call({List<Get3ClientsInner>? clients});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGet3.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGet3.copyWith.fieldName(...)`
class _$Get3CWProxyImpl implements _$Get3CWProxy {
  const _$Get3CWProxyImpl(this._value);

  final Get3 _value;

  @override
  Get3 clients(List<Get3ClientsInner>? clients) => this(clients: clients);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Get3(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Get3(...).copyWith(id: 12, name: "My name")
  /// ````
  Get3 call({Object? clients = const $CopyWithPlaceholder()}) {
    return Get3(
      clients: clients == const $CopyWithPlaceholder()
          ? _value.clients
          // ignore: cast_nullable_to_non_nullable
          : clients as List<Get3ClientsInner>?,
    );
  }
}

extension $Get3CopyWith on Get3 {
  /// Returns a callable class that can be used as follows: `instanceOfGet3.copyWith(...)` or like so:`instanceOfGet3.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Get3CWProxy get copyWith => _$Get3CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Get3 _$Get3FromJson(Map<String, dynamic> json) =>
    $checkedCreate('Get3', json, ($checkedConvert) {
      final val = Get3(
        clients: $checkedConvert(
          'clients',
          (v) => (v as List<dynamic>?)
              ?.map((e) => Get3ClientsInner.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$Get3ToJson(Get3 instance) => <String, dynamic>{
  'clients': ?instance.clients?.map((e) => e.toJson()).toList(),
};
