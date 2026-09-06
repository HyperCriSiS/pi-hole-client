// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lists_processed3_processed.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ListsProcessed3ProcessedCWProxy {
  ListsProcessed3Processed success(
    List<ListsProcessed3ProcessedSuccessInner>? success,
  );

  ListsProcessed3Processed errors(
    List<ListsProcessed3ProcessedErrorsInner>? errors,
  );

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListsProcessed3Processed(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListsProcessed3Processed(...).copyWith(id: 12, name: "My name")
  /// ````
  ListsProcessed3Processed call({
    List<ListsProcessed3ProcessedSuccessInner>? success,
    List<ListsProcessed3ProcessedErrorsInner>? errors,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfListsProcessed3Processed.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfListsProcessed3Processed.copyWith.fieldName(...)`
class _$ListsProcessed3ProcessedCWProxyImpl
    implements _$ListsProcessed3ProcessedCWProxy {
  const _$ListsProcessed3ProcessedCWProxyImpl(this._value);

  final ListsProcessed3Processed _value;

  @override
  ListsProcessed3Processed success(
    List<ListsProcessed3ProcessedSuccessInner>? success,
  ) => this(success: success);

  @override
  ListsProcessed3Processed errors(
    List<ListsProcessed3ProcessedErrorsInner>? errors,
  ) => this(errors: errors);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListsProcessed3Processed(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListsProcessed3Processed(...).copyWith(id: 12, name: "My name")
  /// ````
  ListsProcessed3Processed call({
    Object? success = const $CopyWithPlaceholder(),
    Object? errors = const $CopyWithPlaceholder(),
  }) {
    return ListsProcessed3Processed(
      success: success == const $CopyWithPlaceholder()
          ? _value.success
          // ignore: cast_nullable_to_non_nullable
          : success as List<ListsProcessed3ProcessedSuccessInner>?,
      errors: errors == const $CopyWithPlaceholder()
          ? _value.errors
          // ignore: cast_nullable_to_non_nullable
          : errors as List<ListsProcessed3ProcessedErrorsInner>?,
    );
  }
}

extension $ListsProcessed3ProcessedCopyWith on ListsProcessed3Processed {
  /// Returns a callable class that can be used as follows: `instanceOfListsProcessed3Processed.copyWith(...)` or like so:`instanceOfListsProcessed3Processed.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ListsProcessed3ProcessedCWProxy get copyWith =>
      _$ListsProcessed3ProcessedCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListsProcessed3Processed _$ListsProcessed3ProcessedFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ListsProcessed3Processed', json, ($checkedConvert) {
  final val = ListsProcessed3Processed(
    success: $checkedConvert(
      'success',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) => ListsProcessed3ProcessedSuccessInner.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    ),
    errors: $checkedConvert(
      'errors',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) => ListsProcessed3ProcessedErrorsInner.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$ListsProcessed3ProcessedToJson(
  ListsProcessed3Processed instance,
) => <String, dynamic>{
  'success': ?instance.success?.map((e) => e.toJson()).toList(),
  'errors': ?instance.errors?.map((e) => e.toJson()).toList(),
};
