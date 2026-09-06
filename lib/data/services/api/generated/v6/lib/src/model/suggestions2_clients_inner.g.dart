// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggestions2_clients_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Suggestions2ClientsInnerCWProxy {
  Suggestions2ClientsInner hwaddr(String? hwaddr);

  Suggestions2ClientsInner macVendor(String? macVendor);

  Suggestions2ClientsInner lastQuery(int? lastQuery);

  Suggestions2ClientsInner addresses(String? addresses);

  Suggestions2ClientsInner names(String? names);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Suggestions2ClientsInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Suggestions2ClientsInner(...).copyWith(id: 12, name: "My name")
  /// ````
  Suggestions2ClientsInner call({
    String? hwaddr,
    String? macVendor,
    int? lastQuery,
    String? addresses,
    String? names,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSuggestions2ClientsInner.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSuggestions2ClientsInner.copyWith.fieldName(...)`
class _$Suggestions2ClientsInnerCWProxyImpl
    implements _$Suggestions2ClientsInnerCWProxy {
  const _$Suggestions2ClientsInnerCWProxyImpl(this._value);

  final Suggestions2ClientsInner _value;

  @override
  Suggestions2ClientsInner hwaddr(String? hwaddr) => this(hwaddr: hwaddr);

  @override
  Suggestions2ClientsInner macVendor(String? macVendor) =>
      this(macVendor: macVendor);

  @override
  Suggestions2ClientsInner lastQuery(int? lastQuery) =>
      this(lastQuery: lastQuery);

  @override
  Suggestions2ClientsInner addresses(String? addresses) =>
      this(addresses: addresses);

  @override
  Suggestions2ClientsInner names(String? names) => this(names: names);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Suggestions2ClientsInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Suggestions2ClientsInner(...).copyWith(id: 12, name: "My name")
  /// ````
  Suggestions2ClientsInner call({
    Object? hwaddr = const $CopyWithPlaceholder(),
    Object? macVendor = const $CopyWithPlaceholder(),
    Object? lastQuery = const $CopyWithPlaceholder(),
    Object? addresses = const $CopyWithPlaceholder(),
    Object? names = const $CopyWithPlaceholder(),
  }) {
    return Suggestions2ClientsInner(
      hwaddr: hwaddr == const $CopyWithPlaceholder()
          ? _value.hwaddr
          // ignore: cast_nullable_to_non_nullable
          : hwaddr as String?,
      macVendor: macVendor == const $CopyWithPlaceholder()
          ? _value.macVendor
          // ignore: cast_nullable_to_non_nullable
          : macVendor as String?,
      lastQuery: lastQuery == const $CopyWithPlaceholder()
          ? _value.lastQuery
          // ignore: cast_nullable_to_non_nullable
          : lastQuery as int?,
      addresses: addresses == const $CopyWithPlaceholder()
          ? _value.addresses
          // ignore: cast_nullable_to_non_nullable
          : addresses as String?,
      names: names == const $CopyWithPlaceholder()
          ? _value.names
          // ignore: cast_nullable_to_non_nullable
          : names as String?,
    );
  }
}

extension $Suggestions2ClientsInnerCopyWith on Suggestions2ClientsInner {
  /// Returns a callable class that can be used as follows: `instanceOfSuggestions2ClientsInner.copyWith(...)` or like so:`instanceOfSuggestions2ClientsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Suggestions2ClientsInnerCWProxy get copyWith =>
      _$Suggestions2ClientsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Suggestions2ClientsInner _$Suggestions2ClientsInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('Suggestions2ClientsInner', json, ($checkedConvert) {
  final val = Suggestions2ClientsInner(
    hwaddr: $checkedConvert('hwaddr', (v) => v as String?),
    macVendor: $checkedConvert('macVendor', (v) => v as String?),
    lastQuery: $checkedConvert('lastQuery', (v) => (v as num?)?.toInt()),
    addresses: $checkedConvert('addresses', (v) => v as String?),
    names: $checkedConvert('names', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$Suggestions2ClientsInnerToJson(
  Suggestions2ClientsInner instance,
) => <String, dynamic>{
  'hwaddr': ?instance.hwaddr,
  'macVendor': ?instance.macVendor,
  'lastQuery': ?instance.lastQuery,
  'addresses': ?instance.addresses,
  'names': ?instance.names,
};
