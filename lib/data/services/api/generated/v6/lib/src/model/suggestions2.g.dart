// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggestions2.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Suggestions2CWProxy {
  Suggestions2 clients(List<Suggestions2ClientsInner>? clients);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Suggestions2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Suggestions2(...).copyWith(id: 12, name: "My name")
  /// ````
  Suggestions2 call({List<Suggestions2ClientsInner>? clients});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSuggestions2.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSuggestions2.copyWith.fieldName(...)`
class _$Suggestions2CWProxyImpl implements _$Suggestions2CWProxy {
  const _$Suggestions2CWProxyImpl(this._value);

  final Suggestions2 _value;

  @override
  Suggestions2 clients(List<Suggestions2ClientsInner>? clients) =>
      this(clients: clients);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Suggestions2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Suggestions2(...).copyWith(id: 12, name: "My name")
  /// ````
  Suggestions2 call({Object? clients = const $CopyWithPlaceholder()}) {
    return Suggestions2(
      clients: clients == const $CopyWithPlaceholder()
          ? _value.clients
          // ignore: cast_nullable_to_non_nullable
          : clients as List<Suggestions2ClientsInner>?,
    );
  }
}

extension $Suggestions2CopyWith on Suggestions2 {
  /// Returns a callable class that can be used as follows: `instanceOfSuggestions2.copyWith(...)` or like so:`instanceOfSuggestions2.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Suggestions2CWProxy get copyWith => _$Suggestions2CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Suggestions2 _$Suggestions2FromJson(Map<String, dynamic> json) =>
    $checkedCreate('Suggestions2', json, ($checkedConvert) {
      final val = Suggestions2(
        clients: $checkedConvert(
          'clients',
          (v) => (v as List<dynamic>?)
              ?.map(
                (e) => Suggestions2ClientsInner.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$Suggestions2ToJson(Suggestions2 instance) =>
    <String, dynamic>{
      'clients': ?instance.clients?.map((e) => e.toJson()).toList(),
    };
