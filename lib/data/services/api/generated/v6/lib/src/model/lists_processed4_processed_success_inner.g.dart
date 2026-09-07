// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lists_processed4_processed_success_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ListsProcessed4ProcessedSuccessInnerCWProxy {
  ListsProcessed4ProcessedSuccessInner item(String? item);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListsProcessed4ProcessedSuccessInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListsProcessed4ProcessedSuccessInner(...).copyWith(id: 12, name: "My name")
  /// ````
  ListsProcessed4ProcessedSuccessInner call({String? item});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfListsProcessed4ProcessedSuccessInner.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfListsProcessed4ProcessedSuccessInner.copyWith.fieldName(...)`
class _$ListsProcessed4ProcessedSuccessInnerCWProxyImpl
    implements _$ListsProcessed4ProcessedSuccessInnerCWProxy {
  const _$ListsProcessed4ProcessedSuccessInnerCWProxyImpl(this._value);

  final ListsProcessed4ProcessedSuccessInner _value;

  @override
  ListsProcessed4ProcessedSuccessInner item(String? item) => this(item: item);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListsProcessed4ProcessedSuccessInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListsProcessed4ProcessedSuccessInner(...).copyWith(id: 12, name: "My name")
  /// ````
  ListsProcessed4ProcessedSuccessInner call({
    Object? item = const $CopyWithPlaceholder(),
  }) {
    return ListsProcessed4ProcessedSuccessInner(
      item: item == const $CopyWithPlaceholder()
          ? _value.item
          // ignore: cast_nullable_to_non_nullable
          : item as String?,
    );
  }
}

extension $ListsProcessed4ProcessedSuccessInnerCopyWith
    on ListsProcessed4ProcessedSuccessInner {
  /// Returns a callable class that can be used as follows: `instanceOfListsProcessed4ProcessedSuccessInner.copyWith(...)` or like so:`instanceOfListsProcessed4ProcessedSuccessInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ListsProcessed4ProcessedSuccessInnerCWProxy get copyWith =>
      _$ListsProcessed4ProcessedSuccessInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListsProcessed4ProcessedSuccessInner
_$ListsProcessed4ProcessedSuccessInnerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ListsProcessed4ProcessedSuccessInner', json, (
      $checkedConvert,
    ) {
      final val = ListsProcessed4ProcessedSuccessInner(
        item: $checkedConvert('item', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ListsProcessed4ProcessedSuccessInnerToJson(
  ListsProcessed4ProcessedSuccessInner instance,
) => <String, dynamic>{'item': ?instance.item};
