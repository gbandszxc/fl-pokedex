// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'form_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$FormSummary {
  int get formId => throw _privateConstructorUsedError;
  int get speciesId => throw _privateConstructorUsedError;
  String? get formIdentifier => throw _privateConstructorUsedError;
  String get formNameZh => throw _privateConstructorUsedError;
  String get formNameEn => throw _privateConstructorUsedError;
  bool get isDefault => throw _privateConstructorUsedError;
  bool get isMega => throw _privateConstructorUsedError;
  bool get isGmax => throw _privateConstructorUsedError;
  bool get isRegional => throw _privateConstructorUsedError;
  String? get artworkAsset => throw _privateConstructorUsedError;
  List<String> get typeIds => throw _privateConstructorUsedError;

  /// 身高（米）= forms.height ÷ 10；上游缺失为 null。
  double? get heightM => throw _privateConstructorUsedError;

  /// 体重（千克）= forms.weight ÷ 10；上游缺失为 null。
  double? get weightKg => throw _privateConstructorUsedError;

  /// Create a copy of FormSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FormSummaryCopyWith<FormSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FormSummaryCopyWith<$Res> {
  factory $FormSummaryCopyWith(
          FormSummary value, $Res Function(FormSummary) then) =
      _$FormSummaryCopyWithImpl<$Res, FormSummary>;
  @useResult
  $Res call(
      {int formId,
      int speciesId,
      String? formIdentifier,
      String formNameZh,
      String formNameEn,
      bool isDefault,
      bool isMega,
      bool isGmax,
      bool isRegional,
      String? artworkAsset,
      List<String> typeIds,
      double? heightM,
      double? weightKg});
}

