// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'type2.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Type2CWProxy {
  Type2 type(Type2TypeEnum? type);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Type2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Type2(...).copyWith(id: 12, name: "My name")
  /// ````
  Type2 call({Type2TypeEnum? type});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfType2.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfType2.copyWith.fieldName(...)`
class _$Type2CWProxyImpl implements _$Type2CWProxy {
  const _$Type2CWProxyImpl(this._value);

  final Type2 _value;

  @override
  Type2 type(Type2TypeEnum? type) => this(type: type);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Type2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Type2(...).copyWith(id: 12, name: "My name")
  /// ````
  Type2 call({Object? type = const $CopyWithPlaceholder()}) {
    return Type2(
      type: type == const $CopyWithPlaceholder()
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as Type2TypeEnum?,
    );
  }
}

extension $Type2CopyWith on Type2 {
  /// Returns a callable class that can be used as follows: `instanceOfType2.copyWith(...)` or like so:`instanceOfType2.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Type2CWProxy get copyWith => _$Type2CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Type2 _$Type2FromJson(Map<String, dynamic> json) =>
    $checkedCreate('Type2', json, ($checkedConvert) {
      final val = Type2(
        type: $checkedConvert(
          'type',
          (v) => $enumDecodeNullable(_$Type2TypeEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$Type2ToJson(Type2 instance) => <String, dynamic>{
  'type': ?_$Type2TypeEnumEnumMap[instance.type],
};

const _$Type2TypeEnumEnumMap = {
  Type2TypeEnum.allow: 'allow',
  Type2TypeEnum.block: 'block',
};
