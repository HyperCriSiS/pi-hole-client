// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post5.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Post5CWProxy {
  Post5 processed(List<String>? processed);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Post5(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Post5(...).copyWith(id: 12, name: "My name")
  /// ````
  Post5 call({List<String>? processed});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPost5.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPost5.copyWith.fieldName(...)`
class _$Post5CWProxyImpl implements _$Post5CWProxy {
  const _$Post5CWProxyImpl(this._value);

  final Post5 _value;

  @override
  Post5 processed(List<String>? processed) => this(processed: processed);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Post5(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Post5(...).copyWith(id: 12, name: "My name")
  /// ````
  Post5 call({Object? processed = const $CopyWithPlaceholder()}) {
    return Post5(
      processed: processed == const $CopyWithPlaceholder()
          ? _value.processed
          // ignore: cast_nullable_to_non_nullable
          : processed as List<String>?,
    );
  }
}

extension $Post5CopyWith on Post5 {
  /// Returns a callable class that can be used as follows: `instanceOfPost5.copyWith(...)` or like so:`instanceOfPost5.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Post5CWProxy get copyWith => _$Post5CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Post5 _$Post5FromJson(Map<String, dynamic> json) =>
    $checkedCreate('Post5', json, ($checkedConvert) {
      final val = Post5(
        processed: $checkedConvert(
          'processed',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$Post5ToJson(Post5 instance) => <String, dynamic>{
  'processed': ?instance.processed,
};
