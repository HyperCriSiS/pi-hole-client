// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lists_processed2.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ListsProcessed2CWProxy {
  ListsProcessed2 processed(ListsProcessed2Processed? processed);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListsProcessed2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListsProcessed2(...).copyWith(id: 12, name: "My name")
  /// ````
  ListsProcessed2 call({ListsProcessed2Processed? processed});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfListsProcessed2.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfListsProcessed2.copyWith.fieldName(...)`
class _$ListsProcessed2CWProxyImpl implements _$ListsProcessed2CWProxy {
  const _$ListsProcessed2CWProxyImpl(this._value);

  final ListsProcessed2 _value;

  @override
  ListsProcessed2 processed(ListsProcessed2Processed? processed) =>
      this(processed: processed);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListsProcessed2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListsProcessed2(...).copyWith(id: 12, name: "My name")
  /// ````
  ListsProcessed2 call({Object? processed = const $CopyWithPlaceholder()}) {
    return ListsProcessed2(
      processed: processed == const $CopyWithPlaceholder()
          ? _value.processed
          // ignore: cast_nullable_to_non_nullable
          : processed as ListsProcessed2Processed?,
    );
  }
}

extension $ListsProcessed2CopyWith on ListsProcessed2 {
  /// Returns a callable class that can be used as follows: `instanceOfListsProcessed2.copyWith(...)` or like so:`instanceOfListsProcessed2.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ListsProcessed2CWProxy get copyWith => _$ListsProcessed2CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListsProcessed2 _$ListsProcessed2FromJson(Map<String, dynamic> json) =>
    $checkedCreate('ListsProcessed2', json, ($checkedConvert) {
      final val = ListsProcessed2(
        processed: $checkedConvert(
          'processed',
          (v) => v == null
              ? null
              : ListsProcessed2Processed.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ListsProcessed2ToJson(ListsProcessed2 instance) =>
    <String, dynamic>{'processed': ?instance.processed?.toJson()};
