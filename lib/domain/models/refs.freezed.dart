// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'refs.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TypeRef {
  String get id => throw _privateConstructorUsedError;
  String get nameZh => throw _privateConstructorUsedError;

  /// Create a copy of TypeRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TypeRefCopyWith<TypeRef> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TypeRefCopyWith<$Res> {
  factory $TypeRefCopyWith(TypeRef value, $Res Function(TypeRef) then) =
      _$TypeRefCopyWithImpl<$Res, TypeRef>;
  @useResult
  $Res call({String id, String nameZh});
}

/// @nodoc
class _$TypeRefCopyWithImpl<$Res, $Val extends TypeRef>
    implements $TypeRefCopyWith<$Res> {
  _$TypeRefCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TypeRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nameZh = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      nameZh: null == nameZh
          ? _value.nameZh
          : nameZh // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TypeRefImplCopyWith<$Res> implements $TypeRefCopyWith<$Res> {
  factory _$$TypeRefImplCopyWith(
          _$TypeRefImpl value, $Res Function(_$TypeRefImpl) then) =
      __$$TypeRefImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String nameZh});
}

/// @nodoc
class __$$TypeRefImplCopyWithImpl<$Res>
    extends _$TypeRefCopyWithImpl<$Res, _$TypeRefImpl>
    implements _$$TypeRefImplCopyWith<$Res> {
  __$$TypeRefImplCopyWithImpl(
      _$TypeRefImpl _value, $Res Function(_$TypeRefImpl) _then)
      : super(_value, _then);

  /// Create a copy of TypeRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nameZh = null,
  }) {
    return _then(_$TypeRefImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      nameZh: null == nameZh
          ? _value.nameZh
          : nameZh // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$TypeRefImpl implements _TypeRef {
  const _$TypeRefImpl({required this.id, required this.nameZh});

  @override
  final String id;
  @override
  final String nameZh;

  @override
  String toString() {
    return 'TypeRef(id: $id, nameZh: $nameZh)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TypeRefImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nameZh, nameZh) || other.nameZh == nameZh));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, nameZh);

  /// Create a copy of TypeRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TypeRefImplCopyWith<_$TypeRefImpl> get copyWith =>
      __$$TypeRefImplCopyWithImpl<_$TypeRefImpl>(this, _$identity);
}

abstract class _TypeRef implements TypeRef {
  const factory _TypeRef(
      {required final String id, required final String nameZh}) = _$TypeRefImpl;

  @override
  String get id;
  @override
  String get nameZh;

  /// Create a copy of TypeRef
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TypeRefImplCopyWith<_$TypeRefImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$GenerationRef {
  int get id => throw _privateConstructorUsedError;
  String get identifier => throw _privateConstructorUsedError;
  String get region => throw _privateConstructorUsedError;

  /// Create a copy of GenerationRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GenerationRefCopyWith<GenerationRef> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GenerationRefCopyWith<$Res> {
  factory $GenerationRefCopyWith(
          GenerationRef value, $Res Function(GenerationRef) then) =
      _$GenerationRefCopyWithImpl<$Res, GenerationRef>;
  @useResult
  $Res call({int id, String identifier, String region});
}

/// @nodoc
class _$GenerationRefCopyWithImpl<$Res, $Val extends GenerationRef>
    implements $GenerationRefCopyWith<$Res> {
  _$GenerationRefCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GenerationRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? identifier = null,
    Object? region = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      identifier: null == identifier
          ? _value.identifier
          : identifier // ignore: cast_nullable_to_non_nullable
              as String,
      region: null == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GenerationRefImplCopyWith<$Res>
    implements $GenerationRefCopyWith<$Res> {
  factory _$$GenerationRefImplCopyWith(
          _$GenerationRefImpl value, $Res Function(_$GenerationRefImpl) then) =
      __$$GenerationRefImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String identifier, String region});
}

/// @nodoc
class __$$GenerationRefImplCopyWithImpl<$Res>
    extends _$GenerationRefCopyWithImpl<$Res, _$GenerationRefImpl>
    implements _$$GenerationRefImplCopyWith<$Res> {
  __$$GenerationRefImplCopyWithImpl(
      _$GenerationRefImpl _value, $Res Function(_$GenerationRefImpl) _then)
      : super(_value, _then);

  /// Create a copy of GenerationRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? identifier = null,
    Object? region = null,
  }) {
    return _then(_$GenerationRefImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      identifier: null == identifier
          ? _value.identifier
          : identifier // ignore: cast_nullable_to_non_nullable
              as String,
      region: null == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$GenerationRefImpl implements _GenerationRef {
  const _$GenerationRefImpl(
      {required this.id, required this.identifier, required this.region});

  @override
  final int id;
  @override
  final String identifier;
  @override
  final String region;

  @override
  String toString() {
    return 'GenerationRef(id: $id, identifier: $identifier, region: $region)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GenerationRefImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.identifier, identifier) ||
                other.identifier == identifier) &&
            (identical(other.region, region) || other.region == region));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, identifier, region);

  /// Create a copy of GenerationRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GenerationRefImplCopyWith<_$GenerationRefImpl> get copyWith =>
      __$$GenerationRefImplCopyWithImpl<_$GenerationRefImpl>(this, _$identity);
}

abstract class _GenerationRef implements GenerationRef {
  const factory _GenerationRef(
      {required final int id,
      required final String identifier,
      required final String region}) = _$GenerationRefImpl;

  @override
  int get id;
  @override
  String get identifier;
  @override
  String get region;

  /// Create a copy of GenerationRef
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GenerationRefImplCopyWith<_$GenerationRefImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$PokedexRef {
  int get id => throw _privateConstructorUsedError;
  String get identifier => throw _privateConstructorUsedError;
  String get nameZh => throw _privateConstructorUsedError;
  int? get generationId => throw _privateConstructorUsedError;

  /// Create a copy of PokedexRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PokedexRefCopyWith<PokedexRef> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PokedexRefCopyWith<$Res> {
  factory $PokedexRefCopyWith(
          PokedexRef value, $Res Function(PokedexRef) then) =
      _$PokedexRefCopyWithImpl<$Res, PokedexRef>;
  @useResult
  $Res call({int id, String identifier, String nameZh, int? generationId});
}

/// @nodoc
class _$PokedexRefCopyWithImpl<$Res, $Val extends PokedexRef>
    implements $PokedexRefCopyWith<$Res> {
  _$PokedexRefCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PokedexRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? identifier = null,
    Object? nameZh = null,
    Object? generationId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      identifier: null == identifier
          ? _value.identifier
          : identifier // ignore: cast_nullable_to_non_nullable
              as String,
      nameZh: null == nameZh
          ? _value.nameZh
          : nameZh // ignore: cast_nullable_to_non_nullable
              as String,
      generationId: freezed == generationId
          ? _value.generationId
          : generationId // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PokedexRefImplCopyWith<$Res>
    implements $PokedexRefCopyWith<$Res> {
  factory _$$PokedexRefImplCopyWith(
          _$PokedexRefImpl value, $Res Function(_$PokedexRefImpl) then) =
      __$$PokedexRefImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String identifier, String nameZh, int? generationId});
}

/// @nodoc
class __$$PokedexRefImplCopyWithImpl<$Res>
    extends _$PokedexRefCopyWithImpl<$Res, _$PokedexRefImpl>
    implements _$$PokedexRefImplCopyWith<$Res> {
  __$$PokedexRefImplCopyWithImpl(
      _$PokedexRefImpl _value, $Res Function(_$PokedexRefImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokedexRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? identifier = null,
    Object? nameZh = null,
    Object? generationId = freezed,
  }) {
    return _then(_$PokedexRefImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      identifier: null == identifier
          ? _value.identifier
          : identifier // ignore: cast_nullable_to_non_nullable
              as String,
      nameZh: null == nameZh
          ? _value.nameZh
          : nameZh // ignore: cast_nullable_to_non_nullable
              as String,
      generationId: freezed == generationId
          ? _value.generationId
          : generationId // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

class _$PokedexRefImpl implements _PokedexRef {
  const _$PokedexRefImpl(
      {required this.id,
      required this.identifier,
      required this.nameZh,
      this.generationId});

  @override
  final int id;
  @override
  final String identifier;
  @override
  final String nameZh;
  @override
  final int? generationId;

  @override
  String toString() {
    return 'PokedexRef(id: $id, identifier: $identifier, nameZh: $nameZh, generationId: $generationId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokedexRefImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.identifier, identifier) ||
                other.identifier == identifier) &&
            (identical(other.nameZh, nameZh) || other.nameZh == nameZh) &&
            (identical(other.generationId, generationId) ||
                other.generationId == generationId));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, identifier, nameZh, generationId);

  /// Create a copy of PokedexRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokedexRefImplCopyWith<_$PokedexRefImpl> get copyWith =>
      __$$PokedexRefImplCopyWithImpl<_$PokedexRefImpl>(this, _$identity);
}

abstract class _PokedexRef implements PokedexRef {
  const factory _PokedexRef(
      {required final int id,
      required final String identifier,
      required final String nameZh,
      final int? generationId}) = _$PokedexRefImpl;

  @override
  int get id;
  @override
  String get identifier;
  @override
  String get nameZh;
  @override
  int? get generationId;

  /// Create a copy of PokedexRef
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokedexRefImplCopyWith<_$PokedexRefImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$VersionGroupRef {
  String get id => throw _privateConstructorUsedError;
  String get labelZh => throw _privateConstructorUsedError;
  int get generationId => throw _privateConstructorUsedError;

  /// Create a copy of VersionGroupRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VersionGroupRefCopyWith<VersionGroupRef> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VersionGroupRefCopyWith<$Res> {
  factory $VersionGroupRefCopyWith(
          VersionGroupRef value, $Res Function(VersionGroupRef) then) =
      _$VersionGroupRefCopyWithImpl<$Res, VersionGroupRef>;
  @useResult
  $Res call({String id, String labelZh, int generationId});
}

/// @nodoc
class _$VersionGroupRefCopyWithImpl<$Res, $Val extends VersionGroupRef>
    implements $VersionGroupRefCopyWith<$Res> {
  _$VersionGroupRefCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VersionGroupRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? labelZh = null,
    Object? generationId = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      labelZh: null == labelZh
          ? _value.labelZh
          : labelZh // ignore: cast_nullable_to_non_nullable
              as String,
      generationId: null == generationId
          ? _value.generationId
          : generationId // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VersionGroupRefImplCopyWith<$Res>
    implements $VersionGroupRefCopyWith<$Res> {
  factory _$$VersionGroupRefImplCopyWith(_$VersionGroupRefImpl value,
          $Res Function(_$VersionGroupRefImpl) then) =
      __$$VersionGroupRefImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String labelZh, int generationId});
}

/// @nodoc
class __$$VersionGroupRefImplCopyWithImpl<$Res>
    extends _$VersionGroupRefCopyWithImpl<$Res, _$VersionGroupRefImpl>
    implements _$$VersionGroupRefImplCopyWith<$Res> {
  __$$VersionGroupRefImplCopyWithImpl(
      _$VersionGroupRefImpl _value, $Res Function(_$VersionGroupRefImpl) _then)
      : super(_value, _then);

  /// Create a copy of VersionGroupRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? labelZh = null,
    Object? generationId = null,
  }) {
    return _then(_$VersionGroupRefImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      labelZh: null == labelZh
          ? _value.labelZh
          : labelZh // ignore: cast_nullable_to_non_nullable
              as String,
      generationId: null == generationId
          ? _value.generationId
          : generationId // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$VersionGroupRefImpl implements _VersionGroupRef {
  const _$VersionGroupRefImpl(
      {required this.id, required this.labelZh, required this.generationId});

  @override
  final String id;
  @override
  final String labelZh;
  @override
  final int generationId;

  @override
  String toString() {
    return 'VersionGroupRef(id: $id, labelZh: $labelZh, generationId: $generationId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VersionGroupRefImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.labelZh, labelZh) || other.labelZh == labelZh) &&
            (identical(other.generationId, generationId) ||
                other.generationId == generationId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, labelZh, generationId);

  /// Create a copy of VersionGroupRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VersionGroupRefImplCopyWith<_$VersionGroupRefImpl> get copyWith =>
      __$$VersionGroupRefImplCopyWithImpl<_$VersionGroupRefImpl>(
          this, _$identity);
}

abstract class _VersionGroupRef implements VersionGroupRef {
  const factory _VersionGroupRef(
      {required final String id,
      required final String labelZh,
      required final int generationId}) = _$VersionGroupRefImpl;

  @override
  String get id;
  @override
  String get labelZh;
  @override
  int get generationId;

  /// Create a copy of VersionGroupRef
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VersionGroupRefImplCopyWith<_$VersionGroupRefImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
