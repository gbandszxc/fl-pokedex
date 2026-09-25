// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manifest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DataManifestImpl _$$DataManifestImplFromJson(Map<String, dynamic> json) =>
    _$DataManifestImpl(
      schemaVersion: (json['schemaVersion'] as num).toInt(),
      dataVersion: json['dataVersion'] as String,
      pokemonCount: (json['pokemonCount'] as num).toInt(),
      formCount: (json['formCount'] as num).toInt(),
      moveCount: (json['moveCount'] as num).toInt(),
      abilityCount: (json['abilityCount'] as num).toInt(),
      versionCount: (json['versionCount'] as num).toInt(),
      buildDate: json['buildDate'] as String,
      upstreamRevision: json['upstreamRevision'] as Map<String, dynamic>,
      learnsetVersionGroups: (json['learnsetVersionGroups'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      missingArtwork: (json['missingArtwork'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$$DataManifestImplToJson(_$DataManifestImpl instance) =>
    <String, dynamic>{
      'schemaVersion': instance.schemaVersion,
      'dataVersion': instance.dataVersion,
      'pokemonCount': instance.pokemonCount,
      'formCount': instance.formCount,
      'moveCount': instance.moveCount,
      'abilityCount': instance.abilityCount,
      'versionCount': instance.versionCount,
      'buildDate': instance.buildDate,
      'upstreamRevision': instance.upstreamRevision,
      'learnsetVersionGroups': instance.learnsetVersionGroups,
      'missingArtwork': instance.missingArtwork,
    };