/// @nodoc
class _$FormSummaryCopyWithImpl<$Res, $Val extends FormSummary>
    implements $FormSummaryCopyWith<$Res> {
  _$FormSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FormSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? formId = null,
    Object? speciesId = null,
    Object? formIdentifier = freezed,
    Object? formNameZh = null,
    Object? formNameEn = null,
    Object? isDefault = null,
    Object? isMega = null,
    Object? isGmax = null,
    Object? isRegional = null,
    Object? artworkAsset = freezed,
    Object? typeIds = null,
    Object? heightM = freezed,
    Object? weightKg = freezed,
  }) {
    return _then(_value.copyWith(
      formId: null == formId
          ? _value.formId
          : formId // ignore: cast_nullable_to_non_nullable
              as int,
      speciesId: null == speciesId
          ? _value.speciesId
          : speciesId // ignore: cast_nullable_to_non_nullable
              as int,
      formIdentifier: freezed == formIdentifier
          ? _value.formIdentifier
          : formIdentifier // ignore: cast_nullable_to_non_nullable
              as String?,
      formNameZh: null == formNameZh
          ? _value.formNameZh
          : formNameZh // ignore: cast_nullable_to_non_nullable
              as String,
      formNameEn: null == formNameEn
          ? _value.formNameEn
          : formNameEn // ignore: cast_nullable_to_non_nullable
              as String,
      isDefault: null == isDefault
          ? _value.isDefault
          : isDefault // ignore: cast_nullable_to_non_nullable
              as bool,
      isMega: null == isMega
          ? _value.isMega
          : isMega // ignore: cast_nullable_to_non_nullable
              as bool,
      isGmax: null == isGmax
          ? _value.isGmax
          : isGmax // ignore: cast_nullable_to_non_nullable
              as bool,
      isRegional: null == isRegional
          ? _value.isRegional
          : isRegional // ignore: cast_nullable_to_non_nullable
              as bool,
      artworkAsset: freezed == artworkAsset
          ? _value.artworkAsset
          : artworkAsset // ignore: cast_nullable_to_non_nullable
              as String?,
      typeIds: null == typeIds
          ? _value.typeIds
          : typeIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      heightM: freezed == heightM
          ? _value.heightM
          : heightM // ignore: cast_nullable_to_non_nullable
              as double?,
      weightKg: freezed == weightKg
          ? _value.weightKg
          : weightKg // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FormSummaryImplCopyWith<$Res>
    implements $FormSummaryCopyWith<$Res> {
  factory _$$FormSummaryImplCopyWith(
          _$FormSummaryImpl value, $Res Function(_$FormSummaryImpl) then) =
      __$$FormSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int formId,
      int speciesId,
      String? formIdentifier,
      String formNameZh,
      String formNameEn,
      bool isDefault,
      bool isMega,
      bool isGmax,
      bool isRegional,
      String? artworkAsset,
      List<String> typeIds,
      double? heightM,
      double? weightKg});
}

/// @nodoc
class __$$FormSummaryImplCopyWithImpl<$Res>
    extends _$FormSummaryCopyWithImpl<$Res, _$FormSummaryImpl>
    implements _$$FormSummaryImplCopyWith<$Res> {
  __$$FormSummaryImplCopyWithImpl(
      _$FormSummaryImpl _value, $Res Function(_$FormSummaryImpl) _then)
      : super(_value, _then);

  /// Create a copy of FormSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? formId = null,
    Object? speciesId = null,
    Object? formIdentifier = freezed,
    Object? formNameZh = null,
    Object? formNameEn = null,
    Object? isDefault = null,
    Object? isMega = null,
    Object? isGmax = null,
    Object? isRegional = null,
    Object? artworkAsset = freezed,
    Object? typeIds = null,
    Object? heightM = freezed,
    Object? weightKg = freezed,
  }) {
    return _then(_$FormSummaryImpl(
      formId: null == formId
          ? _value.formId
          : formId // ignore: cast_nullable_to_non_nullable
              as int,
      speciesId: null == speciesId
          ? _value.speciesId
          : speciesId // ignore: cast_nullable_to_non_nullable
              as int,
      formIdentifier: freezed == formIdentifier
          ? _value.formIdentifier
          : formIdentifier // ignore: cast_nullable_to_non_nullable
              as String?,
      formNameZh: null == formNameZh
          ? _value.formNameZh
          : formNameZh // ignore: cast_nullable_to_non_nullable
              as String,
      formNameEn: null == formNameEn
          ? _value.formNameEn
          : formNameEn // ignore: cast_nullable_to_non_nullable
              as String,
      isDefault: null == isDefault
          ? _value.isDefault
          : isDefault // ignore: cast_nullable_to_non_nullable
              as bool,
      isMega: null == isMega
          ? _value.isMega
          : isMega // ignore: cast_nullable_to_non_nullable
              as bool,
      isGmax: null == isGmax
          ? _value.isGmax
          : isGmax // ignore: cast_nullable_to_non_nullable
              as bool,
      isRegional: null == isRegional
          ? _value.isRegional
          : isRegional // ignore: cast_nullable_to_non_nullable
              as bool,
      artworkAsset: freezed == artworkAsset
          ? _value.artworkAsset
          : artworkAsset // ignore: cast_nullable_to_non_nullable
              as String?,
      typeIds: null == typeIds
          ? _value._typeIds
          : typeIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      heightM: freezed == heightM
          ? _value.heightM
          : heightM // ignore: cast_nullable_to_non_nullable
              as double?,
      weightKg: freezed == weightKg
          ? _value.weightKg
          : weightKg // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc

class _$FormSummaryImpl implements _FormSummary {
  const _$FormSummaryImpl(
      {required this.formId,
      required this.speciesId,
      this.formIdentifier,
      required this.formNameZh,
      required this.formNameEn,
      required this.isDefault,
      required this.isMega,
      required this.isGmax,
      required this.isRegional,
      this.artworkAsset,
      required final List<String> typeIds,
      this.heightM,
      this.weightKg})
      : _typeIds = typeIds;

  @override
  final int formId;
  @override
  final int speciesId;
  @override
  final String? formIdentifier;
  @override
  final String formNameZh;
  @override
  final String formNameEn;
  @override
  final bool isDefault;
  @override
  final bool isMega;
  @override
  final bool isGmax;
  @override
  final bool isRegional;
  @override
  final String? artworkAsset;
  final List<String> _typeIds;
  @override
  List<String> get typeIds {
    if (_typeIds is EqualUnmodifiableListView) return _typeIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_typeIds);
  }

  /// 身高（米）= forms.height ÷ 10；上游缺失为 null。
  @override
  final double? heightM;

  /// 体重（千克）= forms.weight ÷ 10；上游缺失为 null。
  @override
  final double? weightKg;

  @override
  String toString() {
    return 'FormSummary(formId: $formId, speciesId: $speciesId, formIdentifier: $formIdentifier, formNameZh: $formNameZh, formNameEn: $formNameEn, isDefault: $isDefault, isMega: $isMega, isGmax: $isGmax, isRegional: $isRegional, artworkAsset: $artworkAsset, typeIds: $typeIds, heightM: $heightM, weightKg: $weightKg)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FormSummaryImpl &&
            (identical(other.formId, formId) || other.formId == formId) &&
            (identical(other.speciesId, speciesId) ||
                other.speciesId == speciesId) &&
            (identical(other.formIdentifier, formIdentifier) ||
                other.formIdentifier == formIdentifier) &&
            (identical(other.formNameZh, formNameZh) ||
                other.formNameZh == formNameZh) &&
            (identical(other.formNameEn, formNameEn) ||
                other.formNameEn == formNameEn) &&
            (identical(other.isDefault, isDefault) ||
                other.isDefault == isDefault) &&
            (identical(other.isMega, isMega) || other.isMega == isMega) &&
            (identical(other.isGmax, isGmax) || other.isGmax == isGmax) &&
            (identical(other.isRegional, isRegional) ||
                other.isRegional == isRegional) &&
            (identical(other.artworkAsset, artworkAsset) ||
                other.artworkAsset == artworkAsset) &&
            const DeepCollectionEquality().equals(other._typeIds, _typeIds) &&
            (identical(other.heightM, heightM) || other.heightM == heightM) &&
            (identical(other.weightKg, weightKg) ||
                other.weightKg == weightKg));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      formId,
      speciesId,
      formIdentifier,
      formNameZh,
      formNameEn,
      isDefault,
      isMega,
      isGmax,
      isRegional,
      artworkAsset,
      const DeepCollectionEquality().hash(_typeIds),
      heightM,
      weightKg);

  /// Create a copy of FormSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FormSummaryImplCopyWith<_$FormSummaryImpl> get copyWith =>
      __$$FormSummaryImplCopyWithImpl<_$FormSummaryImpl>(this, _$identity);
}

abstract class _FormSummary implements FormSummary {
  const factory _FormSummary(
      {required final int formId,
      required final int speciesId,
      final String? formIdentifier,
      required final String formNameZh,
      required final String formNameEn,
      required final bool isDefault,
      required final bool isMega,
      required final bool isGmax,
      required final bool isRegional,
      final String? artworkAsset,
      required final List<String> typeIds,
      final double? heightM,
      final double? weightKg}) = _$FormSummaryImpl;

  @override
  int get formId;
  @override
  int get speciesId;
  @override
  String? get formIdentifier;
  @override
  String get formNameZh;
  @override
  String get formNameEn;
  @override
  bool get isDefault;
  @override
  bool get isMega;
  @override
  bool get isGmax;
  @override
  bool get isRegional;
  @override
  String? get artworkAsset;
  @override
  List<String> get typeIds;

  /// 身高（米）= forms.height ÷ 10；上游缺失为 null。
  @override
  double? get heightM;

  /// 体重（千克）= forms.weight ÷ 10；上游缺失为 null。
  @override
  double? get weightKg;

  /// Create a copy of FormSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FormSummaryImplCopyWith<_$FormSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
