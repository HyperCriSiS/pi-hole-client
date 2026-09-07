// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment3.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Comment3CWProxy {
  Comment3 comment(String? comment);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Comment3(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Comment3(...).copyWith(id: 12, name: "My name")
  /// ````
  Comment3 call({String? comment});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfComment3.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfComment3.copyWith.fieldName(...)`
class _$Comment3CWProxyImpl implements _$Comment3CWProxy {
  const _$Comment3CWProxyImpl(this._value);

  final Comment3 _value;

  @override
  Comment3 comment(String? comment) => this(comment: comment);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Comment3(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Comment3(...).copyWith(id: 12, name: "My name")
  /// ````
  Comment3 call({Object? comment = const $CopyWithPlaceholder()}) {
    return Comment3(
      comment: comment == const $CopyWithPlaceholder()
          ? _value.comment
          // ignore: cast_nullable_to_non_nullable
          : comment as String?,
    );
  }
}

extension $Comment3CopyWith on Comment3 {
  /// Returns a callable class that can be used as follows: `instanceOfComment3.copyWith(...)` or like so:`instanceOfComment3.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Comment3CWProxy get copyWith => _$Comment3CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment3 _$Comment3FromJson(Map<String, dynamic> json) =>
    $checkedCreate('Comment3', json, ($checkedConvert) {
      final val = Comment3(
        comment: $checkedConvert('comment', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$Comment3ToJson(Comment3 instance) => <String, dynamic>{
  'comment': ?instance.comment,
};
