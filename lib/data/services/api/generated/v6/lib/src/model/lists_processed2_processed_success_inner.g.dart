// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lists_processed2_processed_success_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ListsProcessed2ProcessedSuccessInnerCWProxy {
  ListsProcessed2ProcessedSuccessInner item(String? item);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListsProcessed2ProcessedSuccessInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListsProcessed2ProcessedSuccessInner(...).copyWith(id: 12, name: "My name")
  /// ````
  ListsProcessed2ProcessedSuccessInner call({String? item});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfListsProcessed2ProcessedSuccessInner.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfListsProcessed2ProcessedSuccessInner.copyWith.fieldName(...)`
class _$ListsProcessed2ProcessedSuccessInnerCWProxyImpl
    implements _$ListsProcessed2ProcessedSuccessInnerCWProxy {
  const _$ListsProcessed2ProcessedSuccessInnerCWProxyImpl(this._value);

  final ListsProcessed2ProcessedSuccessInner _value;

  @override
  ListsProcessed2ProcessedSuccessInner item(String? item) => this(item: item);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListsProcessed2ProcessedSuccessInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListsProcessed2ProcessedSuccessInner(...).copyWith(id: 12, name: "My name")
  /// ````
  ListsProcessed2ProcessedSuccessInner call({
    Object? item = const $CopyWithPlaceholder(),
  }) {
    return ListsProcessed2ProcessedSuccessInner(
      item: item == const $CopyWithPlaceholder()
          ? _value.item
          // ignore: cast_nullable_to_non_nullable
          : item as String?,
    );
  }
}

extension $ListsProcessed2ProcessedSuccessInnerCopyWith
    on ListsProcessed2ProcessedSuccessInner {
  /// Returns a callable class that can be used as follows: `instanceOfListsProcessed2ProcessedSuccessInner.copyWith(...)` or like so:`instanceOfListsProcessed2ProcessedSuccessInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ListsProcessed2ProcessedSuccessInnerCWProxy get copyWith =>
      _$ListsProcessed2ProcessedSuccessInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListsProcessed2ProcessedSuccessInner
_$ListsProcessed2ProcessedSuccessInnerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ListsProcessed2ProcessedSuccessInner', json, (
      $checkedConvert,
    ) {
      final val = ListsProcessed2ProcessedSuccessInner(
        item: $checkedConvert('item', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ListsProcessed2ProcessedSuccessInnerToJson(
  ListsProcessed2ProcessedSuccessInner instance,
) => <String, dynamic>{'item': ?instance.item};
