// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lists_processed3_processed_errors_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ListsProcessed3ProcessedErrorsInnerCWProxy {
  ListsProcessed3ProcessedErrorsInner item(String? item);

  ListsProcessed3ProcessedErrorsInner error(String? error);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListsProcessed3ProcessedErrorsInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListsProcessed3ProcessedErrorsInner(...).copyWith(id: 12, name: "My name")
  /// ````
  ListsProcessed3ProcessedErrorsInner call({String? item, String? error});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfListsProcessed3ProcessedErrorsInner.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfListsProcessed3ProcessedErrorsInner.copyWith.fieldName(...)`
class _$ListsProcessed3ProcessedErrorsInnerCWProxyImpl
    implements _$ListsProcessed3ProcessedErrorsInnerCWProxy {
  const _$ListsProcessed3ProcessedErrorsInnerCWProxyImpl(this._value);

  final ListsProcessed3ProcessedErrorsInner _value;

  @override
  ListsProcessed3ProcessedErrorsInner item(String? item) => this(item: item);

  @override
  ListsProcessed3ProcessedErrorsInner error(String? error) =>
      this(error: error);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListsProcessed3ProcessedErrorsInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListsProcessed3ProcessedErrorsInner(...).copyWith(id: 12, name: "My name")
  /// ````
  ListsProcessed3ProcessedErrorsInner call({
    Object? item = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
  }) {
    return ListsProcessed3ProcessedErrorsInner(
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

extension $ListsProcessed3ProcessedErrorsInnerCopyWith
    on ListsProcessed3ProcessedErrorsInner {
  /// Returns a callable class that can be used as follows: `instanceOfListsProcessed3ProcessedErrorsInner.copyWith(...)` or like so:`instanceOfListsProcessed3ProcessedErrorsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ListsProcessed3ProcessedErrorsInnerCWProxy get copyWith =>
      _$ListsProcessed3ProcessedErrorsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListsProcessed3ProcessedErrorsInner
_$ListsProcessed3ProcessedErrorsInnerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ListsProcessed3ProcessedErrorsInner', json, (
      $checkedConvert,
    ) {
      final val = ListsProcessed3ProcessedErrorsInner(
        item: $checkedConvert('item', (v) => v as String?),
        error: $checkedConvert('error', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ListsProcessed3ProcessedErrorsInnerToJson(
  ListsProcessed3ProcessedErrorsInner instance,
) => <String, dynamic>{'item': ?instance.item, 'error': ?instance.error};
