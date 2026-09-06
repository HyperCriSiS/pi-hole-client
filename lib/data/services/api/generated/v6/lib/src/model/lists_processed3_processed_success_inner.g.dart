// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lists_processed3_processed_success_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ListsProcessed3ProcessedSuccessInnerCWProxy {
  ListsProcessed3ProcessedSuccessInner item(String? item);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListsProcessed3ProcessedSuccessInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListsProcessed3ProcessedSuccessInner(...).copyWith(id: 12, name: "My name")
  /// ````
  ListsProcessed3ProcessedSuccessInner call({String? item});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfListsProcessed3ProcessedSuccessInner.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfListsProcessed3ProcessedSuccessInner.copyWith.fieldName(...)`
class _$ListsProcessed3ProcessedSuccessInnerCWProxyImpl
    implements _$ListsProcessed3ProcessedSuccessInnerCWProxy {
  const _$ListsProcessed3ProcessedSuccessInnerCWProxyImpl(this._value);

  final ListsProcessed3ProcessedSuccessInner _value;

  @override
  ListsProcessed3ProcessedSuccessInner item(String? item) => this(item: item);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListsProcessed3ProcessedSuccessInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListsProcessed3ProcessedSuccessInner(...).copyWith(id: 12, name: "My name")
  /// ````
  ListsProcessed3ProcessedSuccessInner call({
    Object? item = const $CopyWithPlaceholder(),
  }) {
    return ListsProcessed3ProcessedSuccessInner(
      item: item == const $CopyWithPlaceholder()
          ? _value.item
          // ignore: cast_nullable_to_non_nullable
          : item as String?,
    );
  }
}

extension $ListsProcessed3ProcessedSuccessInnerCopyWith
    on ListsProcessed3ProcessedSuccessInner {
  /// Returns a callable class that can be used as follows: `instanceOfListsProcessed3ProcessedSuccessInner.copyWith(...)` or like so:`instanceOfListsProcessed3ProcessedSuccessInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ListsProcessed3ProcessedSuccessInnerCWProxy get copyWith =>
      _$ListsProcessed3ProcessedSuccessInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListsProcessed3ProcessedSuccessInner
_$ListsProcessed3ProcessedSuccessInnerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ListsProcessed3ProcessedSuccessInner', json, (
      $checkedConvert,
    ) {
      final val = ListsProcessed3ProcessedSuccessInner(
        item: $checkedConvert('item', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ListsProcessed3ProcessedSuccessInnerToJson(
  ListsProcessed3ProcessedSuccessInner instance,
) => <String, dynamic>{'item': ?instance.item};
