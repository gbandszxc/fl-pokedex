// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stat_block.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$StatBlock {
  int get hp => throw _privateConstructorUsedError;
  int get attack => throw _privateConstructorUsedError;
  int get defense => throw _privateConstructorUsedError;
  int get specialAttack => throw _privateConstructorUsedError;
  int get specialDefense => throw _privateConstructorUsedError;
  int get speed => throw _privateConstructorUsedError;

  /// Create a copy of StatBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StatBlockCopyWith<StatBlock> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StatBlockCopyWith<$Res> {
  factory $StatBlockCopyWith(StatBlock value, $Res Function(StatBlock) then) =
      _$StatBlockCopyWithImpl<$Res, StatBlock>;
  @useResult
  $Res call(
      {int hp,
      int attack,
      int defense,
      int specialAttack,
      int specialDefense,
      int speed});
}

/// @nodoc
class _$StatBlockCopyWithImpl<$Res, $Val extends StatBlock>
    implements $StatBlockCopyWith<$Res> {
  _$StatBlockCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StatBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hp = null,
    Object? attack = null,
    Object? defense = null,
    Object? specialAttack = null,
    Object? specialDefense = null,
    Object? speed = null,
  }) {
    return _then(_value.copyWith(
      hp: null == hp
          ? _value.hp
          : hp // ignore: cast_nullable_to_non_nullable
              as int,
      attack: null == attack
          ? _value.attack
          : attack // ignore: cast_nullable_to_non_nullable
              as int,
      defense: null == defense
          ? _value.defense
          : defense // ignore: cast_nullable_to_non_nullable
              as int,
      specialAttack: null == specialAttack
          ? _value.specialAttack
          : specialAttack // ignore: cast_nullable_to_non_nullable
              as int,
      specialDefense: null == specialDefense
          ? _value.specialDefense
          : specialDefense // ignore: cast_nullable_to_non_nullable
              as int,
      speed: null == speed
          ? _value.speed
          : speed // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StatBlockImplCopyWith<$Res>
    implements $StatBlockCopyWith<$Res> {
  factory _$$StatBlockImplCopyWith(
          _$StatBlockImpl value, $Res Function(_$StatBlockImpl) then) =
      __$$StatBlockImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int hp,
      int attack,
      int defense,
      int specialAttack,
      int specialDefense,
      int speed});
}

/// @nodoc
class __$$StatBlockImplCopyWithImpl<$Res>
    extends _$StatBlockCopyWithImpl<$Res, _$StatBlockImpl>
    implements _$$StatBlockImplCopyWith<$Res> {
  __$$StatBlockImplCopyWithImpl(
      _$StatBlockImpl _value, $Res Function(_$StatBlockImpl) _then)
      : super(_value, _then);

  /// Create a copy of StatBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hp = null,
    Object? attack = null,
    Object? defense = null,
    Object? specialAttack = null,
    Object? specialDefense = null,
    Object? speed = null,
  }) {
    return _then(_$StatBlockImpl(
      hp: null == hp
          ? _value.hp
          : hp // ignore: cast_nullable_to_non_nullable
              as int,
      attack: null == attack
          ? _value.attack
          : attack // ignore: cast_nullable_to_non_nullable
              as int,
      defense: null == defense
          ? _value.defense
          : defense // ignore: cast_nullable_to_non_nullable
              as int,
      specialAttack: null == specialAttack
          ? _value.specialAttack
          : specialAttack // ignore: cast_nullable_to_non_nullable
              as int,
      specialDefense: null == specialDefense
          ? _value.specialDefense
          : specialDefense // ignore: cast_nullable_to_non_nullable
              as int,
      speed: null == speed
          ? _value.speed
          : speed // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$StatBlockImpl extends _StatBlock {
  const _$StatBlockImpl(
      {required this.hp,
      required this.attack,
      required this.defense,
      required this.specialAttack,
      required this.specialDefense,
      required this.speed})
      : super._();

  @override
  final int hp;
  @override
  final int attack;
  @override
  final int defense;
  @override
  final int specialAttack;
  @override
  final int specialDefense;
  @override
  final int speed;

  @override
  String toString() {
    return 'StatBlock(hp: $hp, attack: $attack, defense: $defense, specialAttack: $specialAttack, specialDefense: $specialDefense, speed: $speed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StatBlockImpl &&
            (identical(other.hp, hp) || other.hp == hp) &&
            (identical(other.attack, attack) || other.attack == attack) &&
            (identical(other.defense, defense) || other.defense == defense) &&
            (identical(other.specialAttack, specialAttack) ||
                other.specialAttack == specialAttack) &&
            (identical(other.specialDefense, specialDefense) ||
                other.specialDefense == specialDefense) &&
            (identical(other.speed, speed) || other.speed == speed));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, hp, attack, defense, specialAttack, specialDefense, speed);

  /// Create a copy of StatBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StatBlockImplCopyWith<_$StatBlockImpl> get copyWith =>
      __$$StatBlockImplCopyWithImpl<_$StatBlockImpl>(this, _$identity);
}

abstract class _StatBlock extends StatBlock {
  const factory _StatBlock(
      {required final int hp,
      required final int attack,
      required final int defense,
      required final int specialAttack,
      required final int specialDefense,
      required final int speed}) = _$StatBlockImpl;
  const _StatBlock._() : super._();

  @override
  int get hp;
  @override
  int get attack;
  @override
  int get defense;
  @override
  int get specialAttack;
  @override
  int get specialDefense;
  @override
  int get speed;

  /// Create a copy of StatBlock
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StatBlockImplCopyWith<_$StatBlockImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
