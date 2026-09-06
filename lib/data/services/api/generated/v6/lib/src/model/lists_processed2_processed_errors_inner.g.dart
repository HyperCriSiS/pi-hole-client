// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lists_processed2_processed_errors_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ListsProcessed2ProcessedErrorsInnerCWProxy {
  ListsProcessed2ProcessedErrorsInner item(String? item);

  ListsProcessed2ProcessedErrorsInner error(String? error);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListsProcessed2ProcessedErrorsInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListsProcessed2ProcessedErrorsInner(...).copyWith(id: 12, name: "My name")
  /// ````
  ListsProcessed2ProcessedErrorsInner call({String? item, String? error});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfListsProcessed2ProcessedErrorsInner.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfListsProcessed2ProcessedErrorsInner.copyWith.fieldName(...)`
class _$ListsProcessed2ProcessedErrorsInnerCWProxyImpl
    implements _$ListsProcessed2ProcessedErrorsInnerCWProxy {
  const _$ListsProcessed2ProcessedErrorsInnerCWProxyImpl(this._value);

  final ListsProcessed2ProcessedErrorsInner _value;

  @override
  ListsProcessed2ProcessedErrorsInner item(String? item) => this(item: item);

  @override
  ListsProcessed2ProcessedErrorsInner error(String? error) =>
      this(error: error);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListsProcessed2ProcessedErrorsInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListsProcessed2ProcessedErrorsInner(...).copyWith(id: 12, name: "My name")
  /// ````
  ListsProcessed2ProcessedErrorsInner call({
    Object? item = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
  }) {
    return ListsProcessed2ProcessedErrorsInner(
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

extension $ListsProcessed2ProcessedErrorsInnerCopyWith
    on ListsProcessed2ProcessedErrorsInner {
  /// Returns a callable class that can be used as follows: `instanceOfListsProcessed2ProcessedErrorsInner.copyWith(...)` or like so:`instanceOfListsProcessed2ProcessedErrorsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ListsProcessed2ProcessedErrorsInnerCWProxy get copyWith =>
      _$ListsProcessed2ProcessedErrorsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListsProcessed2ProcessedErrorsInner
_$ListsProcessed2ProcessedErrorsInnerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ListsProcessed2ProcessedErrorsInner', json, (
      $checkedConvert,
    ) {
      final val = ListsProcessed2ProcessedErrorsInner(
        item: $checkedConvert('item', (v) => v as String?),
        error: $checkedConvert('error', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ListsProcessed2ProcessedErrorsInnerToJson(
  ListsProcessed2ProcessedErrorsInner instance,
) => <String, dynamic>{'item': ?instance.item, 'error': ?instance.error};
