// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment4.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Comment4CWProxy {
  Comment4 comment(String? comment);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Comment4(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Comment4(...).copyWith(id: 12, name: "My name")
  /// ````
  Comment4 call({String? comment});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfComment4.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfComment4.copyWith.fieldName(...)`
class _$Comment4CWProxyImpl implements _$Comment4CWProxy {
  const _$Comment4CWProxyImpl(this._value);

  final Comment4 _value;

  @override
  Comment4 comment(String? comment) => this(comment: comment);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Comment4(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Comment4(...).copyWith(id: 12, name: "My name")
  /// ````
  Comment4 call({Object? comment = const $CopyWithPlaceholder()}) {
    return Comment4(
      comment: comment == const $CopyWithPlaceholder()
          ? _value.comment
          // ignore: cast_nullable_to_non_nullable
          : comment as String?,
    );
  }
}

extension $Comment4CopyWith on Comment4 {
  /// Returns a callable class that can be used as follows: `instanceOfComment4.copyWith(...)` or like so:`instanceOfComment4.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Comment4CWProxy get copyWith => _$Comment4CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment4 _$Comment4FromJson(Map<String, dynamic> json) =>
    $checkedCreate('Comment4', json, ($checkedConvert) {
      final val = Comment4(
        comment: $checkedConvert('comment', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$Comment4ToJson(Comment4 instance) => <String, dynamic>{
  'comment': ?instance.comment,
};
