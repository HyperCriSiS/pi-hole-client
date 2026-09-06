// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lists_processed4_processed_errors_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ListsProcessed4ProcessedErrorsInnerCWProxy {
  ListsProcessed4ProcessedErrorsInner item(String? item);

  ListsProcessed4ProcessedErrorsInner error(String? error);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListsProcessed4ProcessedErrorsInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListsProcessed4ProcessedErrorsInner(...).copyWith(id: 12, name: "My name")
  /// ````
  ListsProcessed4ProcessedErrorsInner call({String? item, String? error});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfListsProcessed4ProcessedErrorsInner.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfListsProcessed4ProcessedErrorsInner.copyWith.fieldName(...)`
class _$ListsProcessed4ProcessedErrorsInnerCWProxyImpl
    implements _$ListsProcessed4ProcessedErrorsInnerCWProxy {
  const _$ListsProcessed4ProcessedErrorsInnerCWProxyImpl(this._value);

  final ListsProcessed4ProcessedErrorsInner _value;

  @override
  ListsProcessed4ProcessedErrorsInner item(String? item) => this(item: item);

  @override
  ListsProcessed4ProcessedErrorsInner error(String? error) =>
      this(error: error);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListsProcessed4ProcessedErrorsInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListsProcessed4ProcessedErrorsInner(...).copyWith(id: 12, name: "My name")
  /// ````
  ListsProcessed4ProcessedErrorsInner call({
    Object? item = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
  }) {
    return ListsProcessed4ProcessedErrorsInner(
      item: item == const $CopyWithPlaceholder()
          ? _value.item
          // ignore: cast_nullable_to_non_nullable
          : item as String?,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
    );
  }
}

extension $ListsProcessed4ProcessedErrorsInnerCopyWith
    on ListsProcessed4ProcessedErrorsInner {
  /// Returns a callable class that can be used as follows: `instanceOfListsProcessed4ProcessedErrorsInner.copyWith(...)` or like so:`instanceOfListsProcessed4ProcessedErrorsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ListsProcessed4ProcessedErrorsInnerCWProxy get copyWith =>
      _$ListsProcessed4ProcessedErrorsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListsProcessed4ProcessedErrorsInner
_$ListsProcessed4ProcessedErrorsInnerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ListsProcessed4ProcessedErrorsInner', json, (
      $checkedConvert,
    ) {
      final val = ListsProcessed4ProcessedErrorsInner(
        item: $checkedConvert('item', (v) => v as String?),
        error: $checkedConvert('error', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ListsProcessed4ProcessedErrorsInnerToJson(
  ListsProcessed4ProcessedErrorsInner instance,
) => <String, dynamic>{'item': ?instance.item, 'error': ?instance.error};
