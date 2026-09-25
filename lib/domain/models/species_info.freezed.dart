// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'species_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SpeciesInfo {
  int get speciesId => throw _privateConstructorUsedError;
  int get nationalDex => throw _privateConstructorUsedError;
  int get generationId => throw _privateConstructorUsedError;

  /// 分类（如“种子宝可梦”；上游缺失为 null）。
  String? get genusZh => throw _privateConstructorUsedError;
  String? get genusEn => throw _privateConstructorUsedError;

  /// Create a copy of SpeciesInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SpeciesInfoCopyWith<SpeciesInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpeciesInfoCopyWith<$Res> {
  factory $SpeciesInfoCopyWith(
          SpeciesInfo value, $Res Function(SpeciesInfo) then) =
      _$SpeciesInfoCopyWithImpl<$Res, SpeciesInfo>;
  @useResult
  $Res call(
      {int speciesId,
      int nationalDex,
      int generationId,
      String? genusZh,
      String? genusEn});
}

/// @nodoc
class _$SpeciesInfoCopyWithImpl<$Res, $Val extends SpeciesInfo>
    implements $SpeciesInfoCopyWith<$Res> {
  _$SpeciesInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpeciesInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? speciesId = null,
    Object? nationalDex = null,
    Object? generationId = null,
    Object? genusZh = freezed,
    Object? genusEn = freezed,
  }) {
    return _then(_value.copyWith(
      speciesId: null == speciesId
          ? _value.speciesId
          : speciesId // ignore: cast_nullable_to_non_nullable
              as int,
      nationalDex: null == nationalDex
          ? _value.nationalDex
          : nationalDex // ignore: cast_nullable_to_non_nullable
              as int,
      generationId: null == generationId
          ? _value.generationId
          : generationId // ignore: cast_nullable_to_non_nullable
              as int,
      genusZh: freezed == genusZh
          ? _value.genusZh
          : genusZh // ignore: cast_nullable_to_non_nullable
              as String?,
      genusEn: freezed == genusEn
          ? _value.genusEn
          : genusEn // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SpeciesInfoImplCopyWith<$Res>
    implements $SpeciesInfoCopyWith<$Res> {
  factory _$$SpeciesInfoImplCopyWith(
          _$SpeciesInfoImpl value, $Res Function(_$SpeciesInfoImpl) then) =
      __$$SpeciesInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int speciesId,
      int nationalDex,
      int generationId,
      String? genusZh,
      String? genusEn});
}

/// @nodoc
class __$$SpeciesInfoImplCopyWithImpl<$Res>
    extends _$SpeciesInfoCopyWithImpl<$Res, _$SpeciesInfoImpl>
    implements _$$SpeciesInfoImplCopyWith<$Res> {
  __$$SpeciesInfoImplCopyWithImpl(
      _$SpeciesInfoImpl _value, $Res Function(_$SpeciesInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of SpeciesInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? speciesId = null,
    Object? nationalDex = null,
    Object? generationId = null,
    Object? genusZh = freezed,
    Object? genusEn = freezed,
  }) {
    return _then(_$SpeciesInfoImpl(
      speciesId: null == speciesId
          ? _value.speciesId
          : speciesId // ignore: cast_nullable_to_non_nullable
              as int,
      nationalDex: null == nationalDex
          ? _value.nationalDex
          : nationalDex // ignore: cast_nullable_to_non_nullable
              as int,
      generationId: null == generationId
          ? _value.generationId
          : generationId // ignore: cast_nullable_to_non_nullable
              as int,
      genusZh: freezed == genusZh
          ? _value.genusZh
          : genusZh // ignore: cast_nullable_to_non_nullable
              as String?,
      genusEn: freezed == genusEn
          ? _value.genusEn
          : genusEn // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$SpeciesInfoImpl implements _SpeciesInfo {
  const _$SpeciesInfoImpl(
      {required this.speciesId,
      required this.nationalDex,
      required this.generationId,
      this.genusZh,
      this.genusEn});

  @override
  final int speciesId;
  @override
  final int nationalDex;
  @override
  final int generationId;

  /// 分类（如“种子宝可梦”；上游缺失为 null）。
  @override
  final String? genusZh;
  @override
  final String? genusEn;

  @override
  String toString() {
    return 'SpeciesInfo(speciesId: $speciesId, nationalDex: $nationalDex, generationId: $generationId, genusZh: $genusZh, genusEn: $genusEn)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpeciesInfoImpl &&
            (identical(other.speciesId, speciesId) ||
                other.speciesId == speciesId) &&
            (identical(other.nationalDex, nationalDex) ||
                other.nationalDex == nationalDex) &&
            (identical(other.generationId, generationId) ||
                other.generationId == generationId) &&
            (identical(other.genusZh, genusZh) || other.genusZh == genusZh) &&
            (identical(other.genusEn, genusEn) || other.genusEn == genusEn));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, speciesId, nationalDex, generationId, genusZh, genusEn);

  /// Create a copy of SpeciesInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpeciesInfoImplCopyWith<_$SpeciesInfoImpl> get copyWith =>
      __$$SpeciesInfoImplCopyWithImpl<_$SpeciesInfoImpl>(this, _$identity);
}

abstract class _SpeciesInfo implements SpeciesInfo {
  const factory _SpeciesInfo(
      {required final int speciesId,
      required final int nationalDex,
      required final int generationId,
      final String? genusZh,
      final String? genusEn}) = _$SpeciesInfoImpl;

  @override
  int get speciesId;
  @override
  int get nationalDex;
  @override
  int get generationId;

  /// 分类（如“种子宝可梦”；上游缺失为 null）。
  @override
  String? get genusZh;
  @override
  String? get genusEn;

  /// Create a copy of SpeciesInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpeciesInfoImplCopyWith<_$SpeciesInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
