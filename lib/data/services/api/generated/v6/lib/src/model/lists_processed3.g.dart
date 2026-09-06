// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lists_processed3.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ListsProcessed3CWProxy {
  ListsProcessed3 processed(ListsProcessed3Processed? processed);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListsProcessed3(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListsProcessed3(...).copyWith(id: 12, name: "My name")
  /// ````
  ListsProcessed3 call({ListsProcessed3Processed? processed});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfListsProcessed3.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfListsProcessed3.copyWith.fieldName(...)`
class _$ListsProcessed3CWProxyImpl implements _$ListsProcessed3CWProxy {
  const _$ListsProcessed3CWProxyImpl(this._value);

  final ListsProcessed3 _value;

  @override
  ListsProcessed3 processed(ListsProcessed3Processed? processed) =>
      this(processed: processed);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListsProcessed3(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListsProcessed3(...).copyWith(id: 12, name: "My name")
  /// ````
  ListsProcessed3 call({Object? processed = const $CopyWithPlaceholder()}) {
    return ListsProcessed3(
      processed: processed == const $CopyWithPlaceholder()
          ? _value.processed
          // ignore: cast_nullable_to_non_nullable
          : processed as ListsProcessed3Processed?,
    );
  }
}

extension $ListsProcessed3CopyWith on ListsProcessed3 {
  /// Returns a callable class that can be used as follows: `instanceOfListsProcessed3.copyWith(...)` or like so:`instanceOfListsProcessed3.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ListsProcessed3CWProxy get copyWith => _$ListsProcessed3CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListsProcessed3 _$ListsProcessed3FromJson(Map<String, dynamic> json) =>
    $checkedCreate('ListsProcessed3', json, ($checkedConvert) {
      final val = ListsProcessed3(
        processed: $checkedConvert(
          'processed',
          (v) => v == null
              ? null
              : ListsProcessed3Processed.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ListsProcessed3ToJson(ListsProcessed3 instance) =>
    <String, dynamic>{'processed': ?instance.processed?.toJson()};
