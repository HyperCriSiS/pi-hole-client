// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lists_processed2_processed.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ListsProcessed2ProcessedCWProxy {
  ListsProcessed2Processed success(
    List<ListsProcessed2ProcessedSuccessInner>? success,
  );

  ListsProcessed2Processed errors(
    List<ListsProcessed2ProcessedErrorsInner>? errors,
  );

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListsProcessed2Processed(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListsProcessed2Processed(...).copyWith(id: 12, name: "My name")
  /// ````
  ListsProcessed2Processed call({
    List<ListsProcessed2ProcessedSuccessInner>? success,
    List<ListsProcessed2ProcessedErrorsInner>? errors,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfListsProcessed2Processed.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfListsProcessed2Processed.copyWith.fieldName(...)`
class _$ListsProcessed2ProcessedCWProxyImpl
    implements _$ListsProcessed2ProcessedCWProxy {
  const _$ListsProcessed2ProcessedCWProxyImpl(this._value);

  final ListsProcessed2Processed _value;

  @override
  ListsProcessed2Processed success(
    List<ListsProcessed2ProcessedSuccessInner>? success,
  ) => this(success: success);

  @override
  ListsProcessed2Processed errors(
    List<ListsProcessed2ProcessedErrorsInner>? errors,
  ) => this(errors: errors);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListsProcessed2Processed(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListsProcessed2Processed(...).copyWith(id: 12, name: "My name")
  /// ````
  ListsProcessed2Processed call({
    Object? success = const $CopyWithPlaceholder(),
    Object? errors = const $CopyWithPlaceholder(),
  }) {
    return ListsProcessed2Processed(
      success: success == const $CopyWithPlaceholder()
          ? _value.success
          // ignore: cast_nullable_to_non_nullable
          : success as List<ListsProcessed2ProcessedSuccessInner>?,
      errors: errors == const $CopyWithPlaceholder()
          ? _value.errors
          // ignore: cast_nullable_to_non_nullable
          : errors as List<ListsProcessed2ProcessedErrorsInner>?,
    );
  }
}

extension $ListsProcessed2ProcessedCopyWith on ListsProcessed2Processed {
  /// Returns a callable class that can be used as follows: `instanceOfListsProcessed2Processed.copyWith(...)` or like so:`instanceOfListsProcessed2Processed.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ListsProcessed2ProcessedCWProxy get copyWith =>
      _$ListsProcessed2ProcessedCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListsProcessed2Processed _$ListsProcessed2ProcessedFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ListsProcessed2Processed', json, ($checkedConvert) {
  final val = ListsProcessed2Processed(
    success: $checkedConvert(
      'success',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) => ListsProcessed2ProcessedSuccessInner.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    ),
    errors: $checkedConvert(
      'errors',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) => ListsProcessed2ProcessedErrorsInner.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$ListsProcessed2ProcessedToJson(
  ListsProcessed2Processed instance,
) => <String, dynamic>{
  'success': ?instance.success?.map((e) => e.toJson()).toList(),
  'errors': ?instance.errors?.map((e) => e.toJson()).toList(),
};
