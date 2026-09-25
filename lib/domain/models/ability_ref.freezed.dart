// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ability_ref.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AbilityRef {
  int get id => throw _privateConstructorUsedError;
  String get nameZh => throw _privateConstructorUsedError;
  String get nameEn => throw _privateConstructorUsedError;
  bool get isHidden => throw _privateConstructorUsedError;

  /// Create a copy of AbilityRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AbilityRefCopyWith<AbilityRef> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AbilityRefCopyWith<$Res> {
  factory $AbilityRefCopyWith(
          AbilityRef value, $Res Function(AbilityRef) then) =
      _$AbilityRefCopyWithImpl<$Res, AbilityRef>;
  @useResult
  $Res call({int id, String nameZh, String nameEn, bool isHidden});
}

/// @nodoc
class _$AbilityRefCopyWithImpl<$Res, $Val extends AbilityRef>
    implements $AbilityRefCopyWith<$Res> {
  _$AbilityRefCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AbilityRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nameZh = null,
    Object? nameEn = null,
    Object? isHidden = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      nameZh: null == nameZh
          ? _value.nameZh
          : nameZh // ignore: cast_nullable_to_non_nullable
              as String,
      nameEn: null == nameEn
          ? _value.nameEn
          : nameEn // ignore: cast_nullable_to_non_nullable
              as String,
      isHidden: null == isHidden
          ? _value.isHidden
          : isHidden // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AbilityRefImplCopyWith<$Res>
    implements $AbilityRefCopyWith<$Res> {
  factory _$$AbilityRefImplCopyWith(
          _$AbilityRefImpl value, $Res Function(_$AbilityRefImpl) then) =
      __$$AbilityRefImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String nameZh, String nameEn, bool isHidden});
}

/// @nodoc
class __$$AbilityRefImplCopyWithImpl<$Res>
    extends _$AbilityRefCopyWithImpl<$Res, _$AbilityRefImpl>
    implements _$$AbilityRefImplCopyWith<$Res> {
  __$$AbilityRefImplCopyWithImpl(
      _$AbilityRefImpl _value, $Res Function(_$AbilityRefImpl) _then)
      : super(_value, _then);

  /// Create a copy of AbilityRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nameZh = null,
    Object? nameEn = null,
    Object? isHidden = null,
  }) {
    return _then(_$AbilityRefImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      nameZh: null == nameZh
          ? _value.nameZh
          : nameZh // ignore: cast_nullable_to_non_nullable
              as String,
      nameEn: null == nameEn
          ? _value.nameEn
          : nameEn // ignore: cast_nullable_to_non_nullable
              as String,
      isHidden: null == isHidden
          ? _value.isHidden
          : isHidden // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$AbilityRefImpl implements _AbilityRef {
  const _$AbilityRefImpl(
      {required this.id,
      required this.nameZh,
      required this.nameEn,
      required this.isHidden});

  @override
  final int id;
  @override
  final String nameZh;
  @override
  final String nameEn;
  @override
  final bool isHidden;

  @override
  String toString() {
    return 'AbilityRef(id: $id, nameZh: $nameZh, nameEn: $nameEn, isHidden: $isHidden)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AbilityRefImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nameZh, nameZh) || other.nameZh == nameZh) &&
            (identical(other.nameEn, nameEn) || other.nameEn == nameEn) &&
            (identical(other.isHidden, isHidden) ||
                other.isHidden == isHidden));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, nameZh, nameEn, isHidden);

  /// Create a copy of AbilityRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AbilityRefImplCopyWith<_$AbilityRefImpl> get copyWith =>
      __$$AbilityRefImplCopyWithImpl<_$AbilityRefImpl>(this, _$identity);
}

abstract class _AbilityRef implements AbilityRef {
  const factory _AbilityRef(
      {required final int id,
      required final String nameZh,
      required final String nameEn,
      required final bool isHidden}) = _$AbilityRefImpl;

  @override
  int get id;
  @override
  String get nameZh;
  @override
  String get nameEn;
  @override
  bool get isHidden;

  /// Create a copy of AbilityRef
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AbilityRefImplCopyWith<_$AbilityRefImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
