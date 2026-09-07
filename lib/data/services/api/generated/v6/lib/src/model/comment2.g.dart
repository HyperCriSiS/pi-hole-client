// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment2.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Comment2CWProxy {
  Comment2 comment(String? comment);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Comment2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Comment2(...).copyWith(id: 12, name: "My name")
  /// ````
  Comment2 call({String? comment});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfComment2.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfComment2.copyWith.fieldName(...)`
class _$Comment2CWProxyImpl implements _$Comment2CWProxy {
  const _$Comment2CWProxyImpl(this._value);

  final Comment2 _value;

  @override
  Comment2 comment(String? comment) => this(comment: comment);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Comment2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Comment2(...).copyWith(id: 12, name: "My name")
  /// ````
  Comment2 call({Object? comment = const $CopyWithPlaceholder()}) {
    return Comment2(
      comment: comment == const $CopyWithPlaceholder()
          ? _value.comment
          // ignore: cast_nullable_to_non_nullable
          : comment as String?,
    );
  }
}

extension $Comment2CopyWith on Comment2 {
  /// Returns a callable class that can be used as follows: `instanceOfComment2.copyWith(...)` or like so:`instanceOfComment2.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Comment2CWProxy get copyWith => _$Comment2CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment2 _$Comment2FromJson(Map<String, dynamic> json) =>
    $checkedCreate('Comment2', json, ($checkedConvert) {
      final val = Comment2(
        comment: $checkedConvert('comment', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$Comment2ToJson(Comment2 instance) => <String, dynamic>{
  'comment': ?instance.comment,
};
