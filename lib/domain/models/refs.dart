import 'package:freezed_annotation/freezed_annotation.dart';

part 'refs.freezed.dart';

/// 属性引用（architecture.md §3，字段锁死）。
///
/// [id] 即 identifier（如 "fire"）。
@freezed
class TypeRef with _$TypeRef {
  const factory TypeRef({
    required String id,
    required String nameZh,
  }) = _TypeRef;
}

/// 世代引用（architecture.md §3，字段锁死）。
@freezed
class GenerationRef with _$GenerationRef {
  const factory GenerationRef({
    required int id,
    required String identifier,
    required String region,
  }) = _GenerationRef;
}

/// 图鉴（地区）引用（architecture.md §3，字段锁死）。
@freezed
class PokedexRef with _$PokedexRef {
  const factory PokedexRef({
    required int id,
    required String identifier,
    required String nameZh,
    int? generationId,
  }) = _PokedexRef;
}

/// 版本组引用（architecture.md §3，字段锁死）。
@freezed
class VersionGroupRef with _$VersionGroupRef {
  const factory VersionGroupRef({
    required String id,
    required String labelZh,
    required int generationId,
  }) = _VersionGroupRef;
}
