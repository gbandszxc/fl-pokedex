// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'filters.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$FilterState {
  String get query => throw _privateConstructorUsedError;
  Set<int> get generations => throw _privateConstructorUsedError;
  Set<String> get typeIds => throw _privateConstructorUsedError;
  TypeMatchMode get typeMatchMode => throw _privateConstructorUsedError;
  Set<int> get pokedexIds => throw _privateConstructorUsedError;
  int? get dexMin => throw _privateConstructorUsedError;
  int? get dexMax => throw _privateConstructorUsedError;
  Set<SpecialTag> get tags => throw _privateConstructorUsedError;

  /// Create a copy of FilterState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FilterStateCopyWith<FilterState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FilterStateCopyWith<$Res> {
  factory $FilterStateCopyWith(
          FilterState value, $Res Function(FilterState) then) =
      _$FilterStateCopyWithImpl<$Res, FilterState>;
  @useResult
  $Res call(
      {String query,
      Set<int> generations,
      Set<String> typeIds,
      TypeMatchMode typeMatchMode,
      Set<int> pokedexIds,
      int? dexMin,
      int? dexMax,
      Set<SpecialTag> tags});
}

/// @nodoc
class _$FilterStateCopyWithImpl<$Res, $Val extends FilterState>
    implements $FilterStateCopyWith<$Res> {
  _$FilterStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FilterState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = null,
    Object? generations = null,
    Object? typeIds = null,
    Object? typeMatchMode = null,
    Object? pokedexIds = null,
    Object? dexMin = freezed,
    Object? dexMax = freezed,
    Object? tags = null,
  }) {
    return _then(_value.copyWith(
      query: null == query
          ? _value.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
      generations: null == generations
          ? _value.generations
          : generations // ignore: cast_nullable_to_non_nullable
              as Set<int>,
      typeIds: null == typeIds
          ? _value.typeIds
          : typeIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      typeMatchMode: null == typeMatchMode
          ? _value.typeMatchMode
          : typeMatchMode // ignore: cast_nullable_to_non_nullable
              as TypeMatchMode,
      pokedexIds: null == pokedexIds
          ? _value.pokedexIds
          : pokedexIds // ignore: cast_nullable_to_non_nullable
              as Set<int>,
      dexMin: freezed == dexMin
          ? _value.dexMin
          : dexMin // ignore: cast_nullable_to_non_nullable
              as int?,
      dexMax: freezed == dexMax
          ? _value.dexMax
          : dexMax // ignore: cast_nullable_to_non_nullable
              as int?,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as Set<SpecialTag>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FilterStateImplCopyWith<$Res>
    implements $FilterStateCopyWith<$Res> {
  factory _$$FilterStateImplCopyWith(
          _$FilterStateImpl value, $Res Function(_$FilterStateImpl) then) =
      __$$FilterStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String query,
      Set<int> generations,
      Set<String> typeIds,
      TypeMatchMode typeMatchMode,
      Set<int> pokedexIds,
      int? dexMin,
      int? dexMax,
      Set<SpecialTag> tags});
}

/// @nodoc
class __$$FilterStateImplCopyWithImpl<$Res>
    extends _$FilterStateCopyWithImpl<$Res, _$FilterStateImpl>
    implements _$$FilterStateImplCopyWith<$Res> {
  __$$FilterStateImplCopyWithImpl(
      _$FilterStateImpl _value, $Res Function(_$FilterStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of FilterState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = null,
    Object? generations = null,
    Object? typeIds = null,
    Object? typeMatchMode = null,
    Object? pokedexIds = null,
    Object? dexMin = freezed,
    Object? dexMax = freezed,
    Object? tags = null,
  }) {
    return _then(_$FilterStateImpl(
      query: null == query
          ? _value.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
      generations: null == generations
          ? _value._generations
          : generations // ignore: cast_nullable_to_non_nullable
              as Set<int>,
      typeIds: null == typeIds
          ? _value._typeIds
          : typeIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      typeMatchMode: null == typeMatchMode
          ? _value.typeMatchMode
          : typeMatchMode // ignore: cast_nullable_to_non_nullable
              as TypeMatchMode,
      pokedexIds: null == pokedexIds
          ? _value._pokedexIds
          : pokedexIds // ignore: cast_nullable_to_non_nullable
              as Set<int>,
      dexMin: freezed == dexMin
          ? _value.dexMin
          : dexMin // ignore: cast_nullable_to_non_nullable
              as int?,
      dexMax: freezed == dexMax
          ? _value.dexMax
          : dexMax // ignore: cast_nullable_to_non_nullable
              as int?,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as Set<SpecialTag>,
    ));
  }
}

/// @nodoc

class _$FilterStateImpl extends _FilterState {
  const _$FilterStateImpl(
      {this.query = '',
      final Set<int> generations = const <int>{},
      final Set<String> typeIds = const <String>{},
      this.typeMatchMode = TypeMatchMode.any,
      final Set<int> pokedexIds = const <int>{},
      this.dexMin,
      this.dexMax,
      final Set<SpecialTag> tags = const <SpecialTag>{}})
      : _generations = generations,
        _typeIds = typeIds,
        _pokedexIds = pokedexIds,
        _tags = tags,
        super._();

  @override
  @JsonKey()
  final String query;
  final Set<int> _generations;
  @override
  @JsonKey()
  Set<int> get generations {
    if (_generations is EqualUnmodifiableSetView) return _generations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_generations);
  }

  final Set<String> _typeIds;
  @override
  @JsonKey()
  Set<String> get typeIds {
    if (_typeIds is EqualUnmodifiableSetView) return _typeIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_typeIds);
  }

  @override
  @JsonKey()
  final TypeMatchMode typeMatchMode;
  final Set<int> _pokedexIds;
  @override
  @JsonKey()
  Set<int> get pokedexIds {
    if (_pokedexIds is EqualUnmodifiableSetView) return _pokedexIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_pokedexIds);
  }

  @override
  final int? dexMin;
  @override
  final int? dexMax;
  final Set<SpecialTag> _tags;
  @override
  @JsonKey()
  Set<SpecialTag> get tags {
    if (_tags is EqualUnmodifiableSetView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_tags);
  }

  @override
  String toString() {
    return 'FilterState(query: $query, generations: $generations, typeIds: $typeIds, typeMatchMode: $typeMatchMode, pokedexIds: $pokedexIds, dexMin: $dexMin, dexMax: $dexMax, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FilterStateImpl &&
            (identical(other.query, query) || other.query == query) &&
            const DeepCollectionEquality()
                .equals(other._generations, _generations) &&
            const DeepCollectionEquality().equals(other._typeIds, _typeIds) &&
            (identical(other.typeMatchMode, typeMatchMode) ||
                other.typeMatchMode == typeMatchMode) &&
            const DeepCollectionEquality()
                .equals(other._pokedexIds, _pokedexIds) &&
            (identical(other.dexMin, dexMin) || other.dexMin == dexMin) &&
            (identical(other.dexMax, dexMax) || other.dexMax == dexMax) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      query,
      const DeepCollectionEquality().hash(_generations),
      const DeepCollectionEquality().hash(_typeIds),
      typeMatchMode,
      const DeepCollectionEquality().hash(_pokedexIds),
      dexMin,
      dexMax,
      const DeepCollectionEquality().hash(_tags));

  /// Create a copy of FilterState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FilterStateImplCopyWith<_$FilterStateImpl> get copyWith =>
      __$$FilterStateImplCopyWithImpl<_$FilterStateImpl>(this, _$identity);
}

abstract class _FilterState extends FilterState {
  const factory _FilterState(
      {final String query,
      final Set<int> generations,
      final Set<String> typeIds,
      final TypeMatchMode typeMatchMode,
      final Set<int> pokedexIds,
      final int? dexMin,
      final int? dexMax,
      final Set<SpecialTag> tags}) = _$FilterStateImpl;
  const _FilterState._() : super._();

  @override
  String get query;
  @override
  Set<int> get generations;
  @override
  Set<String> get typeIds;
  @override
  TypeMatchMode get typeMatchMode;
  @override
  Set<int> get pokedexIds;
  @override
  int? get dexMin;
  @override
  int? get dexMax;
  @override
  Set<SpecialTag> get tags;

  /// Create a copy of FilterState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FilterStateImplCopyWith<_$FilterStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
