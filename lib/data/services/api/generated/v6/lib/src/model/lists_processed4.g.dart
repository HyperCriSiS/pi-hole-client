// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lists_processed4.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ListsProcessed4CWProxy {
  ListsProcessed4 processed(ListsProcessed4Processed? processed);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListsProcessed4(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListsProcessed4(...).copyWith(id: 12, name: "My name")
  /// ````
  ListsProcessed4 call({ListsProcessed4Processed? processed});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfListsProcessed4.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfListsProcessed4.copyWith.fieldName(...)`
class _$ListsProcessed4CWProxyImpl implements _$ListsProcessed4CWProxy {
  const _$ListsProcessed4CWProxyImpl(this._value);

  final ListsProcessed4 _value;

  @override
  ListsProcessed4 processed(ListsProcessed4Processed? processed) =>
      this(processed: processed);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListsProcessed4(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListsProcessed4(...).copyWith(id: 12, name: "My name")
  /// ````
  ListsProcessed4 call({Object? processed = const $CopyWithPlaceholder()}) {
    return ListsProcessed4(
      processed: processed == const $CopyWithPlaceholder()
          ? _value.processed
          // ignore: cast_nullable_to_non_nullable
          : processed as ListsProcessed4Processed?,
    );
  }
}

extension $ListsProcessed4CopyWith on ListsProcessed4 {
  /// Returns a callable class that can be used as follows: `instanceOfListsProcessed4.copyWith(...)` or like so:`instanceOfListsProcessed4.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ListsProcessed4CWProxy get copyWith => _$ListsProcessed4CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListsProcessed4 _$ListsProcessed4FromJson(Map<String, dynamic> json) =>
    $checkedCreate('ListsProcessed4', json, ($checkedConvert) {
      final val = ListsProcessed4(
        processed: $checkedConvert(
          'processed',
          (v) => v == null
              ? null
              : ListsProcessed4Processed.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ListsProcessed4ToJson(ListsProcessed4 instance) =>
    <String, dynamic>{'processed': ?instance.processed?.toJson()};
