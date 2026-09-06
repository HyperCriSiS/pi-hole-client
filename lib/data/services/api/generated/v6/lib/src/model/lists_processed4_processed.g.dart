// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lists_processed4_processed.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ListsProcessed4ProcessedCWProxy {
  ListsProcessed4Processed success(
    List<ListsProcessed4ProcessedSuccessInner>? success,
  );

  ListsProcessed4Processed errors(
    List<ListsProcessed4ProcessedErrorsInner>? errors,
  );

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListsProcessed4Processed(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListsProcessed4Processed(...).copyWith(id: 12, name: "My name")
  /// ````
  ListsProcessed4Processed call({
    List<ListsProcessed4ProcessedSuccessInner>? success,
    List<ListsProcessed4ProcessedErrorsInner>? errors,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfListsProcessed4Processed.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfListsProcessed4Processed.copyWith.fieldName(...)`
class _$ListsProcessed4ProcessedCWProxyImpl
    implements _$ListsProcessed4ProcessedCWProxy {
  const _$ListsProcessed4ProcessedCWProxyImpl(this._value);

  final ListsProcessed4Processed _value;

  @override
  ListsProcessed4Processed success(
    List<ListsProcessed4ProcessedSuccessInner>? success,
  ) => this(success: success);

  @override
  ListsProcessed4Processed errors(
    List<ListsProcessed4ProcessedErrorsInner>? errors,
  ) => this(errors: errors);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListsProcessed4Processed(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListsProcessed4Processed(...).copyWith(id: 12, name: "My name")
  /// ````
  ListsProcessed4Processed call({
    Object? success = const $CopyWithPlaceholder(),
    Object? errors = const $CopyWithPlaceholder(),
  }) {
    return ListsProcessed4Processed(
      success: success == const $CopyWithPlaceholder()
          ? _value.success
          // ignore: cast_nullable_to_non_nullable
          : success as List<ListsProcessed4ProcessedSuccessInner>?,
      errors: errors == const $CopyWithPlaceholder()
          ? _value.errors
          // ignore: cast_nullable_to_non_nullable
          : errors as List<ListsProcessed4ProcessedErrorsInner>?,
    );
  }
}

extension $ListsProcessed4ProcessedCopyWith on ListsProcessed4Processed {
  /// Returns a callable class that can be used as follows: `instanceOfListsProcessed4Processed.copyWith(...)` or like so:`instanceOfListsProcessed4Processed.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ListsProcessed4ProcessedCWProxy get copyWith =>
      _$ListsProcessed4ProcessedCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListsProcessed4Processed _$ListsProcessed4ProcessedFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ListsProcessed4Processed', json, ($checkedConvert) {
  final val = ListsProcessed4Processed(
    success: $checkedConvert(
      'success',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) => ListsProcessed4ProcessedSuccessInner.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    ),
    errors: $checkedConvert(
      'errors',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) => ListsProcessed4ProcessedErrorsInner.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$ListsProcessed4ProcessedToJson(
  ListsProcessed4Processed instance,
) => <String, dynamic>{
  'success': ?instance.success?.map((e) => e.toJson()).toList(),
  'errors': ?instance.errors?.map((e) => e.toJson()).toList(),
};
