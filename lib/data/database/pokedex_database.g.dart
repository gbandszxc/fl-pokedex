// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pokedex_database.dart';

// ignore_for_file: type=lint
class $MetaTable extends Meta with TableInfo<$MetaTable, MetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meta';
  @override
  VerificationContext validateIntegrity(Insertable<MetaRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  MetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetaRow(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $MetaTable createAlias(String alias) {
    return $MetaTable(attachedDatabase, alias);
  }
}

class MetaRow extends DataClass implements Insertable<MetaRow> {
  final String key;
  final String value;
  const MetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  MetaCompanion toCompanion(bool nullToAbsent) {
    return MetaCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory MetaRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  MetaRow copyWith({String? key, String? value}) => MetaRow(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  MetaRow copyWithCompanion(MetaCompanion data) {
    return MetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetaRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetaRow && other.key == this.key && other.value == this.value);
}

class MetaCompanion extends UpdateCompanion<MetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const MetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<MetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetaCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return MetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GenerationsTable extends Generations
    with TableInfo<$GenerationsTable, GenerationsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GenerationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _identifierMeta =
      const VerificationMeta('identifier');
  @override
  late final GeneratedColumn<String> identifier = GeneratedColumn<String>(
      'identifier', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
      'region', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, identifier, region];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'generations';
  @override
  VerificationContext validateIntegrity(Insertable<GenerationsRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('identifier')) {
      context.handle(
          _identifierMeta,
          identifier.isAcceptableOrUnknown(
              data['identifier']!, _identifierMeta));
    } else if (isInserting) {
      context.missing(_identifierMeta);
    }
    if (data.containsKey('region')) {
      context.handle(_regionMeta,
          region.isAcceptableOrUnknown(data['region']!, _regionMeta));
    } else if (isInserting) {
      context.missing(_regionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  GenerationsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GenerationsRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      identifier: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}identifier'])!,
      region: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}region'])!,
    );
  }

  @override
  $GenerationsTable createAlias(String alias) {
    return $GenerationsTable(attachedDatabase, alias);
  }
}

class GenerationsRow extends DataClass implements Insertable<GenerationsRow> {
  final int id;
  final String identifier;
  final String region;
  const GenerationsRow(
      {required this.id, required this.identifier, required this.region});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['identifier'] = Variable<String>(identifier);
    map['region'] = Variable<String>(region);
    return map;
  }

  GenerationsCompanion toCompanion(bool nullToAbsent) {
    return GenerationsCompanion(
      id: Value(id),
      identifier: Value(identifier),
      region: Value(region),
    );
  }

  factory GenerationsRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GenerationsRow(
      id: serializer.fromJson<int>(json['id']),
      identifier: serializer.fromJson<String>(json['identifier']),
      region: serializer.fromJson<String>(json['region']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'identifier': serializer.toJson<String>(identifier),
      'region': serializer.toJson<String>(region),
    };
  }

  GenerationsRow copyWith({int? id, String? identifier, String? region}) =>
      GenerationsRow(
        id: id ?? this.id,
        identifier: identifier ?? this.identifier,
        region: region ?? this.region,
      );
  GenerationsRow copyWithCompanion(GenerationsCompanion data) {
    return GenerationsRow(
      id: data.id.present ? data.id.value : this.id,
      identifier:
          data.identifier.present ? data.identifier.value : this.identifier,
      region: data.region.present ? data.region.value : this.region,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GenerationsRow(')
          ..write('id: $id, ')
          ..write('identifier: $identifier, ')
          ..write('region: $region')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, identifier, region);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GenerationsRow &&
          other.id == this.id &&
          other.identifier == this.identifier &&
          other.region == this.region);
}

class GenerationsCompanion extends UpdateCompanion<GenerationsRow> {
  final Value<int> id;
  final Value<String> identifier;
  final Value<String> region;
  final Value<int> rowid;
  const GenerationsCompanion({
    this.id = const Value.absent(),
    this.identifier = const Value.absent(),
    this.region = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GenerationsCompanion.insert({
    required int id,
    required String identifier,
    required String region,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        identifier = Value(identifier),
        region = Value(region);
  static Insertable<GenerationsRow> custom({
    Expression<int>? id,
    Expression<String>? identifier,
    Expression<String>? region,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (identifier != null) 'identifier': identifier,
      if (region != null) 'region': region,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GenerationsCompanion copyWith(
      {Value<int>? id,
      Value<String>? identifier,
      Value<String>? region,
      Value<int>? rowid}) {
    return GenerationsCompanion(
      id: id ?? this.id,
      identifier: identifier ?? this.identifier,
      region: region ?? this.region,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (identifier.present) {
      map['identifier'] = Variable<String>(identifier.value);
    }
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GenerationsCompanion(')
          ..write('id: $id, ')
          ..write('identifier: $identifier, ')
          ..write('region: $region, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TypesTable extends Types with TableInfo<$TypesTable, TypesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _identifierMeta =
      const VerificationMeta('identifier');
  @override
  late final GeneratedColumn<String> identifier = GeneratedColumn<String>(
      'identifier', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameZhHansMeta =
      const VerificationMeta('nameZhHans');
  @override
  late final GeneratedColumn<String> nameZhHans = GeneratedColumn<String>(
      'name_zh_hans', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameZhHantMeta =
      const VerificationMeta('nameZhHant');
  @override
  late final GeneratedColumn<String> nameZhHant = GeneratedColumn<String>(
      'name_zh_hant', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
      'name_en', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameJaMeta = const VerificationMeta('nameJa');
  @override
  late final GeneratedColumn<String> nameJa = GeneratedColumn<String>(
      'name_ja', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, identifier, nameZhHans, nameZhHant, nameEn, nameJa];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'types';
  @override
  VerificationContext validateIntegrity(Insertable<TypesRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('identifier')) {
      context.handle(
          _identifierMeta,
          identifier.isAcceptableOrUnknown(
              data['identifier']!, _identifierMeta));
    } else if (isInserting) {
      context.missing(_identifierMeta);
    }
    if (data.containsKey('name_zh_hans')) {
      context.handle(
          _nameZhHansMeta,
          nameZhHans.isAcceptableOrUnknown(
              data['name_zh_hans']!, _nameZhHansMeta));
    } else if (isInserting) {
      context.missing(_nameZhHansMeta);
    }
    if (data.containsKey('name_zh_hant')) {
      context.handle(
          _nameZhHantMeta,
          nameZhHant.isAcceptableOrUnknown(
              data['name_zh_hant']!, _nameZhHantMeta));
    } else if (isInserting) {
      context.missing(_nameZhHantMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(_nameEnMeta,
          nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta));
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('name_ja')) {
      context.handle(_nameJaMeta,
          nameJa.isAcceptableOrUnknown(data['name_ja']!, _nameJaMeta));
    } else if (isInserting) {
      context.missing(_nameJaMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  TypesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TypesRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      identifier: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}identifier'])!,
      nameZhHans: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_zh_hans'])!,
      nameZhHant: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_zh_hant'])!,
      nameEn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_en'])!,
      nameJa: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_ja'])!,
    );
  }

  @override
  $TypesTable createAlias(String alias) {
    return $TypesTable(attachedDatabase, alias);
  }
}

class TypesRow extends DataClass implements Insertable<TypesRow> {
  final int id;
  final String identifier;
  final String nameZhHans;
  final String nameZhHant;
  final String nameEn;
  final String nameJa;
  const TypesRow(
      {required this.id,
      required this.identifier,
      required this.nameZhHans,
      required this.nameZhHant,
      required this.nameEn,
      required this.nameJa});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['identifier'] = Variable<String>(identifier);
    map['name_zh_hans'] = Variable<String>(nameZhHans);
    map['name_zh_hant'] = Variable<String>(nameZhHant);
    map['name_en'] = Variable<String>(nameEn);
    map['name_ja'] = Variable<String>(nameJa);
    return map;
  }

  TypesCompanion toCompanion(bool nullToAbsent) {
    return TypesCompanion(
      id: Value(id),
      identifier: Value(identifier),
      nameZhHans: Value(nameZhHans),
      nameZhHant: Value(nameZhHant),
      nameEn: Value(nameEn),
      nameJa: Value(nameJa),
    );
  }

  factory TypesRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TypesRow(
      id: serializer.fromJson<int>(json['id']),
      identifier: serializer.fromJson<String>(json['identifier']),
      nameZhHans: serializer.fromJson<String>(json['nameZhHans']),
      nameZhHant: serializer.fromJson<String>(json['nameZhHant']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      nameJa: serializer.fromJson<String>(json['nameJa']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'identifier': serializer.toJson<String>(identifier),
      'nameZhHans': serializer.toJson<String>(nameZhHans),
      'nameZhHant': serializer.toJson<String>(nameZhHant),
      'nameEn': serializer.toJson<String>(nameEn),
      'nameJa': serializer.toJson<String>(nameJa),
    };
  }

  TypesRow copyWith(
          {int? id,
          String? identifier,
          String? nameZhHans,
          String? nameZhHant,
          String? nameEn,
          String? nameJa}) =>
      TypesRow(
        id: id ?? this.id,
        identifier: identifier ?? this.identifier,
        nameZhHans: nameZhHans ?? this.nameZhHans,
        nameZhHant: nameZhHant ?? this.nameZhHant,
        nameEn: nameEn ?? this.nameEn,
        nameJa: nameJa ?? this.nameJa,
      );
  TypesRow copyWithCompanion(TypesCompanion data) {
    return TypesRow(
      id: data.id.present ? data.id.value : this.id,
      identifier:
          data.identifier.present ? data.identifier.value : this.identifier,
      nameZhHans:
          data.nameZhHans.present ? data.nameZhHans.value : this.nameZhHans,
      nameZhHant:
          data.nameZhHant.present ? data.nameZhHant.value : this.nameZhHant,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      nameJa: data.nameJa.present ? data.nameJa.value : this.nameJa,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TypesRow(')
          ..write('id: $id, ')
          ..write('identifier: $identifier, ')
          ..write('nameZhHans: $nameZhHans, ')
          ..write('nameZhHant: $nameZhHant, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameJa: $nameJa')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, identifier, nameZhHans, nameZhHant, nameEn, nameJa);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TypesRow &&
          other.id == this.id &&
          other.identifier == this.identifier &&
          other.nameZhHans == this.nameZhHans &&
          other.nameZhHant == this.nameZhHant &&
          other.nameEn == this.nameEn &&
          other.nameJa == this.nameJa);
}

class TypesCompanion extends UpdateCompanion<TypesRow> {
  final Value<int> id;
  final Value<String> identifier;
  final Value<String> nameZhHans;
  final Value<String> nameZhHant;
  final Value<String> nameEn;
  final Value<String> nameJa;
  final Value<int> rowid;
  const TypesCompanion({
    this.id = const Value.absent(),
    this.identifier = const Value.absent(),
    this.nameZhHans = const Value.absent(),
    this.nameZhHant = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.nameJa = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TypesCompanion.insert({
    required int id,
    required String identifier,
    required String nameZhHans,
    required String nameZhHant,
    required String nameEn,
    required String nameJa,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        identifier = Value(identifier),
        nameZhHans = Value(nameZhHans),
        nameZhHant = Value(nameZhHant),
        nameEn = Value(nameEn),
        nameJa = Value(nameJa);
  static Insertable<TypesRow> custom({
    Expression<int>? id,
    Expression<String>? identifier,
    Expression<String>? nameZhHans,
    Expression<String>? nameZhHant,
    Expression<String>? nameEn,
    Expression<String>? nameJa,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (identifier != null) 'identifier': identifier,
      if (nameZhHans != null) 'name_zh_hans': nameZhHans,
      if (nameZhHant != null) 'name_zh_hant': nameZhHant,
      if (nameEn != null) 'name_en': nameEn,
      if (nameJa != null) 'name_ja': nameJa,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TypesCompanion copyWith(
      {Value<int>? id,
      Value<String>? identifier,
      Value<String>? nameZhHans,
      Value<String>? nameZhHant,
      Value<String>? nameEn,
      Value<String>? nameJa,
      Value<int>? rowid}) {
    return TypesCompanion(
      id: id ?? this.id,
      identifier: identifier ?? this.identifier,
      nameZhHans: nameZhHans ?? this.nameZhHans,
      nameZhHant: nameZhHant ?? this.nameZhHant,
      nameEn: nameEn ?? this.nameEn,
      nameJa: nameJa ?? this.nameJa,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (identifier.present) {
      map['identifier'] = Variable<String>(identifier.value);
    }
    if (nameZhHans.present) {
      map['name_zh_hans'] = Variable<String>(nameZhHans.value);
    }
    if (nameZhHant.present) {
      map['name_zh_hant'] = Variable<String>(nameZhHant.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (nameJa.present) {
      map['name_ja'] = Variable<String>(nameJa.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TypesCompanion(')
          ..write('id: $id, ')
          ..write('identifier: $identifier, ')
          ..write('nameZhHans: $nameZhHans, ')
          ..write('nameZhHant: $nameZhHant, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameJa: $nameJa, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AbilitiesTable extends Abilities
    with TableInfo<$AbilitiesTable, AbilitiesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AbilitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _identifierMeta =
      const VerificationMeta('identifier');
  @override
  late final GeneratedColumn<String> identifier = GeneratedColumn<String>(
      'identifier', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameZhHansMeta =
      const VerificationMeta('nameZhHans');
  @override
  late final GeneratedColumn<String> nameZhHans = GeneratedColumn<String>(
      'name_zh_hans', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
      'name_en', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameJaMeta = const VerificationMeta('nameJa');
  @override
  late final GeneratedColumn<String> nameJa = GeneratedColumn<String>(
      'name_ja', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _generationIdMeta =
      const VerificationMeta('generationId');
  @override
  late final GeneratedColumn<int> generationId = GeneratedColumn<int>(
      'generation_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _textZhHansMeta =
      const VerificationMeta('textZhHans');
  @override
  late final GeneratedColumn<String> textZhHans = GeneratedColumn<String>(
      'text_zh_hans', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _textEnMeta = const VerificationMeta('textEn');
  @override
  late final GeneratedColumn<String> textEn = GeneratedColumn<String>(
      'text_en', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        identifier,
        nameZhHans,
        nameEn,
        nameJa,
        generationId,
        textZhHans,
        textEn
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'abilities';
  @override
  VerificationContext validateIntegrity(Insertable<AbilitiesRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('identifier')) {
      context.handle(
          _identifierMeta,
          identifier.isAcceptableOrUnknown(
              data['identifier']!, _identifierMeta));
    } else if (isInserting) {
      context.missing(_identifierMeta);
    }
    if (data.containsKey('name_zh_hans')) {
      context.handle(
          _nameZhHansMeta,
          nameZhHans.isAcceptableOrUnknown(
              data['name_zh_hans']!, _nameZhHansMeta));
    } else if (isInserting) {
      context.missing(_nameZhHansMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(_nameEnMeta,
          nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta));
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('name_ja')) {
      context.handle(_nameJaMeta,
          nameJa.isAcceptableOrUnknown(data['name_ja']!, _nameJaMeta));
    } else if (isInserting) {
      context.missing(_nameJaMeta);
    }
    if (data.containsKey('generation_id')) {
      context.handle(
          _generationIdMeta,
          generationId.isAcceptableOrUnknown(
              data['generation_id']!, _generationIdMeta));
    } else if (isInserting) {
      context.missing(_generationIdMeta);
    }
    if (data.containsKey('text_zh_hans')) {
      context.handle(
          _textZhHansMeta,
          textZhHans.isAcceptableOrUnknown(
              data['text_zh_hans']!, _textZhHansMeta));
    }
    if (data.containsKey('text_en')) {
      context.handle(_textEnMeta,
          textEn.isAcceptableOrUnknown(data['text_en']!, _textEnMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  AbilitiesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AbilitiesRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      identifier: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}identifier'])!,
      nameZhHans: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_zh_hans'])!,
      nameEn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_en'])!,
      nameJa: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_ja'])!,
      generationId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}generation_id'])!,
      textZhHans: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}text_zh_hans']),
      textEn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}text_en']),
    );
  }

  @override
  $AbilitiesTable createAlias(String alias) {
    return $AbilitiesTable(attachedDatabase, alias);
  }
}

class AbilitiesRow extends DataClass implements Insertable<AbilitiesRow> {
  final int id;
  final String identifier;
  final String nameZhHans;
  final String nameEn;
  final String nameJa;
  final int generationId;
  final String? textZhHans;
  final String? textEn;
  const AbilitiesRow(
      {required this.id,
      required this.identifier,
      required this.nameZhHans,
      required this.nameEn,
      required this.nameJa,
      required this.generationId,
      this.textZhHans,
      this.textEn});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['identifier'] = Variable<String>(identifier);
    map['name_zh_hans'] = Variable<String>(nameZhHans);
    map['name_en'] = Variable<String>(nameEn);
    map['name_ja'] = Variable<String>(nameJa);
    map['generation_id'] = Variable<int>(generationId);
    if (!nullToAbsent || textZhHans != null) {
      map['text_zh_hans'] = Variable<String>(textZhHans);
    }
    if (!nullToAbsent || textEn != null) {
      map['text_en'] = Variable<String>(textEn);
    }
    return map;
  }

  AbilitiesCompanion toCompanion(bool nullToAbsent) {
    return AbilitiesCompanion(
      id: Value(id),
      identifier: Value(identifier),
      nameZhHans: Value(nameZhHans),
      nameEn: Value(nameEn),
      nameJa: Value(nameJa),
      generationId: Value(generationId),
      textZhHans: textZhHans == null && nullToAbsent
          ? const Value.absent()
          : Value(textZhHans),
      textEn:
          textEn == null && nullToAbsent ? const Value.absent() : Value(textEn),
    );
  }

  factory AbilitiesRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AbilitiesRow(
      id: serializer.fromJson<int>(json['id']),
      identifier: serializer.fromJson<String>(json['identifier']),
      nameZhHans: serializer.fromJson<String>(json['nameZhHans']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      nameJa: serializer.fromJson<String>(json['nameJa']),
      generationId: serializer.fromJson<int>(json['generationId']),
      textZhHans: serializer.fromJson<String?>(json['textZhHans']),
      textEn: serializer.fromJson<String?>(json['textEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'identifier': serializer.toJson<String>(identifier),
      'nameZhHans': serializer.toJson<String>(nameZhHans),
      'nameEn': serializer.toJson<String>(nameEn),
      'nameJa': serializer.toJson<String>(nameJa),
      'generationId': serializer.toJson<int>(generationId),
      'textZhHans': serializer.toJson<String?>(textZhHans),
      'textEn': serializer.toJson<String?>(textEn),
    };
  }

  AbilitiesRow copyWith(
          {int? id,
          String? identifier,
          String? nameZhHans,
          String? nameEn,
          String? nameJa,
          int? generationId,
          Value<String?> textZhHans = const Value.absent(),
          Value<String?> textEn = const Value.absent()}) =>
      AbilitiesRow(
        id: id ?? this.id,
        identifier: identifier ?? this.identifier,
        nameZhHans: nameZhHans ?? this.nameZhHans,
        nameEn: nameEn ?? this.nameEn,
        nameJa: nameJa ?? this.nameJa,
        generationId: generationId ?? this.generationId,
        textZhHans: textZhHans.present ? textZhHans.value : this.textZhHans,
        textEn: textEn.present ? textEn.value : this.textEn,
      );
  AbilitiesRow copyWithCompanion(AbilitiesCompanion data) {
    return AbilitiesRow(
      id: data.id.present ? data.id.value : this.id,
      identifier:
          data.identifier.present ? data.identifier.value : this.identifier,
      nameZhHans:
          data.nameZhHans.present ? data.nameZhHans.value : this.nameZhHans,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      nameJa: data.nameJa.present ? data.nameJa.value : this.nameJa,
      generationId: data.generationId.present
          ? data.generationId.value
          : this.generationId,
      textZhHans:
          data.textZhHans.present ? data.textZhHans.value : this.textZhHans,
      textEn: data.textEn.present ? data.textEn.value : this.textEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AbilitiesRow(')
          ..write('id: $id, ')
          ..write('identifier: $identifier, ')
          ..write('nameZhHans: $nameZhHans, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameJa: $nameJa, ')
          ..write('generationId: $generationId, ')
          ..write('textZhHans: $textZhHans, ')
          ..write('textEn: $textEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, identifier, nameZhHans, nameEn, nameJa,
      generationId, textZhHans, textEn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AbilitiesRow &&
          other.id == this.id &&
          other.identifier == this.identifier &&
          other.nameZhHans == this.nameZhHans &&
          other.nameEn == this.nameEn &&
          other.nameJa == this.nameJa &&
          other.generationId == this.generationId &&
          other.textZhHans == this.textZhHans &&
          other.textEn == this.textEn);
}

class AbilitiesCompanion extends UpdateCompanion<AbilitiesRow> {
  final Value<int> id;
  final Value<String> identifier;
  final Value<String> nameZhHans;
  final Value<String> nameEn;
  final Value<String> nameJa;
  final Value<int> generationId;
  final Value<String?> textZhHans;
  final Value<String?> textEn;
  final Value<int> rowid;
  const AbilitiesCompanion({
    this.id = const Value.absent(),
    this.identifier = const Value.absent(),
    this.nameZhHans = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.nameJa = const Value.absent(),
    this.generationId = const Value.absent(),
    this.textZhHans = const Value.absent(),
    this.textEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AbilitiesCompanion.insert({
    required int id,
    required String identifier,
    required String nameZhHans,
    required String nameEn,
    required String nameJa,
    required int generationId,
    this.textZhHans = const Value.absent(),
    this.textEn = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        identifier = Value(identifier),
        nameZhHans = Value(nameZhHans),
        nameEn = Value(nameEn),
        nameJa = Value(nameJa),
        generationId = Value(generationId);
  static Insertable<AbilitiesRow> custom({
    Expression<int>? id,
    Expression<String>? identifier,
    Expression<String>? nameZhHans,
    Expression<String>? nameEn,
    Expression<String>? nameJa,
    Expression<int>? generationId,
    Expression<String>? textZhHans,
    Expression<String>? textEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (identifier != null) 'identifier': identifier,
      if (nameZhHans != null) 'name_zh_hans': nameZhHans,
      if (nameEn != null) 'name_en': nameEn,
      if (nameJa != null) 'name_ja': nameJa,
      if (generationId != null) 'generation_id': generationId,
      if (textZhHans != null) 'text_zh_hans': textZhHans,
      if (textEn != null) 'text_en': textEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AbilitiesCompanion copyWith(
      {Value<int>? id,
      Value<String>? identifier,
      Value<String>? nameZhHans,
      Value<String>? nameEn,
      Value<String>? nameJa,
      Value<int>? generationId,
      Value<String?>? textZhHans,
      Value<String?>? textEn,
      Value<int>? rowid}) {
    return AbilitiesCompanion(
      id: id ?? this.id,
      identifier: identifier ?? this.identifier,
      nameZhHans: nameZhHans ?? this.nameZhHans,
      nameEn: nameEn ?? this.nameEn,
      nameJa: nameJa ?? this.nameJa,
      generationId: generationId ?? this.generationId,
      textZhHans: textZhHans ?? this.textZhHans,
      textEn: textEn ?? this.textEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (identifier.present) {
      map['identifier'] = Variable<String>(identifier.value);
    }
    if (nameZhHans.present) {
      map['name_zh_hans'] = Variable<String>(nameZhHans.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (nameJa.present) {
      map['name_ja'] = Variable<String>(nameJa.value);
    }
    if (generationId.present) {
      map['generation_id'] = Variable<int>(generationId.value);
    }
    if (textZhHans.present) {
      map['text_zh_hans'] = Variable<String>(textZhHans.value);
    }
    if (textEn.present) {
      map['text_en'] = Variable<String>(textEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AbilitiesCompanion(')
          ..write('id: $id, ')
          ..write('identifier: $identifier, ')
          ..write('nameZhHans: $nameZhHans, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameJa: $nameJa, ')
          ..write('generationId: $generationId, ')
          ..write('textZhHans: $textZhHans, ')
          ..write('textEn: $textEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MovesTable extends Moves with TableInfo<$MovesTable, MovesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MovesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _identifierMeta =
      const VerificationMeta('identifier');
  @override
  late final GeneratedColumn<String> identifier = GeneratedColumn<String>(
      'identifier', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _generationIdMeta =
      const VerificationMeta('generationId');
  @override
  late final GeneratedColumn<int> generationId = GeneratedColumn<int>(
      'generation_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _typeIdMeta = const VerificationMeta('typeId');
  @override
  late final GeneratedColumn<int> typeId = GeneratedColumn<int>(
      'type_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _damageClassMeta =
      const VerificationMeta('damageClass');
  @override
  late final GeneratedColumn<String> damageClass = GeneratedColumn<String>(
      'damage_class', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _powerMeta = const VerificationMeta('power');
  @override
  late final GeneratedColumn<int> power = GeneratedColumn<int>(
      'power', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _ppMeta = const VerificationMeta('pp');
  @override
  late final GeneratedColumn<int> pp = GeneratedColumn<int>(
      'pp', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _accuracyMeta =
      const VerificationMeta('accuracy');
  @override
  late final GeneratedColumn<int> accuracy = GeneratedColumn<int>(
      'accuracy', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<String> target = GeneratedColumn<String>(
      'target', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _effectChanceMeta =
      const VerificationMeta('effectChance');
  @override
  late final GeneratedColumn<int> effectChance = GeneratedColumn<int>(
      'effect_chance', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameZhHansMeta =
      const VerificationMeta('nameZhHans');
  @override
  late final GeneratedColumn<String> nameZhHans = GeneratedColumn<String>(
      'name_zh_hans', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
      'name_en', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameJaMeta = const VerificationMeta('nameJa');
  @override
  late final GeneratedColumn<String> nameJa = GeneratedColumn<String>(
      'name_ja', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _effectEnMeta =
      const VerificationMeta('effectEn');
  @override
  late final GeneratedColumn<String> effectEn = GeneratedColumn<String>(
      'effect_en', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _flavorZhHansMeta =
      const VerificationMeta('flavorZhHans');
  @override
  late final GeneratedColumn<String> flavorZhHans = GeneratedColumn<String>(
      'flavor_zh_hans', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        identifier,
        generationId,
        typeId,
        damageClass,
        power,
        pp,
        accuracy,
        priority,
        target,
        effectChance,
        nameZhHans,
        nameEn,
        nameJa,
        effectEn,
        flavorZhHans
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'moves';
  @override
  VerificationContext validateIntegrity(Insertable<MovesRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('identifier')) {
      context.handle(
          _identifierMeta,
          identifier.isAcceptableOrUnknown(
              data['identifier']!, _identifierMeta));
    } else if (isInserting) {
      context.missing(_identifierMeta);
    }
    if (data.containsKey('generation_id')) {
      context.handle(
          _generationIdMeta,
          generationId.isAcceptableOrUnknown(
              data['generation_id']!, _generationIdMeta));
    } else if (isInserting) {
      context.missing(_generationIdMeta);
    }
    if (data.containsKey('type_id')) {
      context.handle(_typeIdMeta,
          typeId.isAcceptableOrUnknown(data['type_id']!, _typeIdMeta));
    } else if (isInserting) {
      context.missing(_typeIdMeta);
    }
    if (data.containsKey('damage_class')) {
      context.handle(
          _damageClassMeta,
          damageClass.isAcceptableOrUnknown(
              data['damage_class']!, _damageClassMeta));
    } else if (isInserting) {
      context.missing(_damageClassMeta);
    }
    if (data.containsKey('power')) {
      context.handle(
          _powerMeta, power.isAcceptableOrUnknown(data['power']!, _powerMeta));
    }
    if (data.containsKey('pp')) {
      context.handle(_ppMeta, pp.isAcceptableOrUnknown(data['pp']!, _ppMeta));
    }
    if (data.containsKey('accuracy')) {
      context.handle(_accuracyMeta,
          accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('target')) {
      context.handle(_targetMeta,
          target.isAcceptableOrUnknown(data['target']!, _targetMeta));
    }
    if (data.containsKey('effect_chance')) {
      context.handle(
          _effectChanceMeta,
          effectChance.isAcceptableOrUnknown(
              data['effect_chance']!, _effectChanceMeta));
    }
    if (data.containsKey('name_zh_hans')) {
      context.handle(
          _nameZhHansMeta,
          nameZhHans.isAcceptableOrUnknown(
              data['name_zh_hans']!, _nameZhHansMeta));
    } else if (isInserting) {
      context.missing(_nameZhHansMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(_nameEnMeta,
          nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta));
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('name_ja')) {
      context.handle(_nameJaMeta,
          nameJa.isAcceptableOrUnknown(data['name_ja']!, _nameJaMeta));
    } else if (isInserting) {
      context.missing(_nameJaMeta);
    }
    if (data.containsKey('effect_en')) {
      context.handle(_effectEnMeta,
          effectEn.isAcceptableOrUnknown(data['effect_en']!, _effectEnMeta));
    }
    if (data.containsKey('flavor_zh_hans')) {
      context.handle(
          _flavorZhHansMeta,
          flavorZhHans.isAcceptableOrUnknown(
              data['flavor_zh_hans']!, _flavorZhHansMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  MovesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MovesRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      identifier: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}identifier'])!,
      generationId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}generation_id'])!,
      typeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type_id'])!,
      damageClass: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}damage_class'])!,
      power: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}power']),
      pp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pp']),
      accuracy: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}accuracy']),
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      target: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target']),
      effectChance: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}effect_chance']),
      nameZhHans: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_zh_hans'])!,
      nameEn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_en'])!,
      nameJa: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_ja'])!,
      effectEn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}effect_en']),
      flavorZhHans: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}flavor_zh_hans']),
    );
  }

  @override
  $MovesTable createAlias(String alias) {
    return $MovesTable(attachedDatabase, alias);
  }
}

class MovesRow extends DataClass implements Insertable<MovesRow> {
  final int id;
  final String identifier;
  final int generationId;
  final int typeId;
  final String damageClass;
  final int? power;
  final int? pp;
  final int? accuracy;
  final int priority;
  final String? target;
  final int? effectChance;
  final String nameZhHans;
  final String nameEn;
  final String nameJa;
  final String? effectEn;
  final String? flavorZhHans;
  const MovesRow(
      {required this.id,
      required this.identifier,
      required this.generationId,
      required this.typeId,
      required this.damageClass,
      this.power,
      this.pp,
      this.accuracy,
      required this.priority,
      this.target,
      this.effectChance,
      required this.nameZhHans,
      required this.nameEn,
      required this.nameJa,
      this.effectEn,
      this.flavorZhHans});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['identifier'] = Variable<String>(identifier);
    map['generation_id'] = Variable<int>(generationId);
    map['type_id'] = Variable<int>(typeId);
    map['damage_class'] = Variable<String>(damageClass);
    if (!nullToAbsent || power != null) {
      map['power'] = Variable<int>(power);
    }
    if (!nullToAbsent || pp != null) {
      map['pp'] = Variable<int>(pp);
    }
    if (!nullToAbsent || accuracy != null) {
      map['accuracy'] = Variable<int>(accuracy);
    }
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || target != null) {
      map['target'] = Variable<String>(target);
    }
    if (!nullToAbsent || effectChance != null) {
      map['effect_chance'] = Variable<int>(effectChance);
    }
    map['name_zh_hans'] = Variable<String>(nameZhHans);
    map['name_en'] = Variable<String>(nameEn);
    map['name_ja'] = Variable<String>(nameJa);
    if (!nullToAbsent || effectEn != null) {
      map['effect_en'] = Variable<String>(effectEn);
    }
    if (!nullToAbsent || flavorZhHans != null) {
      map['flavor_zh_hans'] = Variable<String>(flavorZhHans);
    }
    return map;
  }

  MovesCompanion toCompanion(bool nullToAbsent) {
    return MovesCompanion(
      id: Value(id),
      identifier: Value(identifier),
      generationId: Value(generationId),
      typeId: Value(typeId),
      damageClass: Value(damageClass),
      power:
          power == null && nullToAbsent ? const Value.absent() : Value(power),
      pp: pp == null && nullToAbsent ? const Value.absent() : Value(pp),
      accuracy: accuracy == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracy),
      priority: Value(priority),
      target:
          target == null && nullToAbsent ? const Value.absent() : Value(target),
      effectChance: effectChance == null && nullToAbsent
          ? const Value.absent()
          : Value(effectChance),
      nameZhHans: Value(nameZhHans),
      nameEn: Value(nameEn),
      nameJa: Value(nameJa),
      effectEn: effectEn == null && nullToAbsent
          ? const Value.absent()
          : Value(effectEn),
      flavorZhHans: flavorZhHans == null && nullToAbsent
          ? const Value.absent()
          : Value(flavorZhHans),
    );
  }

  factory MovesRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MovesRow(
      id: serializer.fromJson<int>(json['id']),
      identifier: serializer.fromJson<String>(json['identifier']),
      generationId: serializer.fromJson<int>(json['generationId']),
      typeId: serializer.fromJson<int>(json['typeId']),
      damageClass: serializer.fromJson<String>(json['damageClass']),
      power: serializer.fromJson<int?>(json['power']),
      pp: serializer.fromJson<int?>(json['pp']),
      accuracy: serializer.fromJson<int?>(json['accuracy']),
      priority: serializer.fromJson<int>(json['priority']),
      target: serializer.fromJson<String?>(json['target']),
      effectChance: serializer.fromJson<int?>(json['effectChance']),
      nameZhHans: serializer.fromJson<String>(json['nameZhHans']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      nameJa: serializer.fromJson<String>(json['nameJa']),
      effectEn: serializer.fromJson<String?>(json['effectEn']),
      flavorZhHans: serializer.fromJson<String?>(json['flavorZhHans']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'identifier': serializer.toJson<String>(identifier),
      'generationId': serializer.toJson<int>(generationId),
      'typeId': serializer.toJson<int>(typeId),
      'damageClass': serializer.toJson<String>(damageClass),
      'power': serializer.toJson<int?>(power),
      'pp': serializer.toJson<int?>(pp),
      'accuracy': serializer.toJson<int?>(accuracy),
      'priority': serializer.toJson<int>(priority),
      'target': serializer.toJson<String?>(target),
      'effectChance': serializer.toJson<int?>(effectChance),
      'nameZhHans': serializer.toJson<String>(nameZhHans),
      'nameEn': serializer.toJson<String>(nameEn),
      'nameJa': serializer.toJson<String>(nameJa),
      'effectEn': serializer.toJson<String?>(effectEn),
      'flavorZhHans': serializer.toJson<String?>(flavorZhHans),
    };
  }

  MovesRow copyWith(
          {int? id,
          String? identifier,
          int? generationId,
          int? typeId,
          String? damageClass,
          Value<int?> power = const Value.absent(),
          Value<int?> pp = const Value.absent(),
          Value<int?> accuracy = const Value.absent(),
          int? priority,
          Value<String?> target = const Value.absent(),
          Value<int?> effectChance = const Value.absent(),
          String? nameZhHans,
          String? nameEn,
          String? nameJa,
          Value<String?> effectEn = const Value.absent(),
          Value<String?> flavorZhHans = const Value.absent()}) =>
      MovesRow(
        id: id ?? this.id,
        identifier: identifier ?? this.identifier,
        generationId: generationId ?? this.generationId,
        typeId: typeId ?? this.typeId,
        damageClass: damageClass ?? this.damageClass,
        power: power.present ? power.value : this.power,
        pp: pp.present ? pp.value : this.pp,
        accuracy: accuracy.present ? accuracy.value : this.accuracy,
        priority: priority ?? this.priority,
        target: target.present ? target.value : this.target,
        effectChance:
            effectChance.present ? effectChance.value : this.effectChance,
        nameZhHans: nameZhHans ?? this.nameZhHans,
        nameEn: nameEn ?? this.nameEn,
        nameJa: nameJa ?? this.nameJa,
        effectEn: effectEn.present ? effectEn.value : this.effectEn,
        flavorZhHans:
            flavorZhHans.present ? flavorZhHans.value : this.flavorZhHans,
      );
  MovesRow copyWithCompanion(MovesCompanion data) {
    return MovesRow(
      id: data.id.present ? data.id.value : this.id,
      identifier:
          data.identifier.present ? data.identifier.value : this.identifier,
      generationId: data.generationId.present
          ? data.generationId.value
          : this.generationId,
      typeId: data.typeId.present ? data.typeId.value : this.typeId,
      damageClass:
          data.damageClass.present ? data.damageClass.value : this.damageClass,
      power: data.power.present ? data.power.value : this.power,
      pp: data.pp.present ? data.pp.value : this.pp,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      priority: data.priority.present ? data.priority.value : this.priority,
      target: data.target.present ? data.target.value : this.target,
      effectChance: data.effectChance.present
          ? data.effectChance.value
          : this.effectChance,
      nameZhHans:
          data.nameZhHans.present ? data.nameZhHans.value : this.nameZhHans,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      nameJa: data.nameJa.present ? data.nameJa.value : this.nameJa,
      effectEn: data.effectEn.present ? data.effectEn.value : this.effectEn,
      flavorZhHans: data.flavorZhHans.present
          ? data.flavorZhHans.value
          : this.flavorZhHans,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MovesRow(')
          ..write('id: $id, ')
          ..write('identifier: $identifier, ')
          ..write('generationId: $generationId, ')
          ..write('typeId: $typeId, ')
          ..write('damageClass: $damageClass, ')
          ..write('power: $power, ')
          ..write('pp: $pp, ')
          ..write('accuracy: $accuracy, ')
          ..write('priority: $priority, ')
          ..write('target: $target, ')
          ..write('effectChance: $effectChance, ')
          ..write('nameZhHans: $nameZhHans, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameJa: $nameJa, ')
          ..write('effectEn: $effectEn, ')
          ..write('flavorZhHans: $flavorZhHans')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      identifier,
      generationId,
      typeId,
      damageClass,
      power,
      pp,
      accuracy,
      priority,
      target,
      effectChance,
      nameZhHans,
      nameEn,
      nameJa,
      effectEn,
      flavorZhHans);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MovesRow &&
          other.id == this.id &&
          other.identifier == this.identifier &&
          other.generationId == this.generationId &&
          other.typeId == this.typeId &&
          other.damageClass == this.damageClass &&
          other.power == this.power &&
          other.pp == this.pp &&
          other.accuracy == this.accuracy &&
          other.priority == this.priority &&
          other.target == this.target &&
          other.effectChance == this.effectChance &&
          other.nameZhHans == this.nameZhHans &&
          other.nameEn == this.nameEn &&
          other.nameJa == this.nameJa &&
          other.effectEn == this.effectEn &&
          other.flavorZhHans == this.flavorZhHans);
}

class MovesCompanion extends UpdateCompanion<MovesRow> {
  final Value<int> id;
  final Value<String> identifier;
  final Value<int> generationId;
  final Value<int> typeId;
  final Value<String> damageClass;
  final Value<int?> power;
  final Value<int?> pp;
  final Value<int?> accuracy;
  final Value<int> priority;
  final Value<String?> target;
  final Value<int?> effectChance;
  final Value<String> nameZhHans;
  final Value<String> nameEn;
  final Value<String> nameJa;
  final Value<String?> effectEn;
  final Value<String?> flavorZhHans;
  final Value<int> rowid;
  const MovesCompanion({
    this.id = const Value.absent(),
    this.identifier = const Value.absent(),
    this.generationId = const Value.absent(),
    this.typeId = const Value.absent(),
    this.damageClass = const Value.absent(),
    this.power = const Value.absent(),
    this.pp = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.priority = const Value.absent(),
    this.target = const Value.absent(),
    this.effectChance = const Value.absent(),
    this.nameZhHans = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.nameJa = const Value.absent(),
    this.effectEn = const Value.absent(),
    this.flavorZhHans = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MovesCompanion.insert({
    required int id,
    required String identifier,
    required int generationId,
    required int typeId,
    required String damageClass,
    this.power = const Value.absent(),
    this.pp = const Value.absent(),
    this.accuracy = const Value.absent(),
    required int priority,
    this.target = const Value.absent(),
    this.effectChance = const Value.absent(),
    required String nameZhHans,
    required String nameEn,
    required String nameJa,
    this.effectEn = const Value.absent(),
    this.flavorZhHans = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        identifier = Value(identifier),
        generationId = Value(generationId),
        typeId = Value(typeId),
        damageClass = Value(damageClass),
        priority = Value(priority),
        nameZhHans = Value(nameZhHans),
        nameEn = Value(nameEn),
        nameJa = Value(nameJa);
  static Insertable<MovesRow> custom({
    Expression<int>? id,
    Expression<String>? identifier,
    Expression<int>? generationId,
    Expression<int>? typeId,
    Expression<String>? damageClass,
    Expression<int>? power,
    Expression<int>? pp,
    Expression<int>? accuracy,
    Expression<int>? priority,
    Expression<String>? target,
    Expression<int>? effectChance,
    Expression<String>? nameZhHans,
    Expression<String>? nameEn,
    Expression<String>? nameJa,
    Expression<String>? effectEn,
    Expression<String>? flavorZhHans,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (identifier != null) 'identifier': identifier,
      if (generationId != null) 'generation_id': generationId,
      if (typeId != null) 'type_id': typeId,
      if (damageClass != null) 'damage_class': damageClass,
      if (power != null) 'power': power,
      if (pp != null) 'pp': pp,
      if (accuracy != null) 'accuracy': accuracy,
      if (priority != null) 'priority': priority,
      if (target != null) 'target': target,
      if (effectChance != null) 'effect_chance': effectChance,
      if (nameZhHans != null) 'name_zh_hans': nameZhHans,
      if (nameEn != null) 'name_en': nameEn,
      if (nameJa != null) 'name_ja': nameJa,
      if (effectEn != null) 'effect_en': effectEn,
      if (flavorZhHans != null) 'flavor_zh_hans': flavorZhHans,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MovesCompanion copyWith(
      {Value<int>? id,
      Value<String>? identifier,
      Value<int>? generationId,
      Value<int>? typeId,
      Value<String>? damageClass,
      Value<int?>? power,
      Value<int?>? pp,
      Value<int?>? accuracy,
      Value<int>? priority,
      Value<String?>? target,
      Value<int?>? effectChance,
      Value<String>? nameZhHans,
      Value<String>? nameEn,
      Value<String>? nameJa,
      Value<String?>? effectEn,
      Value<String?>? flavorZhHans,
      Value<int>? rowid}) {
    return MovesCompanion(
      id: id ?? this.id,
      identifier: identifier ?? this.identifier,
      generationId: generationId ?? this.generationId,
      typeId: typeId ?? this.typeId,
      damageClass: damageClass ?? this.damageClass,
      power: power ?? this.power,
      pp: pp ?? this.pp,
      accuracy: accuracy ?? this.accuracy,
      priority: priority ?? this.priority,
      target: target ?? this.target,
      effectChance: effectChance ?? this.effectChance,
      nameZhHans: nameZhHans ?? this.nameZhHans,
      nameEn: nameEn ?? this.nameEn,
      nameJa: nameJa ?? this.nameJa,
      effectEn: effectEn ?? this.effectEn,
      flavorZhHans: flavorZhHans ?? this.flavorZhHans,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (identifier.present) {
      map['identifier'] = Variable<String>(identifier.value);
    }
    if (generationId.present) {
      map['generation_id'] = Variable<int>(generationId.value);
    }
    if (typeId.present) {
      map['type_id'] = Variable<int>(typeId.value);
    }
    if (damageClass.present) {
      map['damage_class'] = Variable<String>(damageClass.value);
    }
    if (power.present) {
      map['power'] = Variable<int>(power.value);
    }
    if (pp.present) {
      map['pp'] = Variable<int>(pp.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<int>(accuracy.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (target.present) {
      map['target'] = Variable<String>(target.value);
    }
    if (effectChance.present) {
      map['effect_chance'] = Variable<int>(effectChance.value);
    }
    if (nameZhHans.present) {
      map['name_zh_hans'] = Variable<String>(nameZhHans.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (nameJa.present) {
      map['name_ja'] = Variable<String>(nameJa.value);
    }
    if (effectEn.present) {
      map['effect_en'] = Variable<String>(effectEn.value);
    }
    if (flavorZhHans.present) {
      map['flavor_zh_hans'] = Variable<String>(flavorZhHans.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MovesCompanion(')
          ..write('id: $id, ')
          ..write('identifier: $identifier, ')
          ..write('generationId: $generationId, ')
          ..write('typeId: $typeId, ')
          ..write('damageClass: $damageClass, ')
          ..write('power: $power, ')
          ..write('pp: $pp, ')
          ..write('accuracy: $accuracy, ')
          ..write('priority: $priority, ')
          ..write('target: $target, ')
          ..write('effectChance: $effectChance, ')
          ..write('nameZhHans: $nameZhHans, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameJa: $nameJa, ')
          ..write('effectEn: $effectEn, ')
          ..write('flavorZhHans: $flavorZhHans, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SpeciesTable extends Species with TableInfo<$SpeciesTable, SpeciesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SpeciesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nationalDexMeta =
      const VerificationMeta('nationalDex');
  @override
  late final GeneratedColumn<int> nationalDex = GeneratedColumn<int>(
      'national_dex', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _generationIdMeta =
      const VerificationMeta('generationId');
  @override
  late final GeneratedColumn<int> generationId = GeneratedColumn<int>(
      'generation_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameZhHansMeta =
      const VerificationMeta('nameZhHans');
  @override
  late final GeneratedColumn<String> nameZhHans = GeneratedColumn<String>(
      'name_zh_hans', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameZhHantMeta =
      const VerificationMeta('nameZhHant');
  @override
  late final GeneratedColumn<String> nameZhHant = GeneratedColumn<String>(
      'name_zh_hant', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
      'name_en', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameJaMeta = const VerificationMeta('nameJa');
  @override
  late final GeneratedColumn<String> nameJa = GeneratedColumn<String>(
      'name_ja', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameJaHrktMeta =
      const VerificationMeta('nameJaHrkt');
  @override
  late final GeneratedColumn<String> nameJaHrkt = GeneratedColumn<String>(
      'name_ja_hrkt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameRoomajiMeta =
      const VerificationMeta('nameRoomaji');
  @override
  late final GeneratedColumn<String> nameRoomaji = GeneratedColumn<String>(
      'name_roomaji', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _genusZhHansMeta =
      const VerificationMeta('genusZhHans');
  @override
  late final GeneratedColumn<String> genusZhHans = GeneratedColumn<String>(
      'genus_zh_hans', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _genusEnMeta =
      const VerificationMeta('genusEn');
  @override
  late final GeneratedColumn<String> genusEn = GeneratedColumn<String>(
      'genus_en', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isLegendaryMeta =
      const VerificationMeta('isLegendary');
  @override
  late final GeneratedColumn<bool> isLegendary = GeneratedColumn<bool>(
      'is_legendary', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_legendary" IN (0, 1))'));
  static const VerificationMeta _isMythicalMeta =
      const VerificationMeta('isMythical');
  @override
  late final GeneratedColumn<bool> isMythical = GeneratedColumn<bool>(
      'is_mythical', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_mythical" IN (0, 1))'));
  static const VerificationMeta _isUltraBeastMeta =
      const VerificationMeta('isUltraBeast');
  @override
  late final GeneratedColumn<bool> isUltraBeast = GeneratedColumn<bool>(
      'is_ultra_beast', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_ultra_beast" IN (0, 1))'));
  static const VerificationMeta _isBabyMeta = const VerificationMeta('isBaby');
  @override
  late final GeneratedColumn<bool> isBaby = GeneratedColumn<bool>(
      'is_baby', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_baby" IN (0, 1))'));
  static const VerificationMeta _evolutionChainIdMeta =
      const VerificationMeta('evolutionChainId');
  @override
  late final GeneratedColumn<int> evolutionChainId = GeneratedColumn<int>(
      'evolution_chain_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _captureRateMeta =
      const VerificationMeta('captureRate');
  @override
  late final GeneratedColumn<int> captureRate = GeneratedColumn<int>(
      'capture_rate', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _baseHappinessMeta =
      const VerificationMeta('baseHappiness');
  @override
  late final GeneratedColumn<int> baseHappiness = GeneratedColumn<int>(
      'base_happiness', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _genderRateMeta =
      const VerificationMeta('genderRate');
  @override
  late final GeneratedColumn<int> genderRate = GeneratedColumn<int>(
      'gender_rate', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _hatchCounterMeta =
      const VerificationMeta('hatchCounter');
  @override
  late final GeneratedColumn<int> hatchCounter = GeneratedColumn<int>(
      'hatch_counter', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _growthRateMeta =
      const VerificationMeta('growthRate');
  @override
  late final GeneratedColumn<String> growthRate = GeneratedColumn<String>(
      'growth_rate', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _eggGroup1Meta =
      const VerificationMeta('eggGroup1');
  @override
  late final GeneratedColumn<String> eggGroup1 = GeneratedColumn<String>(
      'egg_group_1', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _eggGroup2Meta =
      const VerificationMeta('eggGroup2');
  @override
  late final GeneratedColumn<String> eggGroup2 = GeneratedColumn<String>(
      'egg_group_2', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _shapeMeta = const VerificationMeta('shape');
  @override
  late final GeneratedColumn<String> shape = GeneratedColumn<String>(
      'shape', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _habitatMeta =
      const VerificationMeta('habitat');
  @override
  late final GeneratedColumn<String> habitat = GeneratedColumn<String>(
      'habitat', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        nationalDex,
        generationId,
        nameZhHans,
        nameZhHant,
        nameEn,
        nameJa,
        nameJaHrkt,
        nameRoomaji,
        genusZhHans,
        genusEn,
        isLegendary,
        isMythical,
        isUltraBeast,
        isBaby,
        evolutionChainId,
        captureRate,
        baseHappiness,
        genderRate,
        hatchCounter,
        growthRate,
        eggGroup1,
        eggGroup2,
        color,
        shape,
        habitat
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'species';
  @override
  VerificationContext validateIntegrity(Insertable<SpeciesRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('national_dex')) {
      context.handle(
          _nationalDexMeta,
          nationalDex.isAcceptableOrUnknown(
              data['national_dex']!, _nationalDexMeta));
    } else if (isInserting) {
      context.missing(_nationalDexMeta);
    }
    if (data.containsKey('generation_id')) {
      context.handle(
          _generationIdMeta,
          generationId.isAcceptableOrUnknown(
              data['generation_id']!, _generationIdMeta));
    } else if (isInserting) {
      context.missing(_generationIdMeta);
    }
    if (data.containsKey('name_zh_hans')) {
      context.handle(
          _nameZhHansMeta,
          nameZhHans.isAcceptableOrUnknown(
              data['name_zh_hans']!, _nameZhHansMeta));
    } else if (isInserting) {
      context.missing(_nameZhHansMeta);
    }
    if (data.containsKey('name_zh_hant')) {
      context.handle(
          _nameZhHantMeta,
          nameZhHant.isAcceptableOrUnknown(
              data['name_zh_hant']!, _nameZhHantMeta));
    } else if (isInserting) {
      context.missing(_nameZhHantMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(_nameEnMeta,
          nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta));
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('name_ja')) {
      context.handle(_nameJaMeta,
          nameJa.isAcceptableOrUnknown(data['name_ja']!, _nameJaMeta));
    } else if (isInserting) {
      context.missing(_nameJaMeta);
    }
    if (data.containsKey('name_ja_hrkt')) {
      context.handle(
          _nameJaHrktMeta,
          nameJaHrkt.isAcceptableOrUnknown(
              data['name_ja_hrkt']!, _nameJaHrktMeta));
    } else if (isInserting) {
      context.missing(_nameJaHrktMeta);
    }
    if (data.containsKey('name_roomaji')) {
      context.handle(
          _nameRoomajiMeta,
          nameRoomaji.isAcceptableOrUnknown(
              data['name_roomaji']!, _nameRoomajiMeta));
    }
    if (data.containsKey('genus_zh_hans')) {
      context.handle(
          _genusZhHansMeta,
          genusZhHans.isAcceptableOrUnknown(
              data['genus_zh_hans']!, _genusZhHansMeta));
    }
    if (data.containsKey('genus_en')) {
      context.handle(_genusEnMeta,
          genusEn.isAcceptableOrUnknown(data['genus_en']!, _genusEnMeta));
    }
    if (data.containsKey('is_legendary')) {
      context.handle(
          _isLegendaryMeta,
          isLegendary.isAcceptableOrUnknown(
              data['is_legendary']!, _isLegendaryMeta));
    } else if (isInserting) {
      context.missing(_isLegendaryMeta);
    }
    if (data.containsKey('is_mythical')) {
      context.handle(
          _isMythicalMeta,
          isMythical.isAcceptableOrUnknown(
              data['is_mythical']!, _isMythicalMeta));
    } else if (isInserting) {
      context.missing(_isMythicalMeta);
    }
    if (data.containsKey('is_ultra_beast')) {
      context.handle(
          _isUltraBeastMeta,
          isUltraBeast.isAcceptableOrUnknown(
              data['is_ultra_beast']!, _isUltraBeastMeta));
    } else if (isInserting) {
      context.missing(_isUltraBeastMeta);
    }
    if (data.containsKey('is_baby')) {
      context.handle(_isBabyMeta,
          isBaby.isAcceptableOrUnknown(data['is_baby']!, _isBabyMeta));
    } else if (isInserting) {
      context.missing(_isBabyMeta);
    }
    if (data.containsKey('evolution_chain_id')) {
      context.handle(
          _evolutionChainIdMeta,
          evolutionChainId.isAcceptableOrUnknown(
              data['evolution_chain_id']!, _evolutionChainIdMeta));
    }
    if (data.containsKey('capture_rate')) {
      context.handle(
          _captureRateMeta,
          captureRate.isAcceptableOrUnknown(
              data['capture_rate']!, _captureRateMeta));
    }
    if (data.containsKey('base_happiness')) {
      context.handle(
          _baseHappinessMeta,
          baseHappiness.isAcceptableOrUnknown(
              data['base_happiness']!, _baseHappinessMeta));
    }
    if (data.containsKey('gender_rate')) {
      context.handle(
          _genderRateMeta,
          genderRate.isAcceptableOrUnknown(
              data['gender_rate']!, _genderRateMeta));
    }
    if (data.containsKey('hatch_counter')) {
      context.handle(
          _hatchCounterMeta,
          hatchCounter.isAcceptableOrUnknown(
              data['hatch_counter']!, _hatchCounterMeta));
    }
    if (data.containsKey('growth_rate')) {
      context.handle(
          _growthRateMeta,
          growthRate.isAcceptableOrUnknown(
              data['growth_rate']!, _growthRateMeta));
    }
    if (data.containsKey('egg_group_1')) {
      context.handle(
          _eggGroup1Meta,
          eggGroup1.isAcceptableOrUnknown(
              data['egg_group_1']!, _eggGroup1Meta));
    }
    if (data.containsKey('egg_group_2')) {
      context.handle(
          _eggGroup2Meta,
          eggGroup2.isAcceptableOrUnknown(
              data['egg_group_2']!, _eggGroup2Meta));
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('shape')) {
      context.handle(
          _shapeMeta, shape.isAcceptableOrUnknown(data['shape']!, _shapeMeta));
    }
    if (data.containsKey('habitat')) {
      context.handle(_habitatMeta,
          habitat.isAcceptableOrUnknown(data['habitat']!, _habitatMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  SpeciesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SpeciesRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      nationalDex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}national_dex'])!,
      generationId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}generation_id'])!,
      nameZhHans: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_zh_hans'])!,
      nameZhHant: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_zh_hant'])!,
      nameEn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_en'])!,
      nameJa: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_ja'])!,
      nameJaHrkt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_ja_hrkt'])!,
      nameRoomaji: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_roomaji']),
      genusZhHans: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genus_zh_hans']),
      genusEn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genus_en']),
      isLegendary: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_legendary'])!,
      isMythical: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_mythical'])!,
      isUltraBeast: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_ultra_beast'])!,
      isBaby: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_baby'])!,
      evolutionChainId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}evolution_chain_id']),
      captureRate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}capture_rate']),
      baseHappiness: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}base_happiness']),
      genderRate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}gender_rate']),
      hatchCounter: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hatch_counter']),
      growthRate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}growth_rate']),
      eggGroup1: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}egg_group_1']),
      eggGroup2: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}egg_group_2']),
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
      shape: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shape']),
      habitat: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}habitat']),
    );
  }

  @override
  $SpeciesTable createAlias(String alias) {
    return $SpeciesTable(attachedDatabase, alias);
  }
}

class SpeciesRow extends DataClass implements Insertable<SpeciesRow> {
  final int id;
  final int nationalDex;
  final int generationId;
  final String nameZhHans;
  final String nameZhHant;
  final String nameEn;
  final String nameJa;
  final String nameJaHrkt;
  final String? nameRoomaji;
  final String? genusZhHans;
  final String? genusEn;
  final bool isLegendary;
  final bool isMythical;
  final bool isUltraBeast;
  final bool isBaby;
  final int? evolutionChainId;
  final int? captureRate;
  final int? baseHappiness;
  final int? genderRate;
  final int? hatchCounter;
  final String? growthRate;
  final String? eggGroup1;
  final String? eggGroup2;
  final String? color;
  final String? shape;
  final String? habitat;
  const SpeciesRow(
      {required this.id,
      required this.nationalDex,
      required this.generationId,
      required this.nameZhHans,
      required this.nameZhHant,
      required this.nameEn,
      required this.nameJa,
      required this.nameJaHrkt,
      this.nameRoomaji,
      this.genusZhHans,
      this.genusEn,
      required this.isLegendary,
      required this.isMythical,
      required this.isUltraBeast,
      required this.isBaby,
      this.evolutionChainId,
      this.captureRate,
      this.baseHappiness,
      this.genderRate,
      this.hatchCounter,
      this.growthRate,
      this.eggGroup1,
      this.eggGroup2,
      this.color,
      this.shape,
      this.habitat});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['national_dex'] = Variable<int>(nationalDex);
    map['generation_id'] = Variable<int>(generationId);
    map['name_zh_hans'] = Variable<String>(nameZhHans);
    map['name_zh_hant'] = Variable<String>(nameZhHant);
    map['name_en'] = Variable<String>(nameEn);
    map['name_ja'] = Variable<String>(nameJa);
    map['name_ja_hrkt'] = Variable<String>(nameJaHrkt);
    if (!nullToAbsent || nameRoomaji != null) {
      map['name_roomaji'] = Variable<String>(nameRoomaji);
    }
    if (!nullToAbsent || genusZhHans != null) {
      map['genus_zh_hans'] = Variable<String>(genusZhHans);
    }
    if (!nullToAbsent || genusEn != null) {
      map['genus_en'] = Variable<String>(genusEn);
    }
    map['is_legendary'] = Variable<bool>(isLegendary);
    map['is_mythical'] = Variable<bool>(isMythical);
    map['is_ultra_beast'] = Variable<bool>(isUltraBeast);
    map['is_baby'] = Variable<bool>(isBaby);
    if (!nullToAbsent || evolutionChainId != null) {
      map['evolution_chain_id'] = Variable<int>(evolutionChainId);
    }
    if (!nullToAbsent || captureRate != null) {
      map['capture_rate'] = Variable<int>(captureRate);
    }
    if (!nullToAbsent || baseHappiness != null) {
      map['base_happiness'] = Variable<int>(baseHappiness);
    }
    if (!nullToAbsent || genderRate != null) {
      map['gender_rate'] = Variable<int>(genderRate);
    }
    if (!nullToAbsent || hatchCounter != null) {
      map['hatch_counter'] = Variable<int>(hatchCounter);
    }
    if (!nullToAbsent || growthRate != null) {
      map['growth_rate'] = Variable<String>(growthRate);
    }
    if (!nullToAbsent || eggGroup1 != null) {
      map['egg_group_1'] = Variable<String>(eggGroup1);
    }
    if (!nullToAbsent || eggGroup2 != null) {
      map['egg_group_2'] = Variable<String>(eggGroup2);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || shape != null) {
      map['shape'] = Variable<String>(shape);
    }
    if (!nullToAbsent || habitat != null) {
      map['habitat'] = Variable<String>(habitat);
    }
    return map;
  }

  SpeciesCompanion toCompanion(bool nullToAbsent) {
    return SpeciesCompanion(
      id: Value(id),
      nationalDex: Value(nationalDex),
      generationId: Value(generationId),
      nameZhHans: Value(nameZhHans),
      nameZhHant: Value(nameZhHant),
      nameEn: Value(nameEn),
      nameJa: Value(nameJa),
      nameJaHrkt: Value(nameJaHrkt),
      nameRoomaji: nameRoomaji == null && nullToAbsent
          ? const Value.absent()
          : Value(nameRoomaji),
      genusZhHans: genusZhHans == null && nullToAbsent
          ? const Value.absent()
          : Value(genusZhHans),
      genusEn: genusEn == null && nullToAbsent
          ? const Value.absent()
          : Value(genusEn),
      isLegendary: Value(isLegendary),
      isMythical: Value(isMythical),
      isUltraBeast: Value(isUltraBeast),
      isBaby: Value(isBaby),
      evolutionChainId: evolutionChainId == null && nullToAbsent
          ? const Value.absent()
          : Value(evolutionChainId),
      captureRate: captureRate == null && nullToAbsent
          ? const Value.absent()
          : Value(captureRate),
      baseHappiness: baseHappiness == null && nullToAbsent
          ? const Value.absent()
          : Value(baseHappiness),
      genderRate: genderRate == null && nullToAbsent
          ? const Value.absent()
          : Value(genderRate),
      hatchCounter: hatchCounter == null && nullToAbsent
          ? const Value.absent()
          : Value(hatchCounter),
      growthRate: growthRate == null && nullToAbsent
          ? const Value.absent()
          : Value(growthRate),
      eggGroup1: eggGroup1 == null && nullToAbsent
          ? const Value.absent()
          : Value(eggGroup1),
      eggGroup2: eggGroup2 == null && nullToAbsent
          ? const Value.absent()
          : Value(eggGroup2),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      shape:
          shape == null && nullToAbsent ? const Value.absent() : Value(shape),
      habitat: habitat == null && nullToAbsent
          ? const Value.absent()
          : Value(habitat),
    );
  }

  factory SpeciesRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SpeciesRow(
      id: serializer.fromJson<int>(json['id']),
      nationalDex: serializer.fromJson<int>(json['nationalDex']),
      generationId: serializer.fromJson<int>(json['generationId']),
      nameZhHans: serializer.fromJson<String>(json['nameZhHans']),
      nameZhHant: serializer.fromJson<String>(json['nameZhHant']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      nameJa: serializer.fromJson<String>(json['nameJa']),
      nameJaHrkt: serializer.fromJson<String>(json['nameJaHrkt']),
      nameRoomaji: serializer.fromJson<String?>(json['nameRoomaji']),
      genusZhHans: serializer.fromJson<String?>(json['genusZhHans']),
      genusEn: serializer.fromJson<String?>(json['genusEn']),
      isLegendary: serializer.fromJson<bool>(json['isLegendary']),
      isMythical: serializer.fromJson<bool>(json['isMythical']),
      isUltraBeast: serializer.fromJson<bool>(json['isUltraBeast']),
      isBaby: serializer.fromJson<bool>(json['isBaby']),
      evolutionChainId: serializer.fromJson<int?>(json['evolutionChainId']),
      captureRate: serializer.fromJson<int?>(json['captureRate']),
      baseHappiness: serializer.fromJson<int?>(json['baseHappiness']),
      genderRate: serializer.fromJson<int?>(json['genderRate']),
      hatchCounter: serializer.fromJson<int?>(json['hatchCounter']),
      growthRate: serializer.fromJson<String?>(json['growthRate']),
      eggGroup1: serializer.fromJson<String?>(json['eggGroup1']),
      eggGroup2: serializer.fromJson<String?>(json['eggGroup2']),
      color: serializer.fromJson<String?>(json['color']),
      shape: serializer.fromJson<String?>(json['shape']),
      habitat: serializer.fromJson<String?>(json['habitat']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nationalDex': serializer.toJson<int>(nationalDex),
      'generationId': serializer.toJson<int>(generationId),
      'nameZhHans': serializer.toJson<String>(nameZhHans),
      'nameZhHant': serializer.toJson<String>(nameZhHant),
      'nameEn': serializer.toJson<String>(nameEn),
      'nameJa': serializer.toJson<String>(nameJa),
      'nameJaHrkt': serializer.toJson<String>(nameJaHrkt),
      'nameRoomaji': serializer.toJson<String?>(nameRoomaji),
      'genusZhHans': serializer.toJson<String?>(genusZhHans),
      'genusEn': serializer.toJson<String?>(genusEn),
      'isLegendary': serializer.toJson<bool>(isLegendary),
      'isMythical': serializer.toJson<bool>(isMythical),
      'isUltraBeast': serializer.toJson<bool>(isUltraBeast),
      'isBaby': serializer.toJson<bool>(isBaby),
      'evolutionChainId': serializer.toJson<int?>(evolutionChainId),
      'captureRate': serializer.toJson<int?>(captureRate),
      'baseHappiness': serializer.toJson<int?>(baseHappiness),
      'genderRate': serializer.toJson<int?>(genderRate),
      'hatchCounter': serializer.toJson<int?>(hatchCounter),
      'growthRate': serializer.toJson<String?>(growthRate),
      'eggGroup1': serializer.toJson<String?>(eggGroup1),
      'eggGroup2': serializer.toJson<String?>(eggGroup2),
      'color': serializer.toJson<String?>(color),
      'shape': serializer.toJson<String?>(shape),
      'habitat': serializer.toJson<String?>(habitat),
    };
  }

  SpeciesRow copyWith(
          {int? id,
          int? nationalDex,
          int? generationId,
          String? nameZhHans,
          String? nameZhHant,
          String? nameEn,
          String? nameJa,
          String? nameJaHrkt,
          Value<String?> nameRoomaji = const Value.absent(),
          Value<String?> genusZhHans = const Value.absent(),
          Value<String?> genusEn = const Value.absent(),
          bool? isLegendary,
          bool? isMythical,
          bool? isUltraBeast,
          bool? isBaby,
          Value<int?> evolutionChainId = const Value.absent(),
          Value<int?> captureRate = const Value.absent(),
          Value<int?> baseHappiness = const Value.absent(),
          Value<int?> genderRate = const Value.absent(),
          Value<int?> hatchCounter = const Value.absent(),
          Value<String?> growthRate = const Value.absent(),
          Value<String?> eggGroup1 = const Value.absent(),
          Value<String?> eggGroup2 = const Value.absent(),
          Value<String?> color = const Value.absent(),
          Value<String?> shape = const Value.absent(),
          Value<String?> habitat = const Value.absent()}) =>
      SpeciesRow(
        id: id ?? this.id,
        nationalDex: nationalDex ?? this.nationalDex,
        generationId: generationId ?? this.generationId,
        nameZhHans: nameZhHans ?? this.nameZhHans,
        nameZhHant: nameZhHant ?? this.nameZhHant,
        nameEn: nameEn ?? this.nameEn,
        nameJa: nameJa ?? this.nameJa,
        nameJaHrkt: nameJaHrkt ?? this.nameJaHrkt,
        nameRoomaji: nameRoomaji.present ? nameRoomaji.value : this.nameRoomaji,
        genusZhHans: genusZhHans.present ? genusZhHans.value : this.genusZhHans,
        genusEn: genusEn.present ? genusEn.value : this.genusEn,
        isLegendary: isLegendary ?? this.isLegendary,
        isMythical: isMythical ?? this.isMythical,
        isUltraBeast: isUltraBeast ?? this.isUltraBeast,
        isBaby: isBaby ?? this.isBaby,
        evolutionChainId: evolutionChainId.present
            ? evolutionChainId.value
            : this.evolutionChainId,
        captureRate: captureRate.present ? captureRate.value : this.captureRate,
        baseHappiness:
            baseHappiness.present ? baseHappiness.value : this.baseHappiness,
        genderRate: genderRate.present ? genderRate.value : this.genderRate,
        hatchCounter:
            hatchCounter.present ? hatchCounter.value : this.hatchCounter,
        growthRate: growthRate.present ? growthRate.value : this.growthRate,
        eggGroup1: eggGroup1.present ? eggGroup1.value : this.eggGroup1,
        eggGroup2: eggGroup2.present ? eggGroup2.value : this.eggGroup2,
        color: color.present ? color.value : this.color,
        shape: shape.present ? shape.value : this.shape,
        habitat: habitat.present ? habitat.value : this.habitat,
      );
  SpeciesRow copyWithCompanion(SpeciesCompanion data) {
    return SpeciesRow(
      id: data.id.present ? data.id.value : this.id,
      nationalDex:
          data.nationalDex.present ? data.nationalDex.value : this.nationalDex,
      generationId: data.generationId.present
          ? data.generationId.value
          : this.generationId,
      nameZhHans:
          data.nameZhHans.present ? data.nameZhHans.value : this.nameZhHans,
      nameZhHant:
          data.nameZhHant.present ? data.nameZhHant.value : this.nameZhHant,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      nameJa: data.nameJa.present ? data.nameJa.value : this.nameJa,
      nameJaHrkt:
          data.nameJaHrkt.present ? data.nameJaHrkt.value : this.nameJaHrkt,
      nameRoomaji:
          data.nameRoomaji.present ? data.nameRoomaji.value : this.nameRoomaji,
      genusZhHans:
          data.genusZhHans.present ? data.genusZhHans.value : this.genusZhHans,
      genusEn: data.genusEn.present ? data.genusEn.value : this.genusEn,
      isLegendary:
          data.isLegendary.present ? data.isLegendary.value : this.isLegendary,
      isMythical:
          data.isMythical.present ? data.isMythical.value : this.isMythical,
      isUltraBeast: data.isUltraBeast.present
          ? data.isUltraBeast.value
          : this.isUltraBeast,
      isBaby: data.isBaby.present ? data.isBaby.value : this.isBaby,
      evolutionChainId: data.evolutionChainId.present
          ? data.evolutionChainId.value
          : this.evolutionChainId,
      captureRate:
          data.captureRate.present ? data.captureRate.value : this.captureRate,
      baseHappiness: data.baseHappiness.present
          ? data.baseHappiness.value
          : this.baseHappiness,
      genderRate:
          data.genderRate.present ? data.genderRate.value : this.genderRate,
      hatchCounter: data.hatchCounter.present
          ? data.hatchCounter.value
          : this.hatchCounter,
      growthRate:
          data.growthRate.present ? data.growthRate.value : this.growthRate,
      eggGroup1: data.eggGroup1.present ? data.eggGroup1.value : this.eggGroup1,
      eggGroup2: data.eggGroup2.present ? data.eggGroup2.value : this.eggGroup2,
      color: data.color.present ? data.color.value : this.color,
      shape: data.shape.present ? data.shape.value : this.shape,
      habitat: data.habitat.present ? data.habitat.value : this.habitat,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SpeciesRow(')
          ..write('id: $id, ')
          ..write('nationalDex: $nationalDex, ')
          ..write('generationId: $generationId, ')
          ..write('nameZhHans: $nameZhHans, ')
          ..write('nameZhHant: $nameZhHant, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameJa: $nameJa, ')
          ..write('nameJaHrkt: $nameJaHrkt, ')
          ..write('nameRoomaji: $nameRoomaji, ')
          ..write('genusZhHans: $genusZhHans, ')
          ..write('genusEn: $genusEn, ')
          ..write('isLegendary: $isLegendary, ')
          ..write('isMythical: $isMythical, ')
          ..write('isUltraBeast: $isUltraBeast, ')
          ..write('isBaby: $isBaby, ')
          ..write('evolutionChainId: $evolutionChainId, ')
          ..write('captureRate: $captureRate, ')
          ..write('baseHappiness: $baseHappiness, ')
          ..write('genderRate: $genderRate, ')
          ..write('hatchCounter: $hatchCounter, ')
          ..write('growthRate: $growthRate, ')
          ..write('eggGroup1: $eggGroup1, ')
          ..write('eggGroup2: $eggGroup2, ')
          ..write('color: $color, ')
          ..write('shape: $shape, ')
          ..write('habitat: $habitat')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        nationalDex,
        generationId,
        nameZhHans,
        nameZhHant,
        nameEn,
        nameJa,
        nameJaHrkt,
        nameRoomaji,
        genusZhHans,
        genusEn,
        isLegendary,
        isMythical,
        isUltraBeast,
        isBaby,
        evolutionChainId,
        captureRate,
        baseHappiness,
        genderRate,
        hatchCounter,
        growthRate,
        eggGroup1,
        eggGroup2,
        color,
        shape,
        habitat
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpeciesRow &&
          other.id == this.id &&
          other.nationalDex == this.nationalDex &&
          other.generationId == this.generationId &&
          other.nameZhHans == this.nameZhHans &&
          other.nameZhHant == this.nameZhHant &&
          other.nameEn == this.nameEn &&
          other.nameJa == this.nameJa &&
          other.nameJaHrkt == this.nameJaHrkt &&
          other.nameRoomaji == this.nameRoomaji &&
          other.genusZhHans == this.genusZhHans &&
          other.genusEn == this.genusEn &&
          other.isLegendary == this.isLegendary &&
          other.isMythical == this.isMythical &&
          other.isUltraBeast == this.isUltraBeast &&
          other.isBaby == this.isBaby &&
          other.evolutionChainId == this.evolutionChainId &&
          other.captureRate == this.captureRate &&
          other.baseHappiness == this.baseHappiness &&
          other.genderRate == this.genderRate &&
          other.hatchCounter == this.hatchCounter &&
          other.growthRate == this.growthRate &&
          other.eggGroup1 == this.eggGroup1 &&
          other.eggGroup2 == this.eggGroup2 &&
          other.color == this.color &&
          other.shape == this.shape &&
          other.habitat == this.habitat);
}

class SpeciesCompanion extends UpdateCompanion<SpeciesRow> {
  final Value<int> id;
  final Value<int> nationalDex;
  final Value<int> generationId;
  final Value<String> nameZhHans;
  final Value<String> nameZhHant;
  final Value<String> nameEn;
  final Value<String> nameJa;
  final Value<String> nameJaHrkt;
  final Value<String?> nameRoomaji;
  final Value<String?> genusZhHans;
  final Value<String?> genusEn;
  final Value<bool> isLegendary;
  final Value<bool> isMythical;
  final Value<bool> isUltraBeast;
  final Value<bool> isBaby;
  final Value<int?> evolutionChainId;
  final Value<int?> captureRate;
  final Value<int?> baseHappiness;
  final Value<int?> genderRate;
  final Value<int?> hatchCounter;
  final Value<String?> growthRate;
  final Value<String?> eggGroup1;
  final Value<String?> eggGroup2;
  final Value<String?> color;
  final Value<String?> shape;
  final Value<String?> habitat;
  final Value<int> rowid;
  const SpeciesCompanion({
    this.id = const Value.absent(),
    this.nationalDex = const Value.absent(),
    this.generationId = const Value.absent(),
    this.nameZhHans = const Value.absent(),
    this.nameZhHant = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.nameJa = const Value.absent(),
    this.nameJaHrkt = const Value.absent(),
    this.nameRoomaji = const Value.absent(),
    this.genusZhHans = const Value.absent(),
    this.genusEn = const Value.absent(),
    this.isLegendary = const Value.absent(),
    this.isMythical = const Value.absent(),
    this.isUltraBeast = const Value.absent(),
    this.isBaby = const Value.absent(),
    this.evolutionChainId = const Value.absent(),
    this.captureRate = const Value.absent(),
    this.baseHappiness = const Value.absent(),
    this.genderRate = const Value.absent(),
    this.hatchCounter = const Value.absent(),
    this.growthRate = const Value.absent(),
    this.eggGroup1 = const Value.absent(),
    this.eggGroup2 = const Value.absent(),
    this.color = const Value.absent(),
    this.shape = const Value.absent(),
    this.habitat = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SpeciesCompanion.insert({
    required int id,
    required int nationalDex,
    required int generationId,
    required String nameZhHans,
    required String nameZhHant,
    required String nameEn,
    required String nameJa,
    required String nameJaHrkt,
    this.nameRoomaji = const Value.absent(),
    this.genusZhHans = const Value.absent(),
    this.genusEn = const Value.absent(),
    required bool isLegendary,
    required bool isMythical,
    required bool isUltraBeast,
    required bool isBaby,
    this.evolutionChainId = const Value.absent(),
    this.captureRate = const Value.absent(),
    this.baseHappiness = const Value.absent(),
    this.genderRate = const Value.absent(),
    this.hatchCounter = const Value.absent(),
    this.growthRate = const Value.absent(),
    this.eggGroup1 = const Value.absent(),
    this.eggGroup2 = const Value.absent(),
    this.color = const Value.absent(),
    this.shape = const Value.absent(),
    this.habitat = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        nationalDex = Value(nationalDex),
        generationId = Value(generationId),
        nameZhHans = Value(nameZhHans),
        nameZhHant = Value(nameZhHant),
        nameEn = Value(nameEn),
        nameJa = Value(nameJa),
        nameJaHrkt = Value(nameJaHrkt),
        isLegendary = Value(isLegendary),
        isMythical = Value(isMythical),
        isUltraBeast = Value(isUltraBeast),
        isBaby = Value(isBaby);
  static Insertable<SpeciesRow> custom({
    Expression<int>? id,
    Expression<int>? nationalDex,
    Expression<int>? generationId,
    Expression<String>? nameZhHans,
    Expression<String>? nameZhHant,
    Expression<String>? nameEn,
    Expression<String>? nameJa,
    Expression<String>? nameJaHrkt,
    Expression<String>? nameRoomaji,
    Expression<String>? genusZhHans,
    Expression<String>? genusEn,
    Expression<bool>? isLegendary,
    Expression<bool>? isMythical,
    Expression<bool>? isUltraBeast,
    Expression<bool>? isBaby,
    Expression<int>? evolutionChainId,
    Expression<int>? captureRate,
    Expression<int>? baseHappiness,
    Expression<int>? genderRate,
    Expression<int>? hatchCounter,
    Expression<String>? growthRate,
    Expression<String>? eggGroup1,
    Expression<String>? eggGroup2,
    Expression<String>? color,
    Expression<String>? shape,
    Expression<String>? habitat,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nationalDex != null) 'national_dex': nationalDex,
      if (generationId != null) 'generation_id': generationId,
      if (nameZhHans != null) 'name_zh_hans': nameZhHans,
      if (nameZhHant != null) 'name_zh_hant': nameZhHant,
      if (nameEn != null) 'name_en': nameEn,
      if (nameJa != null) 'name_ja': nameJa,
      if (nameJaHrkt != null) 'name_ja_hrkt': nameJaHrkt,
      if (nameRoomaji != null) 'name_roomaji': nameRoomaji,
      if (genusZhHans != null) 'genus_zh_hans': genusZhHans,
      if (genusEn != null) 'genus_en': genusEn,
      if (isLegendary != null) 'is_legendary': isLegendary,
      if (isMythical != null) 'is_mythical': isMythical,
      if (isUltraBeast != null) 'is_ultra_beast': isUltraBeast,
      if (isBaby != null) 'is_baby': isBaby,
      if (evolutionChainId != null) 'evolution_chain_id': evolutionChainId,
      if (captureRate != null) 'capture_rate': captureRate,
      if (baseHappiness != null) 'base_happiness': baseHappiness,
      if (genderRate != null) 'gender_rate': genderRate,
      if (hatchCounter != null) 'hatch_counter': hatchCounter,
      if (growthRate != null) 'growth_rate': growthRate,
      if (eggGroup1 != null) 'egg_group_1': eggGroup1,
      if (eggGroup2 != null) 'egg_group_2': eggGroup2,
      if (color != null) 'color': color,
      if (shape != null) 'shape': shape,
      if (habitat != null) 'habitat': habitat,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SpeciesCompanion copyWith(
      {Value<int>? id,
      Value<int>? nationalDex,
      Value<int>? generationId,
      Value<String>? nameZhHans,
      Value<String>? nameZhHant,
      Value<String>? nameEn,
      Value<String>? nameJa,
      Value<String>? nameJaHrkt,
      Value<String?>? nameRoomaji,
      Value<String?>? genusZhHans,
      Value<String?>? genusEn,
      Value<bool>? isLegendary,
      Value<bool>? isMythical,
      Value<bool>? isUltraBeast,
      Value<bool>? isBaby,
      Value<int?>? evolutionChainId,
      Value<int?>? captureRate,
      Value<int?>? baseHappiness,
      Value<int?>? genderRate,
      Value<int?>? hatchCounter,
      Value<String?>? growthRate,
      Value<String?>? eggGroup1,
      Value<String?>? eggGroup2,
      Value<String?>? color,
      Value<String?>? shape,
      Value<String?>? habitat,
      Value<int>? rowid}) {
    return SpeciesCompanion(
      id: id ?? this.id,
      nationalDex: nationalDex ?? this.nationalDex,
      generationId: generationId ?? this.generationId,
      nameZhHans: nameZhHans ?? this.nameZhHans,
      nameZhHant: nameZhHant ?? this.nameZhHant,
      nameEn: nameEn ?? this.nameEn,
      nameJa: nameJa ?? this.nameJa,
      nameJaHrkt: nameJaHrkt ?? this.nameJaHrkt,
      nameRoomaji: nameRoomaji ?? this.nameRoomaji,
      genusZhHans: genusZhHans ?? this.genusZhHans,
      genusEn: genusEn ?? this.genusEn,
      isLegendary: isLegendary ?? this.isLegendary,
      isMythical: isMythical ?? this.isMythical,
      isUltraBeast: isUltraBeast ?? this.isUltraBeast,
      isBaby: isBaby ?? this.isBaby,
      evolutionChainId: evolutionChainId ?? this.evolutionChainId,
      captureRate: captureRate ?? this.captureRate,
      baseHappiness: baseHappiness ?? this.baseHappiness,
      genderRate: genderRate ?? this.genderRate,
      hatchCounter: hatchCounter ?? this.hatchCounter,
      growthRate: growthRate ?? this.growthRate,
      eggGroup1: eggGroup1 ?? this.eggGroup1,
      eggGroup2: eggGroup2 ?? this.eggGroup2,
      color: color ?? this.color,
      shape: shape ?? this.shape,
      habitat: habitat ?? this.habitat,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nationalDex.present) {
      map['national_dex'] = Variable<int>(nationalDex.value);
    }
    if (generationId.present) {
      map['generation_id'] = Variable<int>(generationId.value);
    }
    if (nameZhHans.present) {
      map['name_zh_hans'] = Variable<String>(nameZhHans.value);
    }
    if (nameZhHant.present) {
      map['name_zh_hant'] = Variable<String>(nameZhHant.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (nameJa.present) {
      map['name_ja'] = Variable<String>(nameJa.value);
    }
    if (nameJaHrkt.present) {
      map['name_ja_hrkt'] = Variable<String>(nameJaHrkt.value);
    }
    if (nameRoomaji.present) {
      map['name_roomaji'] = Variable<String>(nameRoomaji.value);
    }
    if (genusZhHans.present) {
      map['genus_zh_hans'] = Variable<String>(genusZhHans.value);
    }
    if (genusEn.present) {
      map['genus_en'] = Variable<String>(genusEn.value);
    }
    if (isLegendary.present) {
      map['is_legendary'] = Variable<bool>(isLegendary.value);
    }
    if (isMythical.present) {
      map['is_mythical'] = Variable<bool>(isMythical.value);
    }
    if (isUltraBeast.present) {
      map['is_ultra_beast'] = Variable<bool>(isUltraBeast.value);
    }
    if (isBaby.present) {
      map['is_baby'] = Variable<bool>(isBaby.value);
    }
    if (evolutionChainId.present) {
      map['evolution_chain_id'] = Variable<int>(evolutionChainId.value);
    }
    if (captureRate.present) {
      map['capture_rate'] = Variable<int>(captureRate.value);
    }
    if (baseHappiness.present) {
      map['base_happiness'] = Variable<int>(baseHappiness.value);
    }
    if (genderRate.present) {
      map['gender_rate'] = Variable<int>(genderRate.value);
    }
    if (hatchCounter.present) {
      map['hatch_counter'] = Variable<int>(hatchCounter.value);
    }
    if (growthRate.present) {
      map['growth_rate'] = Variable<String>(growthRate.value);
    }
    if (eggGroup1.present) {
      map['egg_group_1'] = Variable<String>(eggGroup1.value);
    }
    if (eggGroup2.present) {
      map['egg_group_2'] = Variable<String>(eggGroup2.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (shape.present) {
      map['shape'] = Variable<String>(shape.value);
    }
    if (habitat.present) {
      map['habitat'] = Variable<String>(habitat.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SpeciesCompanion(')
          ..write('id: $id, ')
          ..write('nationalDex: $nationalDex, ')
          ..write('generationId: $generationId, ')
          ..write('nameZhHans: $nameZhHans, ')
          ..write('nameZhHant: $nameZhHant, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameJa: $nameJa, ')
          ..write('nameJaHrkt: $nameJaHrkt, ')
          ..write('nameRoomaji: $nameRoomaji, ')
          ..write('genusZhHans: $genusZhHans, ')
          ..write('genusEn: $genusEn, ')
          ..write('isLegendary: $isLegendary, ')
          ..write('isMythical: $isMythical, ')
          ..write('isUltraBeast: $isUltraBeast, ')
          ..write('isBaby: $isBaby, ')
          ..write('evolutionChainId: $evolutionChainId, ')
          ..write('captureRate: $captureRate, ')
          ..write('baseHappiness: $baseHappiness, ')
          ..write('genderRate: $genderRate, ')
          ..write('hatchCounter: $hatchCounter, ')
          ..write('growthRate: $growthRate, ')
          ..write('eggGroup1: $eggGroup1, ')
          ..write('eggGroup2: $eggGroup2, ')
          ..write('color: $color, ')
          ..write('shape: $shape, ')
          ..write('habitat: $habitat, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FormsTable extends Forms with TableInfo<$FormsTable, FormsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FormsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _speciesIdMeta =
      const VerificationMeta('speciesId');
  @override
  late final GeneratedColumn<int> speciesId = GeneratedColumn<int>(
      'species_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _formIdentifierMeta =
      const VerificationMeta('formIdentifier');
  @override
  late final GeneratedColumn<String> formIdentifier = GeneratedColumn<String>(
      'form_identifier', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _formNameZhMeta =
      const VerificationMeta('formNameZh');
  @override
  late final GeneratedColumn<String> formNameZh = GeneratedColumn<String>(
      'form_name_zh', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _formNameEnMeta =
      const VerificationMeta('formNameEn');
  @override
  late final GeneratedColumn<String> formNameEn = GeneratedColumn<String>(
      'form_name_en', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isDefaultMeta =
      const VerificationMeta('isDefault');
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
      'is_default', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_default" IN (0, 1))'));
  static const VerificationMeta _isMegaMeta = const VerificationMeta('isMega');
  @override
  late final GeneratedColumn<bool> isMega = GeneratedColumn<bool>(
      'is_mega', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_mega" IN (0, 1))'));
  static const VerificationMeta _isGmaxMeta = const VerificationMeta('isGmax');
  @override
  late final GeneratedColumn<bool> isGmax = GeneratedColumn<bool>(
      'is_gmax', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_gmax" IN (0, 1))'));
  static const VerificationMeta _isRegionalMeta =
      const VerificationMeta('isRegional');
  @override
  late final GeneratedColumn<bool> isRegional = GeneratedColumn<bool>(
      'is_regional', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_regional" IN (0, 1))'));
  static const VerificationMeta _isBattleOnlyMeta =
      const VerificationMeta('isBattleOnly');
  @override
  late final GeneratedColumn<bool> isBattleOnly = GeneratedColumn<bool>(
      'is_battle_only', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_battle_only" IN (0, 1))'));
  static const VerificationMeta _formOrderMeta =
      const VerificationMeta('formOrder');
  @override
  late final GeneratedColumn<int> formOrder = GeneratedColumn<int>(
      'form_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
      'height', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<int> weight = GeneratedColumn<int>(
      'weight', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _baseExperienceMeta =
      const VerificationMeta('baseExperience');
  @override
  late final GeneratedColumn<int> baseExperience = GeneratedColumn<int>(
      'base_experience', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _hasGenderDifferenceMeta =
      const VerificationMeta('hasGenderDifference');
  @override
  late final GeneratedColumn<bool> hasGenderDifference = GeneratedColumn<bool>(
      'has_gender_difference', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("has_gender_difference" IN (0, 1))'));
  static const VerificationMeta _artworkAssetMeta =
      const VerificationMeta('artworkAsset');
  @override
  late final GeneratedColumn<String> artworkAsset = GeneratedColumn<String>(
      'artwork_asset', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _thumbAssetMeta =
      const VerificationMeta('thumbAsset');
  @override
  late final GeneratedColumn<String> thumbAsset = GeneratedColumn<String>(
      'thumb_asset', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        speciesId,
        formIdentifier,
        formNameZh,
        formNameEn,
        isDefault,
        isMega,
        isGmax,
        isRegional,
        isBattleOnly,
        formOrder,
        height,
        weight,
        baseExperience,
        hasGenderDifference,
        artworkAsset,
        thumbAsset
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'forms';
  @override
  VerificationContext validateIntegrity(Insertable<FormsRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('species_id')) {
      context.handle(_speciesIdMeta,
          speciesId.isAcceptableOrUnknown(data['species_id']!, _speciesIdMeta));
    } else if (isInserting) {
      context.missing(_speciesIdMeta);
    }
    if (data.containsKey('form_identifier')) {
      context.handle(
          _formIdentifierMeta,
          formIdentifier.isAcceptableOrUnknown(
              data['form_identifier']!, _formIdentifierMeta));
    }
    if (data.containsKey('form_name_zh')) {
      context.handle(
          _formNameZhMeta,
          formNameZh.isAcceptableOrUnknown(
              data['form_name_zh']!, _formNameZhMeta));
    } else if (isInserting) {
      context.missing(_formNameZhMeta);
    }
    if (data.containsKey('form_name_en')) {
      context.handle(
          _formNameEnMeta,
          formNameEn.isAcceptableOrUnknown(
              data['form_name_en']!, _formNameEnMeta));
    } else if (isInserting) {
      context.missing(_formNameEnMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(_isDefaultMeta,
          isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta));
    } else if (isInserting) {
      context.missing(_isDefaultMeta);
    }
    if (data.containsKey('is_mega')) {
      context.handle(_isMegaMeta,
          isMega.isAcceptableOrUnknown(data['is_mega']!, _isMegaMeta));
    } else if (isInserting) {
      context.missing(_isMegaMeta);
    }
    if (data.containsKey('is_gmax')) {
      context.handle(_isGmaxMeta,
          isGmax.isAcceptableOrUnknown(data['is_gmax']!, _isGmaxMeta));
    } else if (isInserting) {
      context.missing(_isGmaxMeta);
    }
    if (data.containsKey('is_regional')) {
      context.handle(
          _isRegionalMeta,
          isRegional.isAcceptableOrUnknown(
              data['is_regional']!, _isRegionalMeta));
    } else if (isInserting) {
      context.missing(_isRegionalMeta);
    }
    if (data.containsKey('is_battle_only')) {
      context.handle(
          _isBattleOnlyMeta,
          isBattleOnly.isAcceptableOrUnknown(
              data['is_battle_only']!, _isBattleOnlyMeta));
    } else if (isInserting) {
      context.missing(_isBattleOnlyMeta);
    }
    if (data.containsKey('form_order')) {
      context.handle(_formOrderMeta,
          formOrder.isAcceptableOrUnknown(data['form_order']!, _formOrderMeta));
    } else if (isInserting) {
      context.missing(_formOrderMeta);
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    }
    if (data.containsKey('base_experience')) {
      context.handle(
          _baseExperienceMeta,
          baseExperience.isAcceptableOrUnknown(
              data['base_experience']!, _baseExperienceMeta));
    }
    if (data.containsKey('has_gender_difference')) {
      context.handle(
          _hasGenderDifferenceMeta,
          hasGenderDifference.isAcceptableOrUnknown(
              data['has_gender_difference']!, _hasGenderDifferenceMeta));
    } else if (isInserting) {
      context.missing(_hasGenderDifferenceMeta);
    }
    if (data.containsKey('artwork_asset')) {
      context.handle(
          _artworkAssetMeta,
          artworkAsset.isAcceptableOrUnknown(
              data['artwork_asset']!, _artworkAssetMeta));
    }
    if (data.containsKey('thumb_asset')) {
      context.handle(
          _thumbAssetMeta,
          thumbAsset.isAcceptableOrUnknown(
              data['thumb_asset']!, _thumbAssetMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  FormsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FormsRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      speciesId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}species_id'])!,
      formIdentifier: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}form_identifier']),
      formNameZh: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}form_name_zh'])!,
      formNameEn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}form_name_en'])!,
      isDefault: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_default'])!,
      isMega: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_mega'])!,
      isGmax: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_gmax'])!,
      isRegional: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_regional'])!,
      isBattleOnly: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_battle_only'])!,
      formOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}form_order'])!,
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}height']),
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}weight']),
      baseExperience: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}base_experience']),
      hasGenderDifference: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}has_gender_difference'])!,
      artworkAsset: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artwork_asset']),
      thumbAsset: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumb_asset']),
    );
  }

  @override
  $FormsTable createAlias(String alias) {
    return $FormsTable(attachedDatabase, alias);
  }
}

class FormsRow extends DataClass implements Insertable<FormsRow> {
  final int id;
  final int speciesId;
  final String? formIdentifier;
  final String formNameZh;
  final String formNameEn;
  final bool isDefault;
  final bool isMega;
  final bool isGmax;
  final bool isRegional;
  final bool isBattleOnly;
  final int formOrder;
  final int? height;
  final int? weight;
  final int? baseExperience;
  final bool hasGenderDifference;
  final String? artworkAsset;
  final String? thumbAsset;
  const FormsRow(
      {required this.id,
      required this.speciesId,
      this.formIdentifier,
      required this.formNameZh,
      required this.formNameEn,
      required this.isDefault,
      required this.isMega,
      required this.isGmax,
      required this.isRegional,
      required this.isBattleOnly,
      required this.formOrder,
      this.height,
      this.weight,
      this.baseExperience,
      required this.hasGenderDifference,
      this.artworkAsset,
      this.thumbAsset});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['species_id'] = Variable<int>(speciesId);
    if (!nullToAbsent || formIdentifier != null) {
      map['form_identifier'] = Variable<String>(formIdentifier);
    }
    map['form_name_zh'] = Variable<String>(formNameZh);
    map['form_name_en'] = Variable<String>(formNameEn);
    map['is_default'] = Variable<bool>(isDefault);
    map['is_mega'] = Variable<bool>(isMega);
    map['is_gmax'] = Variable<bool>(isGmax);
    map['is_regional'] = Variable<bool>(isRegional);
    map['is_battle_only'] = Variable<bool>(isBattleOnly);
    map['form_order'] = Variable<int>(formOrder);
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || weight != null) {
      map['weight'] = Variable<int>(weight);
    }
    if (!nullToAbsent || baseExperience != null) {
      map['base_experience'] = Variable<int>(baseExperience);
    }
    map['has_gender_difference'] = Variable<bool>(hasGenderDifference);
    if (!nullToAbsent || artworkAsset != null) {
      map['artwork_asset'] = Variable<String>(artworkAsset);
    }
    if (!nullToAbsent || thumbAsset != null) {
      map['thumb_asset'] = Variable<String>(thumbAsset);
    }
    return map;
  }

  FormsCompanion toCompanion(bool nullToAbsent) {
    return FormsCompanion(
      id: Value(id),
      speciesId: Value(speciesId),
      formIdentifier: formIdentifier == null && nullToAbsent
          ? const Value.absent()
          : Value(formIdentifier),
      formNameZh: Value(formNameZh),
      formNameEn: Value(formNameEn),
      isDefault: Value(isDefault),
      isMega: Value(isMega),
      isGmax: Value(isGmax),
      isRegional: Value(isRegional),
      isBattleOnly: Value(isBattleOnly),
      formOrder: Value(formOrder),
      height:
          height == null && nullToAbsent ? const Value.absent() : Value(height),
      weight:
          weight == null && nullToAbsent ? const Value.absent() : Value(weight),
      baseExperience: baseExperience == null && nullToAbsent
          ? const Value.absent()
          : Value(baseExperience),
      hasGenderDifference: Value(hasGenderDifference),
      artworkAsset: artworkAsset == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkAsset),
      thumbAsset: thumbAsset == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbAsset),
    );
  }

  factory FormsRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FormsRow(
      id: serializer.fromJson<int>(json['id']),
      speciesId: serializer.fromJson<int>(json['speciesId']),
      formIdentifier: serializer.fromJson<String?>(json['formIdentifier']),
      formNameZh: serializer.fromJson<String>(json['formNameZh']),
      formNameEn: serializer.fromJson<String>(json['formNameEn']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      isMega: serializer.fromJson<bool>(json['isMega']),
      isGmax: serializer.fromJson<bool>(json['isGmax']),
      isRegional: serializer.fromJson<bool>(json['isRegional']),
      isBattleOnly: serializer.fromJson<bool>(json['isBattleOnly']),
      formOrder: serializer.fromJson<int>(json['formOrder']),
      height: serializer.fromJson<int?>(json['height']),
      weight: serializer.fromJson<int?>(json['weight']),
      baseExperience: serializer.fromJson<int?>(json['baseExperience']),
      hasGenderDifference:
          serializer.fromJson<bool>(json['hasGenderDifference']),
      artworkAsset: serializer.fromJson<String?>(json['artworkAsset']),
      thumbAsset: serializer.fromJson<String?>(json['thumbAsset']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'speciesId': serializer.toJson<int>(speciesId),
      'formIdentifier': serializer.toJson<String?>(formIdentifier),
      'formNameZh': serializer.toJson<String>(formNameZh),
      'formNameEn': serializer.toJson<String>(formNameEn),
      'isDefault': serializer.toJson<bool>(isDefault),
      'isMega': serializer.toJson<bool>(isMega),
      'isGmax': serializer.toJson<bool>(isGmax),
      'isRegional': serializer.toJson<bool>(isRegional),
      'isBattleOnly': serializer.toJson<bool>(isBattleOnly),
      'formOrder': serializer.toJson<int>(formOrder),
      'height': serializer.toJson<int?>(height),
      'weight': serializer.toJson<int?>(weight),
      'baseExperience': serializer.toJson<int?>(baseExperience),
      'hasGenderDifference': serializer.toJson<bool>(hasGenderDifference),
      'artworkAsset': serializer.toJson<String?>(artworkAsset),
      'thumbAsset': serializer.toJson<String?>(thumbAsset),
    };
  }

  FormsRow copyWith(
          {int? id,
          int? speciesId,
          Value<String?> formIdentifier = const Value.absent(),
          String? formNameZh,
          String? formNameEn,
          bool? isDefault,
          bool? isMega,
          bool? isGmax,
          bool? isRegional,
          bool? isBattleOnly,
          int? formOrder,
          Value<int?> height = const Value.absent(),
          Value<int?> weight = const Value.absent(),
          Value<int?> baseExperience = const Value.absent(),
          bool? hasGenderDifference,
          Value<String?> artworkAsset = const Value.absent(),
          Value<String?> thumbAsset = const Value.absent()}) =>
      FormsRow(
        id: id ?? this.id,
        speciesId: speciesId ?? this.speciesId,
        formIdentifier:
            formIdentifier.present ? formIdentifier.value : this.formIdentifier,
        formNameZh: formNameZh ?? this.formNameZh,
        formNameEn: formNameEn ?? this.formNameEn,
        isDefault: isDefault ?? this.isDefault,
        isMega: isMega ?? this.isMega,
        isGmax: isGmax ?? this.isGmax,
        isRegional: isRegional ?? this.isRegional,
        isBattleOnly: isBattleOnly ?? this.isBattleOnly,
        formOrder: formOrder ?? this.formOrder,
        height: height.present ? height.value : this.height,
        weight: weight.present ? weight.value : this.weight,
        baseExperience:
            baseExperience.present ? baseExperience.value : this.baseExperience,
        hasGenderDifference: hasGenderDifference ?? this.hasGenderDifference,
        artworkAsset:
            artworkAsset.present ? artworkAsset.value : this.artworkAsset,
        thumbAsset: thumbAsset.present ? thumbAsset.value : this.thumbAsset,
      );
  FormsRow copyWithCompanion(FormsCompanion data) {
    return FormsRow(
      id: data.id.present ? data.id.value : this.id,
      speciesId: data.speciesId.present ? data.speciesId.value : this.speciesId,
      formIdentifier: data.formIdentifier.present
          ? data.formIdentifier.value
          : this.formIdentifier,
      formNameZh:
          data.formNameZh.present ? data.formNameZh.value : this.formNameZh,
      formNameEn:
          data.formNameEn.present ? data.formNameEn.value : this.formNameEn,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      isMega: data.isMega.present ? data.isMega.value : this.isMega,
      isGmax: data.isGmax.present ? data.isGmax.value : this.isGmax,
      isRegional:
          data.isRegional.present ? data.isRegional.value : this.isRegional,
      isBattleOnly: data.isBattleOnly.present
          ? data.isBattleOnly.value
          : this.isBattleOnly,
      formOrder: data.formOrder.present ? data.formOrder.value : this.formOrder,
      height: data.height.present ? data.height.value : this.height,
      weight: data.weight.present ? data.weight.value : this.weight,
      baseExperience: data.baseExperience.present
          ? data.baseExperience.value
          : this.baseExperience,
      hasGenderDifference: data.hasGenderDifference.present
          ? data.hasGenderDifference.value
          : this.hasGenderDifference,
      artworkAsset: data.artworkAsset.present
          ? data.artworkAsset.value
          : this.artworkAsset,
      thumbAsset:
          data.thumbAsset.present ? data.thumbAsset.value : this.thumbAsset,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FormsRow(')
          ..write('id: $id, ')
          ..write('speciesId: $speciesId, ')
          ..write('formIdentifier: $formIdentifier, ')
          ..write('formNameZh: $formNameZh, ')
          ..write('formNameEn: $formNameEn, ')
          ..write('isDefault: $isDefault, ')
          ..write('isMega: $isMega, ')
          ..write('isGmax: $isGmax, ')
          ..write('isRegional: $isRegional, ')
          ..write('isBattleOnly: $isBattleOnly, ')
          ..write('formOrder: $formOrder, ')
          ..write('height: $height, ')
          ..write('weight: $weight, ')
          ..write('baseExperience: $baseExperience, ')
          ..write('hasGenderDifference: $hasGenderDifference, ')
          ..write('artworkAsset: $artworkAsset, ')
          ..write('thumbAsset: $thumbAsset')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      speciesId,
      formIdentifier,
      formNameZh,
      formNameEn,
      isDefault,
      isMega,
      isGmax,
      isRegional,
      isBattleOnly,
      formOrder,
      height,
      weight,
      baseExperience,
      hasGenderDifference,
      artworkAsset,
      thumbAsset);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FormsRow &&
          other.id == this.id &&
          other.speciesId == this.speciesId &&
          other.formIdentifier == this.formIdentifier &&
          other.formNameZh == this.formNameZh &&
          other.formNameEn == this.formNameEn &&
          other.isDefault == this.isDefault &&
          other.isMega == this.isMega &&
          other.isGmax == this.isGmax &&
          other.isRegional == this.isRegional &&
          other.isBattleOnly == this.isBattleOnly &&
          other.formOrder == this.formOrder &&
          other.height == this.height &&
          other.weight == this.weight &&
          other.baseExperience == this.baseExperience &&
          other.hasGenderDifference == this.hasGenderDifference &&
          other.artworkAsset == this.artworkAsset &&
          other.thumbAsset == this.thumbAsset);
}

class FormsCompanion extends UpdateCompanion<FormsRow> {
  final Value<int> id;
  final Value<int> speciesId;
  final Value<String?> formIdentifier;
  final Value<String> formNameZh;
  final Value<String> formNameEn;
  final Value<bool> isDefault;
  final Value<bool> isMega;
  final Value<bool> isGmax;
  final Value<bool> isRegional;
  final Value<bool> isBattleOnly;
  final Value<int> formOrder;
  final Value<int?> height;
  final Value<int?> weight;
  final Value<int?> baseExperience;
  final Value<bool> hasGenderDifference;
  final Value<String?> artworkAsset;
  final Value<String?> thumbAsset;
  final Value<int> rowid;
  const FormsCompanion({
    this.id = const Value.absent(),
    this.speciesId = const Value.absent(),
    this.formIdentifier = const Value.absent(),
    this.formNameZh = const Value.absent(),
    this.formNameEn = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.isMega = const Value.absent(),
    this.isGmax = const Value.absent(),
    this.isRegional = const Value.absent(),
    this.isBattleOnly = const Value.absent(),
    this.formOrder = const Value.absent(),
    this.height = const Value.absent(),
    this.weight = const Value.absent(),
    this.baseExperience = const Value.absent(),
    this.hasGenderDifference = const Value.absent(),
    this.artworkAsset = const Value.absent(),
    this.thumbAsset = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FormsCompanion.insert({
    required int id,
    required int speciesId,
    this.formIdentifier = const Value.absent(),
    required String formNameZh,
    required String formNameEn,
    required bool isDefault,
    required bool isMega,
    required bool isGmax,
    required bool isRegional,
    required bool isBattleOnly,
    required int formOrder,
    this.height = const Value.absent(),
    this.weight = const Value.absent(),
    this.baseExperience = const Value.absent(),
    required bool hasGenderDifference,
    this.artworkAsset = const Value.absent(),
    this.thumbAsset = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        speciesId = Value(speciesId),
        formNameZh = Value(formNameZh),
        formNameEn = Value(formNameEn),
        isDefault = Value(isDefault),
        isMega = Value(isMega),
        isGmax = Value(isGmax),
        isRegional = Value(isRegional),
        isBattleOnly = Value(isBattleOnly),
        formOrder = Value(formOrder),
        hasGenderDifference = Value(hasGenderDifference);
  static Insertable<FormsRow> custom({
    Expression<int>? id,
    Expression<int>? speciesId,
    Expression<String>? formIdentifier,
    Expression<String>? formNameZh,
    Expression<String>? formNameEn,
    Expression<bool>? isDefault,
    Expression<bool>? isMega,
    Expression<bool>? isGmax,
    Expression<bool>? isRegional,
    Expression<bool>? isBattleOnly,
    Expression<int>? formOrder,
    Expression<int>? height,
    Expression<int>? weight,
    Expression<int>? baseExperience,
    Expression<bool>? hasGenderDifference,
    Expression<String>? artworkAsset,
    Expression<String>? thumbAsset,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (speciesId != null) 'species_id': speciesId,
      if (formIdentifier != null) 'form_identifier': formIdentifier,
      if (formNameZh != null) 'form_name_zh': formNameZh,
      if (formNameEn != null) 'form_name_en': formNameEn,
      if (isDefault != null) 'is_default': isDefault,
      if (isMega != null) 'is_mega': isMega,
      if (isGmax != null) 'is_gmax': isGmax,
      if (isRegional != null) 'is_regional': isRegional,
      if (isBattleOnly != null) 'is_battle_only': isBattleOnly,
      if (formOrder != null) 'form_order': formOrder,
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (baseExperience != null) 'base_experience': baseExperience,
      if (hasGenderDifference != null)
        'has_gender_difference': hasGenderDifference,
      if (artworkAsset != null) 'artwork_asset': artworkAsset,
      if (thumbAsset != null) 'thumb_asset': thumbAsset,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FormsCompanion copyWith(
      {Value<int>? id,
      Value<int>? speciesId,
      Value<String?>? formIdentifier,
      Value<String>? formNameZh,
      Value<String>? formNameEn,
      Value<bool>? isDefault,
      Value<bool>? isMega,
      Value<bool>? isGmax,
      Value<bool>? isRegional,
      Value<bool>? isBattleOnly,
      Value<int>? formOrder,
      Value<int?>? height,
      Value<int?>? weight,
      Value<int?>? baseExperience,
      Value<bool>? hasGenderDifference,
      Value<String?>? artworkAsset,
      Value<String?>? thumbAsset,
      Value<int>? rowid}) {
    return FormsCompanion(
      id: id ?? this.id,
      speciesId: speciesId ?? this.speciesId,
      formIdentifier: formIdentifier ?? this.formIdentifier,
      formNameZh: formNameZh ?? this.formNameZh,
      formNameEn: formNameEn ?? this.formNameEn,
      isDefault: isDefault ?? this.isDefault,
      isMega: isMega ?? this.isMega,
      isGmax: isGmax ?? this.isGmax,
      isRegional: isRegional ?? this.isRegional,
      isBattleOnly: isBattleOnly ?? this.isBattleOnly,
      formOrder: formOrder ?? this.formOrder,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      baseExperience: baseExperience ?? this.baseExperience,
      hasGenderDifference: hasGenderDifference ?? this.hasGenderDifference,
      artworkAsset: artworkAsset ?? this.artworkAsset,
      thumbAsset: thumbAsset ?? this.thumbAsset,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (speciesId.present) {
      map['species_id'] = Variable<int>(speciesId.value);
    }
    if (formIdentifier.present) {
      map['form_identifier'] = Variable<String>(formIdentifier.value);
    }
    if (formNameZh.present) {
      map['form_name_zh'] = Variable<String>(formNameZh.value);
    }
    if (formNameEn.present) {
      map['form_name_en'] = Variable<String>(formNameEn.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (isMega.present) {
      map['is_mega'] = Variable<bool>(isMega.value);
    }
    if (isGmax.present) {
      map['is_gmax'] = Variable<bool>(isGmax.value);
    }
    if (isRegional.present) {
      map['is_regional'] = Variable<bool>(isRegional.value);
    }
    if (isBattleOnly.present) {
      map['is_battle_only'] = Variable<bool>(isBattleOnly.value);
    }
    if (formOrder.present) {
      map['form_order'] = Variable<int>(formOrder.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (weight.present) {
      map['weight'] = Variable<int>(weight.value);
    }
    if (baseExperience.present) {
      map['base_experience'] = Variable<int>(baseExperience.value);
    }
    if (hasGenderDifference.present) {
      map['has_gender_difference'] = Variable<bool>(hasGenderDifference.value);
    }
    if (artworkAsset.present) {
      map['artwork_asset'] = Variable<String>(artworkAsset.value);
    }
    if (thumbAsset.present) {
      map['thumb_asset'] = Variable<String>(thumbAsset.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FormsCompanion(')
          ..write('id: $id, ')
          ..write('speciesId: $speciesId, ')
          ..write('formIdentifier: $formIdentifier, ')
          ..write('formNameZh: $formNameZh, ')
          ..write('formNameEn: $formNameEn, ')
          ..write('isDefault: $isDefault, ')
          ..write('isMega: $isMega, ')
          ..write('isGmax: $isGmax, ')
          ..write('isRegional: $isRegional, ')
          ..write('isBattleOnly: $isBattleOnly, ')
          ..write('formOrder: $formOrder, ')
          ..write('height: $height, ')
          ..write('weight: $weight, ')
          ..write('baseExperience: $baseExperience, ')
          ..write('hasGenderDifference: $hasGenderDifference, ')
          ..write('artworkAsset: $artworkAsset, ')
          ..write('thumbAsset: $thumbAsset, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FormTypesTable extends FormTypes
    with TableInfo<$FormTypesTable, FormTypesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FormTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _formIdMeta = const VerificationMeta('formId');
  @override
  late final GeneratedColumn<int> formId = GeneratedColumn<int>(
      'form_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<int> slot = GeneratedColumn<int>(
      'slot', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _typeIdMeta = const VerificationMeta('typeId');
  @override
  late final GeneratedColumn<int> typeId = GeneratedColumn<int>(
      'type_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [formId, slot, typeId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'form_types';
  @override
  VerificationContext validateIntegrity(Insertable<FormTypesRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('form_id')) {
      context.handle(_formIdMeta,
          formId.isAcceptableOrUnknown(data['form_id']!, _formIdMeta));
    } else if (isInserting) {
      context.missing(_formIdMeta);
    }
    if (data.containsKey('slot')) {
      context.handle(
          _slotMeta, slot.isAcceptableOrUnknown(data['slot']!, _slotMeta));
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('type_id')) {
      context.handle(_typeIdMeta,
          typeId.isAcceptableOrUnknown(data['type_id']!, _typeIdMeta));
    } else if (isInserting) {
      context.missing(_typeIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {formId, slot};
  @override
  FormTypesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FormTypesRow(
      formId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}form_id'])!,
      slot: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}slot'])!,
      typeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type_id'])!,
    );
  }

  @override
  $FormTypesTable createAlias(String alias) {
    return $FormTypesTable(attachedDatabase, alias);
  }
}

class FormTypesRow extends DataClass implements Insertable<FormTypesRow> {
  final int formId;
  final int slot;
  final int typeId;
  const FormTypesRow(
      {required this.formId, required this.slot, required this.typeId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['form_id'] = Variable<int>(formId);
    map['slot'] = Variable<int>(slot);
    map['type_id'] = Variable<int>(typeId);
    return map;
  }

  FormTypesCompanion toCompanion(bool nullToAbsent) {
    return FormTypesCompanion(
      formId: Value(formId),
      slot: Value(slot),
      typeId: Value(typeId),
    );
  }

  factory FormTypesRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FormTypesRow(
      formId: serializer.fromJson<int>(json['formId']),
      slot: serializer.fromJson<int>(json['slot']),
      typeId: serializer.fromJson<int>(json['typeId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'formId': serializer.toJson<int>(formId),
      'slot': serializer.toJson<int>(slot),
      'typeId': serializer.toJson<int>(typeId),
    };
  }

  FormTypesRow copyWith({int? formId, int? slot, int? typeId}) => FormTypesRow(
        formId: formId ?? this.formId,
        slot: slot ?? this.slot,
        typeId: typeId ?? this.typeId,
      );
  FormTypesRow copyWithCompanion(FormTypesCompanion data) {
    return FormTypesRow(
      formId: data.formId.present ? data.formId.value : this.formId,
      slot: data.slot.present ? data.slot.value : this.slot,
      typeId: data.typeId.present ? data.typeId.value : this.typeId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FormTypesRow(')
          ..write('formId: $formId, ')
          ..write('slot: $slot, ')
          ..write('typeId: $typeId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(formId, slot, typeId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FormTypesRow &&
          other.formId == this.formId &&
          other.slot == this.slot &&
          other.typeId == this.typeId);
}

class FormTypesCompanion extends UpdateCompanion<FormTypesRow> {
  final Value<int> formId;
  final Value<int> slot;
  final Value<int> typeId;
  final Value<int> rowid;
  const FormTypesCompanion({
    this.formId = const Value.absent(),
    this.slot = const Value.absent(),
    this.typeId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FormTypesCompanion.insert({
    required int formId,
    required int slot,
    required int typeId,
    this.rowid = const Value.absent(),
  })  : formId = Value(formId),
        slot = Value(slot),
        typeId = Value(typeId);
  static Insertable<FormTypesRow> custom({
    Expression<int>? formId,
    Expression<int>? slot,
    Expression<int>? typeId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (formId != null) 'form_id': formId,
      if (slot != null) 'slot': slot,
      if (typeId != null) 'type_id': typeId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FormTypesCompanion copyWith(
      {Value<int>? formId,
      Value<int>? slot,
      Value<int>? typeId,
      Value<int>? rowid}) {
    return FormTypesCompanion(
      formId: formId ?? this.formId,
      slot: slot ?? this.slot,
      typeId: typeId ?? this.typeId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (formId.present) {
      map['form_id'] = Variable<int>(formId.value);
    }
    if (slot.present) {
      map['slot'] = Variable<int>(slot.value);
    }
    if (typeId.present) {
      map['type_id'] = Variable<int>(typeId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FormTypesCompanion(')
          ..write('formId: $formId, ')
          ..write('slot: $slot, ')
          ..write('typeId: $typeId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FormStatsTable extends FormStats
    with TableInfo<$FormStatsTable, FormStatsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FormStatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _formIdMeta = const VerificationMeta('formId');
  @override
  late final GeneratedColumn<int> formId = GeneratedColumn<int>(
      'form_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _statMeta = const VerificationMeta('stat');
  @override
  late final GeneratedColumn<String> stat = GeneratedColumn<String>(
      'stat', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _baseValueMeta =
      const VerificationMeta('baseValue');
  @override
  late final GeneratedColumn<int> baseValue = GeneratedColumn<int>(
      'base_value', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [formId, stat, baseValue];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'form_stats';
  @override
  VerificationContext validateIntegrity(Insertable<FormStatsRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('form_id')) {
      context.handle(_formIdMeta,
          formId.isAcceptableOrUnknown(data['form_id']!, _formIdMeta));
    } else if (isInserting) {
      context.missing(_formIdMeta);
    }
    if (data.containsKey('stat')) {
      context.handle(
          _statMeta, stat.isAcceptableOrUnknown(data['stat']!, _statMeta));
    } else if (isInserting) {
      context.missing(_statMeta);
    }
    if (data.containsKey('base_value')) {
      context.handle(_baseValueMeta,
          baseValue.isAcceptableOrUnknown(data['base_value']!, _baseValueMeta));
    } else if (isInserting) {
      context.missing(_baseValueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {formId, stat};
  @override
  FormStatsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FormStatsRow(
      formId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}form_id'])!,
      stat: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stat'])!,
      baseValue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}base_value'])!,
    );
  }

  @override
  $FormStatsTable createAlias(String alias) {
    return $FormStatsTable(attachedDatabase, alias);
  }
}

class FormStatsRow extends DataClass implements Insertable<FormStatsRow> {
  final int formId;
  final String stat;
  final int baseValue;
  const FormStatsRow(
      {required this.formId, required this.stat, required this.baseValue});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['form_id'] = Variable<int>(formId);
    map['stat'] = Variable<String>(stat);
    map['base_value'] = Variable<int>(baseValue);
    return map;
  }

  FormStatsCompanion toCompanion(bool nullToAbsent) {
    return FormStatsCompanion(
      formId: Value(formId),
      stat: Value(stat),
      baseValue: Value(baseValue),
    );
  }

  factory FormStatsRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FormStatsRow(
      formId: serializer.fromJson<int>(json['formId']),
      stat: serializer.fromJson<String>(json['stat']),
      baseValue: serializer.fromJson<int>(json['baseValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'formId': serializer.toJson<int>(formId),
      'stat': serializer.toJson<String>(stat),
      'baseValue': serializer.toJson<int>(baseValue),
    };
  }

  FormStatsRow copyWith({int? formId, String? stat, int? baseValue}) =>
      FormStatsRow(
        formId: formId ?? this.formId,
        stat: stat ?? this.stat,
        baseValue: baseValue ?? this.baseValue,
      );
  FormStatsRow copyWithCompanion(FormStatsCompanion data) {
    return FormStatsRow(
      formId: data.formId.present ? data.formId.value : this.formId,
      stat: data.stat.present ? data.stat.value : this.stat,
      baseValue: data.baseValue.present ? data.baseValue.value : this.baseValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FormStatsRow(')
          ..write('formId: $formId, ')
          ..write('stat: $stat, ')
          ..write('baseValue: $baseValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(formId, stat, baseValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FormStatsRow &&
          other.formId == this.formId &&
          other.stat == this.stat &&
          other.baseValue == this.baseValue);
}

class FormStatsCompanion extends UpdateCompanion<FormStatsRow> {
  final Value<int> formId;
  final Value<String> stat;
  final Value<int> baseValue;
  final Value<int> rowid;
  const FormStatsCompanion({
    this.formId = const Value.absent(),
    this.stat = const Value.absent(),
    this.baseValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FormStatsCompanion.insert({
    required int formId,
    required String stat,
    required int baseValue,
    this.rowid = const Value.absent(),
  })  : formId = Value(formId),
        stat = Value(stat),
        baseValue = Value(baseValue);
  static Insertable<FormStatsRow> custom({
    Expression<int>? formId,
    Expression<String>? stat,
    Expression<int>? baseValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (formId != null) 'form_id': formId,
      if (stat != null) 'stat': stat,
      if (baseValue != null) 'base_value': baseValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FormStatsCompanion copyWith(
      {Value<int>? formId,
      Value<String>? stat,
      Value<int>? baseValue,
      Value<int>? rowid}) {
    return FormStatsCompanion(
      formId: formId ?? this.formId,
      stat: stat ?? this.stat,
      baseValue: baseValue ?? this.baseValue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (formId.present) {
      map['form_id'] = Variable<int>(formId.value);
    }
    if (stat.present) {
      map['stat'] = Variable<String>(stat.value);
    }
    if (baseValue.present) {
      map['base_value'] = Variable<int>(baseValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FormStatsCompanion(')
          ..write('formId: $formId, ')
          ..write('stat: $stat, ')
          ..write('baseValue: $baseValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FormAbilitiesTable extends FormAbilities
    with TableInfo<$FormAbilitiesTable, FormAbilitiesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FormAbilitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _formIdMeta = const VerificationMeta('formId');
  @override
  late final GeneratedColumn<int> formId = GeneratedColumn<int>(
      'form_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<int> slot = GeneratedColumn<int>(
      'slot', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _abilityIdMeta =
      const VerificationMeta('abilityId');
  @override
  late final GeneratedColumn<int> abilityId = GeneratedColumn<int>(
      'ability_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isHiddenMeta =
      const VerificationMeta('isHidden');
  @override
  late final GeneratedColumn<bool> isHidden = GeneratedColumn<bool>(
      'is_hidden', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_hidden" IN (0, 1))'));
  @override
  List<GeneratedColumn> get $columns => [formId, slot, abilityId, isHidden];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'form_abilities';
  @override
  VerificationContext validateIntegrity(Insertable<FormAbilitiesRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('form_id')) {
      context.handle(_formIdMeta,
          formId.isAcceptableOrUnknown(data['form_id']!, _formIdMeta));
    } else if (isInserting) {
      context.missing(_formIdMeta);
    }
    if (data.containsKey('slot')) {
      context.handle(
          _slotMeta, slot.isAcceptableOrUnknown(data['slot']!, _slotMeta));
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('ability_id')) {
      context.handle(_abilityIdMeta,
          abilityId.isAcceptableOrUnknown(data['ability_id']!, _abilityIdMeta));
    } else if (isInserting) {
      context.missing(_abilityIdMeta);
    }
    if (data.containsKey('is_hidden')) {
      context.handle(_isHiddenMeta,
          isHidden.isAcceptableOrUnknown(data['is_hidden']!, _isHiddenMeta));
    } else if (isInserting) {
      context.missing(_isHiddenMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {formId, slot, isHidden};
  @override
  FormAbilitiesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FormAbilitiesRow(
      formId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}form_id'])!,
      slot: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}slot'])!,
      abilityId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ability_id'])!,
      isHidden: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_hidden'])!,
    );
  }

  @override
  $FormAbilitiesTable createAlias(String alias) {
    return $FormAbilitiesTable(attachedDatabase, alias);
  }
}

class FormAbilitiesRow extends DataClass
    implements Insertable<FormAbilitiesRow> {
  final int formId;
  final int slot;
  final int abilityId;
  final bool isHidden;
  const FormAbilitiesRow(
      {required this.formId,
      required this.slot,
      required this.abilityId,
      required this.isHidden});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['form_id'] = Variable<int>(formId);
    map['slot'] = Variable<int>(slot);
    map['ability_id'] = Variable<int>(abilityId);
    map['is_hidden'] = Variable<bool>(isHidden);
    return map;
  }

  FormAbilitiesCompanion toCompanion(bool nullToAbsent) {
    return FormAbilitiesCompanion(
      formId: Value(formId),
      slot: Value(slot),
      abilityId: Value(abilityId),
      isHidden: Value(isHidden),
    );
  }

  factory FormAbilitiesRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FormAbilitiesRow(
      formId: serializer.fromJson<int>(json['formId']),
      slot: serializer.fromJson<int>(json['slot']),
      abilityId: serializer.fromJson<int>(json['abilityId']),
      isHidden: serializer.fromJson<bool>(json['isHidden']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'formId': serializer.toJson<int>(formId),
      'slot': serializer.toJson<int>(slot),
      'abilityId': serializer.toJson<int>(abilityId),
      'isHidden': serializer.toJson<bool>(isHidden),
    };
  }

  FormAbilitiesRow copyWith(
          {int? formId, int? slot, int? abilityId, bool? isHidden}) =>
      FormAbilitiesRow(
        formId: formId ?? this.formId,
        slot: slot ?? this.slot,
        abilityId: abilityId ?? this.abilityId,
        isHidden: isHidden ?? this.isHidden,
      );
  FormAbilitiesRow copyWithCompanion(FormAbilitiesCompanion data) {
    return FormAbilitiesRow(
      formId: data.formId.present ? data.formId.value : this.formId,
      slot: data.slot.present ? data.slot.value : this.slot,
      abilityId: data.abilityId.present ? data.abilityId.value : this.abilityId,
      isHidden: data.isHidden.present ? data.isHidden.value : this.isHidden,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FormAbilitiesRow(')
          ..write('formId: $formId, ')
          ..write('slot: $slot, ')
          ..write('abilityId: $abilityId, ')
          ..write('isHidden: $isHidden')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(formId, slot, abilityId, isHidden);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FormAbilitiesRow &&
          other.formId == this.formId &&
          other.slot == this.slot &&
          other.abilityId == this.abilityId &&
          other.isHidden == this.isHidden);
}

class FormAbilitiesCompanion extends UpdateCompanion<FormAbilitiesRow> {
  final Value<int> formId;
  final Value<int> slot;
  final Value<int> abilityId;
  final Value<bool> isHidden;
  final Value<int> rowid;
  const FormAbilitiesCompanion({
    this.formId = const Value.absent(),
    this.slot = const Value.absent(),
    this.abilityId = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FormAbilitiesCompanion.insert({
    required int formId,
    required int slot,
    required int abilityId,
    required bool isHidden,
    this.rowid = const Value.absent(),
  })  : formId = Value(formId),
        slot = Value(slot),
        abilityId = Value(abilityId),
        isHidden = Value(isHidden);
  static Insertable<FormAbilitiesRow> custom({
    Expression<int>? formId,
    Expression<int>? slot,
    Expression<int>? abilityId,
    Expression<bool>? isHidden,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (formId != null) 'form_id': formId,
      if (slot != null) 'slot': slot,
      if (abilityId != null) 'ability_id': abilityId,
      if (isHidden != null) 'is_hidden': isHidden,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FormAbilitiesCompanion copyWith(
      {Value<int>? formId,
      Value<int>? slot,
      Value<int>? abilityId,
      Value<bool>? isHidden,
      Value<int>? rowid}) {
    return FormAbilitiesCompanion(
      formId: formId ?? this.formId,
      slot: slot ?? this.slot,
      abilityId: abilityId ?? this.abilityId,
      isHidden: isHidden ?? this.isHidden,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (formId.present) {
      map['form_id'] = Variable<int>(formId.value);
    }
    if (slot.present) {
      map['slot'] = Variable<int>(slot.value);
    }
    if (abilityId.present) {
      map['ability_id'] = Variable<int>(abilityId.value);
    }
    if (isHidden.present) {
      map['is_hidden'] = Variable<bool>(isHidden.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FormAbilitiesCompanion(')
          ..write('formId: $formId, ')
          ..write('slot: $slot, ')
          ..write('abilityId: $abilityId, ')
          ..write('isHidden: $isHidden, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PokemonFormMovesTable extends PokemonFormMoves
    with TableInfo<$PokemonFormMovesTable, PokemonFormMovesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PokemonFormMovesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _formIdMeta = const VerificationMeta('formId');
  @override
  late final GeneratedColumn<int> formId = GeneratedColumn<int>(
      'form_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _moveIdMeta = const VerificationMeta('moveId');
  @override
  late final GeneratedColumn<int> moveId = GeneratedColumn<int>(
      'move_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
      'method', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
      'level', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _versionGroupMeta =
      const VerificationMeta('versionGroup');
  @override
  late final GeneratedColumn<String> versionGroup = GeneratedColumn<String>(
      'version_group', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [formId, moveId, method, level, versionGroup];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pokemon_form_moves';
  @override
  VerificationContext validateIntegrity(
      Insertable<PokemonFormMovesRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('form_id')) {
      context.handle(_formIdMeta,
          formId.isAcceptableOrUnknown(data['form_id']!, _formIdMeta));
    } else if (isInserting) {
      context.missing(_formIdMeta);
    }
    if (data.containsKey('move_id')) {
      context.handle(_moveIdMeta,
          moveId.isAcceptableOrUnknown(data['move_id']!, _moveIdMeta));
    } else if (isInserting) {
      context.missing(_moveIdMeta);
    }
    if (data.containsKey('method')) {
      context.handle(_methodMeta,
          method.isAcceptableOrUnknown(data['method']!, _methodMeta));
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
          _levelMeta, level.isAcceptableOrUnknown(data['level']!, _levelMeta));
    }
    if (data.containsKey('version_group')) {
      context.handle(
          _versionGroupMeta,
          versionGroup.isAcceptableOrUnknown(
              data['version_group']!, _versionGroupMeta));
    } else if (isInserting) {
      context.missing(_versionGroupMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey =>
      {formId, moveId, method, versionGroup};
  @override
  PokemonFormMovesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PokemonFormMovesRow(
      formId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}form_id'])!,
      moveId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}move_id'])!,
      method: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}method'])!,
      level: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}level']),
      versionGroup: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}version_group'])!,
    );
  }

  @override
  $PokemonFormMovesTable createAlias(String alias) {
    return $PokemonFormMovesTable(attachedDatabase, alias);
  }
}

class PokemonFormMovesRow extends DataClass
    implements Insertable<PokemonFormMovesRow> {
  final int formId;
  final int moveId;
  final String method;
  final int? level;
  final String versionGroup;
  const PokemonFormMovesRow(
      {required this.formId,
      required this.moveId,
      required this.method,
      this.level,
      required this.versionGroup});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['form_id'] = Variable<int>(formId);
    map['move_id'] = Variable<int>(moveId);
    map['method'] = Variable<String>(method);
    if (!nullToAbsent || level != null) {
      map['level'] = Variable<int>(level);
    }
    map['version_group'] = Variable<String>(versionGroup);
    return map;
  }

  PokemonFormMovesCompanion toCompanion(bool nullToAbsent) {
    return PokemonFormMovesCompanion(
      formId: Value(formId),
      moveId: Value(moveId),
      method: Value(method),
      level:
          level == null && nullToAbsent ? const Value.absent() : Value(level),
      versionGroup: Value(versionGroup),
    );
  }

  factory PokemonFormMovesRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PokemonFormMovesRow(
      formId: serializer.fromJson<int>(json['formId']),
      moveId: serializer.fromJson<int>(json['moveId']),
      method: serializer.fromJson<String>(json['method']),
      level: serializer.fromJson<int?>(json['level']),
      versionGroup: serializer.fromJson<String>(json['versionGroup']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'formId': serializer.toJson<int>(formId),
      'moveId': serializer.toJson<int>(moveId),
      'method': serializer.toJson<String>(method),
      'level': serializer.toJson<int?>(level),
      'versionGroup': serializer.toJson<String>(versionGroup),
    };
  }

  PokemonFormMovesRow copyWith(
          {int? formId,
          int? moveId,
          String? method,
          Value<int?> level = const Value.absent(),
          String? versionGroup}) =>
      PokemonFormMovesRow(
        formId: formId ?? this.formId,
        moveId: moveId ?? this.moveId,
        method: method ?? this.method,
        level: level.present ? level.value : this.level,
        versionGroup: versionGroup ?? this.versionGroup,
      );
  PokemonFormMovesRow copyWithCompanion(PokemonFormMovesCompanion data) {
    return PokemonFormMovesRow(
      formId: data.formId.present ? data.formId.value : this.formId,
      moveId: data.moveId.present ? data.moveId.value : this.moveId,
      method: data.method.present ? data.method.value : this.method,
      level: data.level.present ? data.level.value : this.level,
      versionGroup: data.versionGroup.present
          ? data.versionGroup.value
          : this.versionGroup,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PokemonFormMovesRow(')
          ..write('formId: $formId, ')
          ..write('moveId: $moveId, ')
          ..write('method: $method, ')
          ..write('level: $level, ')
          ..write('versionGroup: $versionGroup')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(formId, moveId, method, level, versionGroup);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PokemonFormMovesRow &&
          other.formId == this.formId &&
          other.moveId == this.moveId &&
          other.method == this.method &&
          other.level == this.level &&
          other.versionGroup == this.versionGroup);
}

class PokemonFormMovesCompanion extends UpdateCompanion<PokemonFormMovesRow> {
  final Value<int> formId;
  final Value<int> moveId;
  final Value<String> method;
  final Value<int?> level;
  final Value<String> versionGroup;
  final Value<int> rowid;
  const PokemonFormMovesCompanion({
    this.formId = const Value.absent(),
    this.moveId = const Value.absent(),
    this.method = const Value.absent(),
    this.level = const Value.absent(),
    this.versionGroup = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PokemonFormMovesCompanion.insert({
    required int formId,
    required int moveId,
    required String method,
    this.level = const Value.absent(),
    required String versionGroup,
    this.rowid = const Value.absent(),
  })  : formId = Value(formId),
        moveId = Value(moveId),
        method = Value(method),
        versionGroup = Value(versionGroup);
  static Insertable<PokemonFormMovesRow> custom({
    Expression<int>? formId,
    Expression<int>? moveId,
    Expression<String>? method,
    Expression<int>? level,
    Expression<String>? versionGroup,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (formId != null) 'form_id': formId,
      if (moveId != null) 'move_id': moveId,
      if (method != null) 'method': method,
      if (level != null) 'level': level,
      if (versionGroup != null) 'version_group': versionGroup,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PokemonFormMovesCompanion copyWith(
      {Value<int>? formId,
      Value<int>? moveId,
      Value<String>? method,
      Value<int?>? level,
      Value<String>? versionGroup,
      Value<int>? rowid}) {
    return PokemonFormMovesCompanion(
      formId: formId ?? this.formId,
      moveId: moveId ?? this.moveId,
      method: method ?? this.method,
      level: level ?? this.level,
      versionGroup: versionGroup ?? this.versionGroup,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (formId.present) {
      map['form_id'] = Variable<int>(formId.value);
    }
    if (moveId.present) {
      map['move_id'] = Variable<int>(moveId.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (versionGroup.present) {
      map['version_group'] = Variable<String>(versionGroup.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PokemonFormMovesCompanion(')
          ..write('formId: $formId, ')
          ..write('moveId: $moveId, ')
          ..write('method: $method, ')
          ..write('level: $level, ')
          ..write('versionGroup: $versionGroup, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EvolutionChainsTable extends EvolutionChains
    with TableInfo<$EvolutionChainsTable, EvolutionChainsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EvolutionChainsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _rootSpeciesIdMeta =
      const VerificationMeta('rootSpeciesId');
  @override
  late final GeneratedColumn<int> rootSpeciesId = GeneratedColumn<int>(
      'root_species_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, rootSpeciesId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'evolution_chains';
  @override
  VerificationContext validateIntegrity(Insertable<EvolutionChainsRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('root_species_id')) {
      context.handle(
          _rootSpeciesIdMeta,
          rootSpeciesId.isAcceptableOrUnknown(
              data['root_species_id']!, _rootSpeciesIdMeta));
    } else if (isInserting) {
      context.missing(_rootSpeciesIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  EvolutionChainsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EvolutionChainsRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      rootSpeciesId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}root_species_id'])!,
    );
  }

  @override
  $EvolutionChainsTable createAlias(String alias) {
    return $EvolutionChainsTable(attachedDatabase, alias);
  }
}

class EvolutionChainsRow extends DataClass
    implements Insertable<EvolutionChainsRow> {
  final int id;
  final int rootSpeciesId;
  const EvolutionChainsRow({required this.id, required this.rootSpeciesId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['root_species_id'] = Variable<int>(rootSpeciesId);
    return map;
  }

  EvolutionChainsCompanion toCompanion(bool nullToAbsent) {
    return EvolutionChainsCompanion(
      id: Value(id),
      rootSpeciesId: Value(rootSpeciesId),
    );
  }

  factory EvolutionChainsRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EvolutionChainsRow(
      id: serializer.fromJson<int>(json['id']),
      rootSpeciesId: serializer.fromJson<int>(json['rootSpeciesId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'rootSpeciesId': serializer.toJson<int>(rootSpeciesId),
    };
  }

  EvolutionChainsRow copyWith({int? id, int? rootSpeciesId}) =>
      EvolutionChainsRow(
        id: id ?? this.id,
        rootSpeciesId: rootSpeciesId ?? this.rootSpeciesId,
      );
  EvolutionChainsRow copyWithCompanion(EvolutionChainsCompanion data) {
    return EvolutionChainsRow(
      id: data.id.present ? data.id.value : this.id,
      rootSpeciesId: data.rootSpeciesId.present
          ? data.rootSpeciesId.value
          : this.rootSpeciesId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EvolutionChainsRow(')
          ..write('id: $id, ')
          ..write('rootSpeciesId: $rootSpeciesId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, rootSpeciesId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EvolutionChainsRow &&
          other.id == this.id &&
          other.rootSpeciesId == this.rootSpeciesId);
}

class EvolutionChainsCompanion extends UpdateCompanion<EvolutionChainsRow> {
  final Value<int> id;
  final Value<int> rootSpeciesId;
  final Value<int> rowid;
  const EvolutionChainsCompanion({
    this.id = const Value.absent(),
    this.rootSpeciesId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EvolutionChainsCompanion.insert({
    required int id,
    required int rootSpeciesId,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        rootSpeciesId = Value(rootSpeciesId);
  static Insertable<EvolutionChainsRow> custom({
    Expression<int>? id,
    Expression<int>? rootSpeciesId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rootSpeciesId != null) 'root_species_id': rootSpeciesId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EvolutionChainsCompanion copyWith(
      {Value<int>? id, Value<int>? rootSpeciesId, Value<int>? rowid}) {
    return EvolutionChainsCompanion(
      id: id ?? this.id,
      rootSpeciesId: rootSpeciesId ?? this.rootSpeciesId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (rootSpeciesId.present) {
      map['root_species_id'] = Variable<int>(rootSpeciesId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EvolutionChainsCompanion(')
          ..write('id: $id, ')
          ..write('rootSpeciesId: $rootSpeciesId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EvolutionEdgesTable extends EvolutionEdges
    with TableInfo<$EvolutionEdgesTable, EvolutionEdgesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EvolutionEdgesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chainIdMeta =
      const VerificationMeta('chainId');
  @override
  late final GeneratedColumn<int> chainId = GeneratedColumn<int>(
      'chain_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _fromSpeciesIdMeta =
      const VerificationMeta('fromSpeciesId');
  @override
  late final GeneratedColumn<int> fromSpeciesId = GeneratedColumn<int>(
      'from_species_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _toSpeciesIdMeta =
      const VerificationMeta('toSpeciesId');
  @override
  late final GeneratedColumn<int> toSpeciesId = GeneratedColumn<int>(
      'to_species_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _triggerMeta =
      const VerificationMeta('trigger');
  @override
  late final GeneratedColumn<String> trigger = GeneratedColumn<String>(
      'trigger', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _minLevelMeta =
      const VerificationMeta('minLevel');
  @override
  late final GeneratedColumn<int> minLevel = GeneratedColumn<int>(
      'min_level', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _itemMeta = const VerificationMeta('item');
  @override
  late final GeneratedColumn<String> item = GeneratedColumn<String>(
      'item', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _heldItemMeta =
      const VerificationMeta('heldItem');
  @override
  late final GeneratedColumn<String> heldItem = GeneratedColumn<String>(
      'held_item', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _knownMoveMeta =
      const VerificationMeta('knownMove');
  @override
  late final GeneratedColumn<String> knownMove = GeneratedColumn<String>(
      'known_move', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _knownMoveTypeMeta =
      const VerificationMeta('knownMoveType');
  @override
  late final GeneratedColumn<String> knownMoveType = GeneratedColumn<String>(
      'known_move_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _locationMeta =
      const VerificationMeta('location');
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
      'location', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _timeOfDayMeta =
      const VerificationMeta('timeOfDay');
  @override
  late final GeneratedColumn<String> timeOfDay = GeneratedColumn<String>(
      'time_of_day', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
      'gender', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _minHappinessMeta =
      const VerificationMeta('minHappiness');
  @override
  late final GeneratedColumn<int> minHappiness = GeneratedColumn<int>(
      'min_happiness', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _minAffectionMeta =
      const VerificationMeta('minAffection');
  @override
  late final GeneratedColumn<int> minAffection = GeneratedColumn<int>(
      'min_affection', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _minBeautyMeta =
      const VerificationMeta('minBeauty');
  @override
  late final GeneratedColumn<int> minBeauty = GeneratedColumn<int>(
      'min_beauty', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _relativePhysicalStatsMeta =
      const VerificationMeta('relativePhysicalStats');
  @override
  late final GeneratedColumn<String> relativePhysicalStats =
      GeneratedColumn<String>('relative_physical_stats', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _partySpeciesMeta =
      const VerificationMeta('partySpecies');
  @override
  late final GeneratedColumn<String> partySpecies = GeneratedColumn<String>(
      'party_species', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _partyTypeMeta =
      const VerificationMeta('partyType');
  @override
  late final GeneratedColumn<String> partyType = GeneratedColumn<String>(
      'party_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tradeSpeciesMeta =
      const VerificationMeta('tradeSpecies');
  @override
  late final GeneratedColumn<String> tradeSpecies = GeneratedColumn<String>(
      'trade_species', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _needsOverworldRainMeta =
      const VerificationMeta('needsOverworldRain');
  @override
  late final GeneratedColumn<bool> needsOverworldRain = GeneratedColumn<bool>(
      'needs_overworld_rain', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("needs_overworld_rain" IN (0, 1))'));
  static const VerificationMeta _turnUpsideDownMeta =
      const VerificationMeta('turnUpsideDown');
  @override
  late final GeneratedColumn<bool> turnUpsideDown = GeneratedColumn<bool>(
      'turn_upside_down', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("turn_upside_down" IN (0, 1))'));
  @override
  List<GeneratedColumn> get $columns => [
        chainId,
        fromSpeciesId,
        toSpeciesId,
        trigger,
        minLevel,
        item,
        heldItem,
        knownMove,
        knownMoveType,
        location,
        timeOfDay,
        gender,
        minHappiness,
        minAffection,
        minBeauty,
        relativePhysicalStats,
        partySpecies,
        partyType,
        tradeSpecies,
        needsOverworldRain,
        turnUpsideDown
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'evolution_edges';
  @override
  VerificationContext validateIntegrity(Insertable<EvolutionEdgesRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chain_id')) {
      context.handle(_chainIdMeta,
          chainId.isAcceptableOrUnknown(data['chain_id']!, _chainIdMeta));
    } else if (isInserting) {
      context.missing(_chainIdMeta);
    }
    if (data.containsKey('from_species_id')) {
      context.handle(
          _fromSpeciesIdMeta,
          fromSpeciesId.isAcceptableOrUnknown(
              data['from_species_id']!, _fromSpeciesIdMeta));
    }
    if (data.containsKey('to_species_id')) {
      context.handle(
          _toSpeciesIdMeta,
          toSpeciesId.isAcceptableOrUnknown(
              data['to_species_id']!, _toSpeciesIdMeta));
    } else if (isInserting) {
      context.missing(_toSpeciesIdMeta);
    }
    if (data.containsKey('trigger')) {
      context.handle(_triggerMeta,
          trigger.isAcceptableOrUnknown(data['trigger']!, _triggerMeta));
    } else if (isInserting) {
      context.missing(_triggerMeta);
    }
    if (data.containsKey('min_level')) {
      context.handle(_minLevelMeta,
          minLevel.isAcceptableOrUnknown(data['min_level']!, _minLevelMeta));
    }
    if (data.containsKey('item')) {
      context.handle(
          _itemMeta, item.isAcceptableOrUnknown(data['item']!, _itemMeta));
    }
    if (data.containsKey('held_item')) {
      context.handle(_heldItemMeta,
          heldItem.isAcceptableOrUnknown(data['held_item']!, _heldItemMeta));
    }
    if (data.containsKey('known_move')) {
      context.handle(_knownMoveMeta,
          knownMove.isAcceptableOrUnknown(data['known_move']!, _knownMoveMeta));
    }
    if (data.containsKey('known_move_type')) {
      context.handle(
          _knownMoveTypeMeta,
          knownMoveType.isAcceptableOrUnknown(
              data['known_move_type']!, _knownMoveTypeMeta));
    }
    if (data.containsKey('location')) {
      context.handle(_locationMeta,
          location.isAcceptableOrUnknown(data['location']!, _locationMeta));
    }
    if (data.containsKey('time_of_day')) {
      context.handle(
          _timeOfDayMeta,
          timeOfDay.isAcceptableOrUnknown(
              data['time_of_day']!, _timeOfDayMeta));
    }
    if (data.containsKey('gender')) {
      context.handle(_genderMeta,
          gender.isAcceptableOrUnknown(data['gender']!, _genderMeta));
    }
    if (data.containsKey('min_happiness')) {
      context.handle(
          _minHappinessMeta,
          minHappiness.isAcceptableOrUnknown(
              data['min_happiness']!, _minHappinessMeta));
    }
    if (data.containsKey('min_affection')) {
      context.handle(
          _minAffectionMeta,
          minAffection.isAcceptableOrUnknown(
              data['min_affection']!, _minAffectionMeta));
    }
    if (data.containsKey('min_beauty')) {
      context.handle(_minBeautyMeta,
          minBeauty.isAcceptableOrUnknown(data['min_beauty']!, _minBeautyMeta));
    }
    if (data.containsKey('relative_physical_stats')) {
      context.handle(
          _relativePhysicalStatsMeta,
          relativePhysicalStats.isAcceptableOrUnknown(
              data['relative_physical_stats']!, _relativePhysicalStatsMeta));
    }
    if (data.containsKey('party_species')) {
      context.handle(
          _partySpeciesMeta,
          partySpecies.isAcceptableOrUnknown(
              data['party_species']!, _partySpeciesMeta));
    }
    if (data.containsKey('party_type')) {
      context.handle(_partyTypeMeta,
          partyType.isAcceptableOrUnknown(data['party_type']!, _partyTypeMeta));
    }
    if (data.containsKey('trade_species')) {
      context.handle(
          _tradeSpeciesMeta,
          tradeSpecies.isAcceptableOrUnknown(
              data['trade_species']!, _tradeSpeciesMeta));
    }
    if (data.containsKey('needs_overworld_rain')) {
      context.handle(
          _needsOverworldRainMeta,
          needsOverworldRain.isAcceptableOrUnknown(
              data['needs_overworld_rain']!, _needsOverworldRainMeta));
    } else if (isInserting) {
      context.missing(_needsOverworldRainMeta);
    }
    if (data.containsKey('turn_upside_down')) {
      context.handle(
          _turnUpsideDownMeta,
          turnUpsideDown.isAcceptableOrUnknown(
              data['turn_upside_down']!, _turnUpsideDownMeta));
    } else if (isInserting) {
      context.missing(_turnUpsideDownMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chainId, toSpeciesId};
  @override
  EvolutionEdgesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EvolutionEdgesRow(
      chainId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}chain_id'])!,
      fromSpeciesId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}from_species_id']),
      toSpeciesId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}to_species_id'])!,
      trigger: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}trigger'])!,
      minLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}min_level']),
      item: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item']),
      heldItem: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}held_item']),
      knownMove: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}known_move']),
      knownMoveType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}known_move_type']),
      location: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location']),
      timeOfDay: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}time_of_day']),
      gender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gender']),
      minHappiness: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}min_happiness']),
      minAffection: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}min_affection']),
      minBeauty: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}min_beauty']),
      relativePhysicalStats: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}relative_physical_stats']),
      partySpecies: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}party_species']),
      partyType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}party_type']),
      tradeSpecies: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}trade_species']),
      needsOverworldRain: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}needs_overworld_rain'])!,
      turnUpsideDown: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}turn_upside_down'])!,
    );
  }

  @override
  $EvolutionEdgesTable createAlias(String alias) {
    return $EvolutionEdgesTable(attachedDatabase, alias);
  }
}

class EvolutionEdgesRow extends DataClass
    implements Insertable<EvolutionEdgesRow> {
  final int chainId;
  final int? fromSpeciesId;
  final int toSpeciesId;
  final String trigger;
  final int? minLevel;
  final String? item;
  final String? heldItem;
  final String? knownMove;
  final String? knownMoveType;
  final String? location;
  final String? timeOfDay;
  final String? gender;
  final int? minHappiness;
  final int? minAffection;
  final int? minBeauty;
  final String? relativePhysicalStats;
  final String? partySpecies;
  final String? partyType;
  final String? tradeSpecies;
  final bool needsOverworldRain;
  final bool turnUpsideDown;
  const EvolutionEdgesRow(
      {required this.chainId,
      this.fromSpeciesId,
      required this.toSpeciesId,
      required this.trigger,
      this.minLevel,
      this.item,
      this.heldItem,
      this.knownMove,
      this.knownMoveType,
      this.location,
      this.timeOfDay,
      this.gender,
      this.minHappiness,
      this.minAffection,
      this.minBeauty,
      this.relativePhysicalStats,
      this.partySpecies,
      this.partyType,
      this.tradeSpecies,
      required this.needsOverworldRain,
      required this.turnUpsideDown});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chain_id'] = Variable<int>(chainId);
    if (!nullToAbsent || fromSpeciesId != null) {
      map['from_species_id'] = Variable<int>(fromSpeciesId);
    }
    map['to_species_id'] = Variable<int>(toSpeciesId);
    map['trigger'] = Variable<String>(trigger);
    if (!nullToAbsent || minLevel != null) {
      map['min_level'] = Variable<int>(minLevel);
    }
    if (!nullToAbsent || item != null) {
      map['item'] = Variable<String>(item);
    }
    if (!nullToAbsent || heldItem != null) {
      map['held_item'] = Variable<String>(heldItem);
    }
    if (!nullToAbsent || knownMove != null) {
      map['known_move'] = Variable<String>(knownMove);
    }
    if (!nullToAbsent || knownMoveType != null) {
      map['known_move_type'] = Variable<String>(knownMoveType);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || timeOfDay != null) {
      map['time_of_day'] = Variable<String>(timeOfDay);
    }
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    if (!nullToAbsent || minHappiness != null) {
      map['min_happiness'] = Variable<int>(minHappiness);
    }
    if (!nullToAbsent || minAffection != null) {
      map['min_affection'] = Variable<int>(minAffection);
    }
    if (!nullToAbsent || minBeauty != null) {
      map['min_beauty'] = Variable<int>(minBeauty);
    }
    if (!nullToAbsent || relativePhysicalStats != null) {
      map['relative_physical_stats'] = Variable<String>(relativePhysicalStats);
    }
    if (!nullToAbsent || partySpecies != null) {
      map['party_species'] = Variable<String>(partySpecies);
    }
    if (!nullToAbsent || partyType != null) {
      map['party_type'] = Variable<String>(partyType);
    }
    if (!nullToAbsent || tradeSpecies != null) {
      map['trade_species'] = Variable<String>(tradeSpecies);
    }
    map['needs_overworld_rain'] = Variable<bool>(needsOverworldRain);
    map['turn_upside_down'] = Variable<bool>(turnUpsideDown);
    return map;
  }

  EvolutionEdgesCompanion toCompanion(bool nullToAbsent) {
    return EvolutionEdgesCompanion(
      chainId: Value(chainId),
      fromSpeciesId: fromSpeciesId == null && nullToAbsent
          ? const Value.absent()
          : Value(fromSpeciesId),
      toSpeciesId: Value(toSpeciesId),
      trigger: Value(trigger),
      minLevel: minLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(minLevel),
      item: item == null && nullToAbsent ? const Value.absent() : Value(item),
      heldItem: heldItem == null && nullToAbsent
          ? const Value.absent()
          : Value(heldItem),
      knownMove: knownMove == null && nullToAbsent
          ? const Value.absent()
          : Value(knownMove),
      knownMoveType: knownMoveType == null && nullToAbsent
          ? const Value.absent()
          : Value(knownMoveType),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      timeOfDay: timeOfDay == null && nullToAbsent
          ? const Value.absent()
          : Value(timeOfDay),
      gender:
          gender == null && nullToAbsent ? const Value.absent() : Value(gender),
      minHappiness: minHappiness == null && nullToAbsent
          ? const Value.absent()
          : Value(minHappiness),
      minAffection: minAffection == null && nullToAbsent
          ? const Value.absent()
          : Value(minAffection),
      minBeauty: minBeauty == null && nullToAbsent
          ? const Value.absent()
          : Value(minBeauty),
      relativePhysicalStats: relativePhysicalStats == null && nullToAbsent
          ? const Value.absent()
          : Value(relativePhysicalStats),
      partySpecies: partySpecies == null && nullToAbsent
          ? const Value.absent()
          : Value(partySpecies),
      partyType: partyType == null && nullToAbsent
          ? const Value.absent()
          : Value(partyType),
      tradeSpecies: tradeSpecies == null && nullToAbsent
          ? const Value.absent()
          : Value(tradeSpecies),
      needsOverworldRain: Value(needsOverworldRain),
      turnUpsideDown: Value(turnUpsideDown),
    );
  }

  factory EvolutionEdgesRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EvolutionEdgesRow(
      chainId: serializer.fromJson<int>(json['chainId']),
      fromSpeciesId: serializer.fromJson<int?>(json['fromSpeciesId']),
      toSpeciesId: serializer.fromJson<int>(json['toSpeciesId']),
      trigger: serializer.fromJson<String>(json['trigger']),
      minLevel: serializer.fromJson<int?>(json['minLevel']),
      item: serializer.fromJson<String?>(json['item']),
      heldItem: serializer.fromJson<String?>(json['heldItem']),
      knownMove: serializer.fromJson<String?>(json['knownMove']),
      knownMoveType: serializer.fromJson<String?>(json['knownMoveType']),
      location: serializer.fromJson<String?>(json['location']),
      timeOfDay: serializer.fromJson<String?>(json['timeOfDay']),
      gender: serializer.fromJson<String?>(json['gender']),
      minHappiness: serializer.fromJson<int?>(json['minHappiness']),
      minAffection: serializer.fromJson<int?>(json['minAffection']),
      minBeauty: serializer.fromJson<int?>(json['minBeauty']),
      relativePhysicalStats:
          serializer.fromJson<String?>(json['relativePhysicalStats']),
      partySpecies: serializer.fromJson<String?>(json['partySpecies']),
      partyType: serializer.fromJson<String?>(json['partyType']),
      tradeSpecies: serializer.fromJson<String?>(json['tradeSpecies']),
      needsOverworldRain: serializer.fromJson<bool>(json['needsOverworldRain']),
      turnUpsideDown: serializer.fromJson<bool>(json['turnUpsideDown']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chainId': serializer.toJson<int>(chainId),
      'fromSpeciesId': serializer.toJson<int?>(fromSpeciesId),
      'toSpeciesId': serializer.toJson<int>(toSpeciesId),
      'trigger': serializer.toJson<String>(trigger),
      'minLevel': serializer.toJson<int?>(minLevel),
      'item': serializer.toJson<String?>(item),
      'heldItem': serializer.toJson<String?>(heldItem),
      'knownMove': serializer.toJson<String?>(knownMove),
      'knownMoveType': serializer.toJson<String?>(knownMoveType),
      'location': serializer.toJson<String?>(location),
      'timeOfDay': serializer.toJson<String?>(timeOfDay),
      'gender': serializer.toJson<String?>(gender),
      'minHappiness': serializer.toJson<int?>(minHappiness),
      'minAffection': serializer.toJson<int?>(minAffection),
      'minBeauty': serializer.toJson<int?>(minBeauty),
      'relativePhysicalStats':
          serializer.toJson<String?>(relativePhysicalStats),
      'partySpecies': serializer.toJson<String?>(partySpecies),
      'partyType': serializer.toJson<String?>(partyType),
      'tradeSpecies': serializer.toJson<String?>(tradeSpecies),
      'needsOverworldRain': serializer.toJson<bool>(needsOverworldRain),
      'turnUpsideDown': serializer.toJson<bool>(turnUpsideDown),
    };
  }

  EvolutionEdgesRow copyWith(
          {int? chainId,
          Value<int?> fromSpeciesId = const Value.absent(),
          int? toSpeciesId,
          String? trigger,
          Value<int?> minLevel = const Value.absent(),
          Value<String?> item = const Value.absent(),
          Value<String?> heldItem = const Value.absent(),
          Value<String?> knownMove = const Value.absent(),
          Value<String?> knownMoveType = const Value.absent(),
          Value<String?> location = const Value.absent(),
          Value<String?> timeOfDay = const Value.absent(),
          Value<String?> gender = const Value.absent(),
          Value<int?> minHappiness = const Value.absent(),
          Value<int?> minAffection = const Value.absent(),
          Value<int?> minBeauty = const Value.absent(),
          Value<String?> relativePhysicalStats = const Value.absent(),
          Value<String?> partySpecies = const Value.absent(),
          Value<String?> partyType = const Value.absent(),
          Value<String?> tradeSpecies = const Value.absent(),
          bool? needsOverworldRain,
          bool? turnUpsideDown}) =>
      EvolutionEdgesRow(
        chainId: chainId ?? this.chainId,
        fromSpeciesId:
            fromSpeciesId.present ? fromSpeciesId.value : this.fromSpeciesId,
        toSpeciesId: toSpeciesId ?? this.toSpeciesId,
        trigger: trigger ?? this.trigger,
        minLevel: minLevel.present ? minLevel.value : this.minLevel,
        item: item.present ? item.value : this.item,
        heldItem: heldItem.present ? heldItem.value : this.heldItem,
        knownMove: knownMove.present ? knownMove.value : this.knownMove,
        knownMoveType:
            knownMoveType.present ? knownMoveType.value : this.knownMoveType,
        location: location.present ? location.value : this.location,
        timeOfDay: timeOfDay.present ? timeOfDay.value : this.timeOfDay,
        gender: gender.present ? gender.value : this.gender,
        minHappiness:
            minHappiness.present ? minHappiness.value : this.minHappiness,
        minAffection:
            minAffection.present ? minAffection.value : this.minAffection,
        minBeauty: minBeauty.present ? minBeauty.value : this.minBeauty,
        relativePhysicalStats: relativePhysicalStats.present
            ? relativePhysicalStats.value
            : this.relativePhysicalStats,
        partySpecies:
            partySpecies.present ? partySpecies.value : this.partySpecies,
        partyType: partyType.present ? partyType.value : this.partyType,
        tradeSpecies:
            tradeSpecies.present ? tradeSpecies.value : this.tradeSpecies,
        needsOverworldRain: needsOverworldRain ?? this.needsOverworldRain,
        turnUpsideDown: turnUpsideDown ?? this.turnUpsideDown,
      );
  EvolutionEdgesRow copyWithCompanion(EvolutionEdgesCompanion data) {
    return EvolutionEdgesRow(
      chainId: data.chainId.present ? data.chainId.value : this.chainId,
      fromSpeciesId: data.fromSpeciesId.present
          ? data.fromSpeciesId.value
          : this.fromSpeciesId,
      toSpeciesId:
          data.toSpeciesId.present ? data.toSpeciesId.value : this.toSpeciesId,
      trigger: data.trigger.present ? data.trigger.value : this.trigger,
      minLevel: data.minLevel.present ? data.minLevel.value : this.minLevel,
      item: data.item.present ? data.item.value : this.item,
      heldItem: data.heldItem.present ? data.heldItem.value : this.heldItem,
      knownMove: data.knownMove.present ? data.knownMove.value : this.knownMove,
      knownMoveType: data.knownMoveType.present
          ? data.knownMoveType.value
          : this.knownMoveType,
      location: data.location.present ? data.location.value : this.location,
      timeOfDay: data.timeOfDay.present ? data.timeOfDay.value : this.timeOfDay,
      gender: data.gender.present ? data.gender.value : this.gender,
      minHappiness: data.minHappiness.present
          ? data.minHappiness.value
          : this.minHappiness,
      minAffection: data.minAffection.present
          ? data.minAffection.value
          : this.minAffection,
      minBeauty: data.minBeauty.present ? data.minBeauty.value : this.minBeauty,
      relativePhysicalStats: data.relativePhysicalStats.present
          ? data.relativePhysicalStats.value
          : this.relativePhysicalStats,
      partySpecies: data.partySpecies.present
          ? data.partySpecies.value
          : this.partySpecies,
      partyType: data.partyType.present ? data.partyType.value : this.partyType,
      tradeSpecies: data.tradeSpecies.present
          ? data.tradeSpecies.value
          : this.tradeSpecies,
      needsOverworldRain: data.needsOverworldRain.present
          ? data.needsOverworldRain.value
          : this.needsOverworldRain,
      turnUpsideDown: data.turnUpsideDown.present
          ? data.turnUpsideDown.value
          : this.turnUpsideDown,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EvolutionEdgesRow(')
          ..write('chainId: $chainId, ')
          ..write('fromSpeciesId: $fromSpeciesId, ')
          ..write('toSpeciesId: $toSpeciesId, ')
          ..write('trigger: $trigger, ')
          ..write('minLevel: $minLevel, ')
          ..write('item: $item, ')
          ..write('heldItem: $heldItem, ')
          ..write('knownMove: $knownMove, ')
          ..write('knownMoveType: $knownMoveType, ')
          ..write('location: $location, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('gender: $gender, ')
          ..write('minHappiness: $minHappiness, ')
          ..write('minAffection: $minAffection, ')
          ..write('minBeauty: $minBeauty, ')
          ..write('relativePhysicalStats: $relativePhysicalStats, ')
          ..write('partySpecies: $partySpecies, ')
          ..write('partyType: $partyType, ')
          ..write('tradeSpecies: $tradeSpecies, ')
          ..write('needsOverworldRain: $needsOverworldRain, ')
          ..write('turnUpsideDown: $turnUpsideDown')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        chainId,
        fromSpeciesId,
        toSpeciesId,
        trigger,
        minLevel,
        item,
        heldItem,
        knownMove,
        knownMoveType,
        location,
        timeOfDay,
        gender,
        minHappiness,
        minAffection,
        minBeauty,
        relativePhysicalStats,
        partySpecies,
        partyType,
        tradeSpecies,
        needsOverworldRain,
        turnUpsideDown
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EvolutionEdgesRow &&
          other.chainId == this.chainId &&
          other.fromSpeciesId == this.fromSpeciesId &&
          other.toSpeciesId == this.toSpeciesId &&
          other.trigger == this.trigger &&
          other.minLevel == this.minLevel &&
          other.item == this.item &&
          other.heldItem == this.heldItem &&
          other.knownMove == this.knownMove &&
          other.knownMoveType == this.knownMoveType &&
          other.location == this.location &&
          other.timeOfDay == this.timeOfDay &&
          other.gender == this.gender &&
          other.minHappiness == this.minHappiness &&
          other.minAffection == this.minAffection &&
          other.minBeauty == this.minBeauty &&
          other.relativePhysicalStats == this.relativePhysicalStats &&
          other.partySpecies == this.partySpecies &&
          other.partyType == this.partyType &&
          other.tradeSpecies == this.tradeSpecies &&
          other.needsOverworldRain == this.needsOverworldRain &&
          other.turnUpsideDown == this.turnUpsideDown);
}

class EvolutionEdgesCompanion extends UpdateCompanion<EvolutionEdgesRow> {
  final Value<int> chainId;
  final Value<int?> fromSpeciesId;
  final Value<int> toSpeciesId;
  final Value<String> trigger;
  final Value<int?> minLevel;
  final Value<String?> item;
  final Value<String?> heldItem;
  final Value<String?> knownMove;
  final Value<String?> knownMoveType;
  final Value<String?> location;
  final Value<String?> timeOfDay;
  final Value<String?> gender;
  final Value<int?> minHappiness;
  final Value<int?> minAffection;
  final Value<int?> minBeauty;
  final Value<String?> relativePhysicalStats;
  final Value<String?> partySpecies;
  final Value<String?> partyType;
  final Value<String?> tradeSpecies;
  final Value<bool> needsOverworldRain;
  final Value<bool> turnUpsideDown;
  final Value<int> rowid;
  const EvolutionEdgesCompanion({
    this.chainId = const Value.absent(),
    this.fromSpeciesId = const Value.absent(),
    this.toSpeciesId = const Value.absent(),
    this.trigger = const Value.absent(),
    this.minLevel = const Value.absent(),
    this.item = const Value.absent(),
    this.heldItem = const Value.absent(),
    this.knownMove = const Value.absent(),
    this.knownMoveType = const Value.absent(),
    this.location = const Value.absent(),
    this.timeOfDay = const Value.absent(),
    this.gender = const Value.absent(),
    this.minHappiness = const Value.absent(),
    this.minAffection = const Value.absent(),
    this.minBeauty = const Value.absent(),
    this.relativePhysicalStats = const Value.absent(),
    this.partySpecies = const Value.absent(),
    this.partyType = const Value.absent(),
    this.tradeSpecies = const Value.absent(),
    this.needsOverworldRain = const Value.absent(),
    this.turnUpsideDown = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EvolutionEdgesCompanion.insert({
    required int chainId,
    this.fromSpeciesId = const Value.absent(),
    required int toSpeciesId,
    required String trigger,
    this.minLevel = const Value.absent(),
    this.item = const Value.absent(),
    this.heldItem = const Value.absent(),
    this.knownMove = const Value.absent(),
    this.knownMoveType = const Value.absent(),
    this.location = const Value.absent(),
    this.timeOfDay = const Value.absent(),
    this.gender = const Value.absent(),
    this.minHappiness = const Value.absent(),
    this.minAffection = const Value.absent(),
    this.minBeauty = const Value.absent(),
    this.relativePhysicalStats = const Value.absent(),
    this.partySpecies = const Value.absent(),
    this.partyType = const Value.absent(),
    this.tradeSpecies = const Value.absent(),
    required bool needsOverworldRain,
    required bool turnUpsideDown,
    this.rowid = const Value.absent(),
  })  : chainId = Value(chainId),
        toSpeciesId = Value(toSpeciesId),
        trigger = Value(trigger),
        needsOverworldRain = Value(needsOverworldRain),
        turnUpsideDown = Value(turnUpsideDown);
  static Insertable<EvolutionEdgesRow> custom({
    Expression<int>? chainId,
    Expression<int>? fromSpeciesId,
    Expression<int>? toSpeciesId,
    Expression<String>? trigger,
    Expression<int>? minLevel,
    Expression<String>? item,
    Expression<String>? heldItem,
    Expression<String>? knownMove,
    Expression<String>? knownMoveType,
    Expression<String>? location,
    Expression<String>? timeOfDay,
    Expression<String>? gender,
    Expression<int>? minHappiness,
    Expression<int>? minAffection,
    Expression<int>? minBeauty,
    Expression<String>? relativePhysicalStats,
    Expression<String>? partySpecies,
    Expression<String>? partyType,
    Expression<String>? tradeSpecies,
    Expression<bool>? needsOverworldRain,
    Expression<bool>? turnUpsideDown,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chainId != null) 'chain_id': chainId,
      if (fromSpeciesId != null) 'from_species_id': fromSpeciesId,
      if (toSpeciesId != null) 'to_species_id': toSpeciesId,
      if (trigger != null) 'trigger': trigger,
      if (minLevel != null) 'min_level': minLevel,
      if (item != null) 'item': item,
      if (heldItem != null) 'held_item': heldItem,
      if (knownMove != null) 'known_move': knownMove,
      if (knownMoveType != null) 'known_move_type': knownMoveType,
      if (location != null) 'location': location,
      if (timeOfDay != null) 'time_of_day': timeOfDay,
      if (gender != null) 'gender': gender,
      if (minHappiness != null) 'min_happiness': minHappiness,
      if (minAffection != null) 'min_affection': minAffection,
      if (minBeauty != null) 'min_beauty': minBeauty,
      if (relativePhysicalStats != null)
        'relative_physical_stats': relativePhysicalStats,
      if (partySpecies != null) 'party_species': partySpecies,
      if (partyType != null) 'party_type': partyType,
      if (tradeSpecies != null) 'trade_species': tradeSpecies,
      if (needsOverworldRain != null)
        'needs_overworld_rain': needsOverworldRain,
      if (turnUpsideDown != null) 'turn_upside_down': turnUpsideDown,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EvolutionEdgesCompanion copyWith(
      {Value<int>? chainId,
      Value<int?>? fromSpeciesId,
      Value<int>? toSpeciesId,
      Value<String>? trigger,
      Value<int?>? minLevel,
      Value<String?>? item,
      Value<String?>? heldItem,
      Value<String?>? knownMove,
      Value<String?>? knownMoveType,
      Value<String?>? location,
      Value<String?>? timeOfDay,
      Value<String?>? gender,
      Value<int?>? minHappiness,
      Value<int?>? minAffection,
      Value<int?>? minBeauty,
      Value<String?>? relativePhysicalStats,
      Value<String?>? partySpecies,
      Value<String?>? partyType,
      Value<String?>? tradeSpecies,
      Value<bool>? needsOverworldRain,
      Value<bool>? turnUpsideDown,
      Value<int>? rowid}) {
    return EvolutionEdgesCompanion(
      chainId: chainId ?? this.chainId,
      fromSpeciesId: fromSpeciesId ?? this.fromSpeciesId,
      toSpeciesId: toSpeciesId ?? this.toSpeciesId,
      trigger: trigger ?? this.trigger,
      minLevel: minLevel ?? this.minLevel,
      item: item ?? this.item,
      heldItem: heldItem ?? this.heldItem,
      knownMove: knownMove ?? this.knownMove,
      knownMoveType: knownMoveType ?? this.knownMoveType,
      location: location ?? this.location,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      gender: gender ?? this.gender,
      minHappiness: minHappiness ?? this.minHappiness,
      minAffection: minAffection ?? this.minAffection,
      minBeauty: minBeauty ?? this.minBeauty,
      relativePhysicalStats:
          relativePhysicalStats ?? this.relativePhysicalStats,
      partySpecies: partySpecies ?? this.partySpecies,
      partyType: partyType ?? this.partyType,
      tradeSpecies: tradeSpecies ?? this.tradeSpecies,
      needsOverworldRain: needsOverworldRain ?? this.needsOverworldRain,
      turnUpsideDown: turnUpsideDown ?? this.turnUpsideDown,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chainId.present) {
      map['chain_id'] = Variable<int>(chainId.value);
    }
    if (fromSpeciesId.present) {
      map['from_species_id'] = Variable<int>(fromSpeciesId.value);
    }
    if (toSpeciesId.present) {
      map['to_species_id'] = Variable<int>(toSpeciesId.value);
    }
    if (trigger.present) {
      map['trigger'] = Variable<String>(trigger.value);
    }
    if (minLevel.present) {
      map['min_level'] = Variable<int>(minLevel.value);
    }
    if (item.present) {
      map['item'] = Variable<String>(item.value);
    }
    if (heldItem.present) {
      map['held_item'] = Variable<String>(heldItem.value);
    }
    if (knownMove.present) {
      map['known_move'] = Variable<String>(knownMove.value);
    }
    if (knownMoveType.present) {
      map['known_move_type'] = Variable<String>(knownMoveType.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (timeOfDay.present) {
      map['time_of_day'] = Variable<String>(timeOfDay.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (minHappiness.present) {
      map['min_happiness'] = Variable<int>(minHappiness.value);
    }
    if (minAffection.present) {
      map['min_affection'] = Variable<int>(minAffection.value);
    }
    if (minBeauty.present) {
      map['min_beauty'] = Variable<int>(minBeauty.value);
    }
    if (relativePhysicalStats.present) {
      map['relative_physical_stats'] =
          Variable<String>(relativePhysicalStats.value);
    }
    if (partySpecies.present) {
      map['party_species'] = Variable<String>(partySpecies.value);
    }
    if (partyType.present) {
      map['party_type'] = Variable<String>(partyType.value);
    }
    if (tradeSpecies.present) {
      map['trade_species'] = Variable<String>(tradeSpecies.value);
    }
    if (needsOverworldRain.present) {
      map['needs_overworld_rain'] = Variable<bool>(needsOverworldRain.value);
    }
    if (turnUpsideDown.present) {
      map['turn_upside_down'] = Variable<bool>(turnUpsideDown.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EvolutionEdgesCompanion(')
          ..write('chainId: $chainId, ')
          ..write('fromSpeciesId: $fromSpeciesId, ')
          ..write('toSpeciesId: $toSpeciesId, ')
          ..write('trigger: $trigger, ')
          ..write('minLevel: $minLevel, ')
          ..write('item: $item, ')
          ..write('heldItem: $heldItem, ')
          ..write('knownMove: $knownMove, ')
          ..write('knownMoveType: $knownMoveType, ')
          ..write('location: $location, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('gender: $gender, ')
          ..write('minHappiness: $minHappiness, ')
          ..write('minAffection: $minAffection, ')
          ..write('minBeauty: $minBeauty, ')
          ..write('relativePhysicalStats: $relativePhysicalStats, ')
          ..write('partySpecies: $partySpecies, ')
          ..write('partyType: $partyType, ')
          ..write('tradeSpecies: $tradeSpecies, ')
          ..write('needsOverworldRain: $needsOverworldRain, ')
          ..write('turnUpsideDown: $turnUpsideDown, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VersionsTable extends Versions
    with TableInfo<$VersionsTable, VersionsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _identifierMeta =
      const VerificationMeta('identifier');
  @override
  late final GeneratedColumn<String> identifier = GeneratedColumn<String>(
      'identifier', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _generationIdMeta =
      const VerificationMeta('generationId');
  @override
  late final GeneratedColumn<int> generationId = GeneratedColumn<int>(
      'generation_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _versionGroupMeta =
      const VerificationMeta('versionGroup');
  @override
  late final GeneratedColumn<String> versionGroup = GeneratedColumn<String>(
      'version_group', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameZhHansMeta =
      const VerificationMeta('nameZhHans');
  @override
  late final GeneratedColumn<String> nameZhHans = GeneratedColumn<String>(
      'name_zh_hans', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
      'name_en', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameJaMeta = const VerificationMeta('nameJa');
  @override
  late final GeneratedColumn<String> nameJa = GeneratedColumn<String>(
      'name_ja', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, identifier, generationId, versionGroup, nameZhHans, nameEn, nameJa];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'versions';
  @override
  VerificationContext validateIntegrity(Insertable<VersionsRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('identifier')) {
      context.handle(
          _identifierMeta,
          identifier.isAcceptableOrUnknown(
              data['identifier']!, _identifierMeta));
    } else if (isInserting) {
      context.missing(_identifierMeta);
    }
    if (data.containsKey('generation_id')) {
      context.handle(
          _generationIdMeta,
          generationId.isAcceptableOrUnknown(
              data['generation_id']!, _generationIdMeta));
    } else if (isInserting) {
      context.missing(_generationIdMeta);
    }
    if (data.containsKey('version_group')) {
      context.handle(
          _versionGroupMeta,
          versionGroup.isAcceptableOrUnknown(
              data['version_group']!, _versionGroupMeta));
    } else if (isInserting) {
      context.missing(_versionGroupMeta);
    }
    if (data.containsKey('name_zh_hans')) {
      context.handle(
          _nameZhHansMeta,
          nameZhHans.isAcceptableOrUnknown(
              data['name_zh_hans']!, _nameZhHansMeta));
    }
    if (data.containsKey('name_en')) {
      context.handle(_nameEnMeta,
          nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta));
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('name_ja')) {
      context.handle(_nameJaMeta,
          nameJa.isAcceptableOrUnknown(data['name_ja']!, _nameJaMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  VersionsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VersionsRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      identifier: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}identifier'])!,
      generationId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}generation_id'])!,
      versionGroup: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}version_group'])!,
      nameZhHans: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_zh_hans']),
      nameEn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_en'])!,
      nameJa: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_ja']),
    );
  }

  @override
  $VersionsTable createAlias(String alias) {
    return $VersionsTable(attachedDatabase, alias);
  }
}

class VersionsRow extends DataClass implements Insertable<VersionsRow> {
  final int id;
  final String identifier;
  final int generationId;
  final String versionGroup;
  final String? nameZhHans;
  final String nameEn;
  final String? nameJa;
  const VersionsRow(
      {required this.id,
      required this.identifier,
      required this.generationId,
      required this.versionGroup,
      this.nameZhHans,
      required this.nameEn,
      this.nameJa});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['identifier'] = Variable<String>(identifier);
    map['generation_id'] = Variable<int>(generationId);
    map['version_group'] = Variable<String>(versionGroup);
    if (!nullToAbsent || nameZhHans != null) {
      map['name_zh_hans'] = Variable<String>(nameZhHans);
    }
    map['name_en'] = Variable<String>(nameEn);
    if (!nullToAbsent || nameJa != null) {
      map['name_ja'] = Variable<String>(nameJa);
    }
    return map;
  }

  VersionsCompanion toCompanion(bool nullToAbsent) {
    return VersionsCompanion(
      id: Value(id),
      identifier: Value(identifier),
      generationId: Value(generationId),
      versionGroup: Value(versionGroup),
      nameZhHans: nameZhHans == null && nullToAbsent
          ? const Value.absent()
          : Value(nameZhHans),
      nameEn: Value(nameEn),
      nameJa:
          nameJa == null && nullToAbsent ? const Value.absent() : Value(nameJa),
    );
  }

  factory VersionsRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VersionsRow(
      id: serializer.fromJson<int>(json['id']),
      identifier: serializer.fromJson<String>(json['identifier']),
      generationId: serializer.fromJson<int>(json['generationId']),
      versionGroup: serializer.fromJson<String>(json['versionGroup']),
      nameZhHans: serializer.fromJson<String?>(json['nameZhHans']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      nameJa: serializer.fromJson<String?>(json['nameJa']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'identifier': serializer.toJson<String>(identifier),
      'generationId': serializer.toJson<int>(generationId),
      'versionGroup': serializer.toJson<String>(versionGroup),
      'nameZhHans': serializer.toJson<String?>(nameZhHans),
      'nameEn': serializer.toJson<String>(nameEn),
      'nameJa': serializer.toJson<String?>(nameJa),
    };
  }

  VersionsRow copyWith(
          {int? id,
          String? identifier,
          int? generationId,
          String? versionGroup,
          Value<String?> nameZhHans = const Value.absent(),
          String? nameEn,
          Value<String?> nameJa = const Value.absent()}) =>
      VersionsRow(
        id: id ?? this.id,
        identifier: identifier ?? this.identifier,
        generationId: generationId ?? this.generationId,
        versionGroup: versionGroup ?? this.versionGroup,
        nameZhHans: nameZhHans.present ? nameZhHans.value : this.nameZhHans,
        nameEn: nameEn ?? this.nameEn,
        nameJa: nameJa.present ? nameJa.value : this.nameJa,
      );
  VersionsRow copyWithCompanion(VersionsCompanion data) {
    return VersionsRow(
      id: data.id.present ? data.id.value : this.id,
      identifier:
          data.identifier.present ? data.identifier.value : this.identifier,
      generationId: data.generationId.present
          ? data.generationId.value
          : this.generationId,
      versionGroup: data.versionGroup.present
          ? data.versionGroup.value
          : this.versionGroup,
      nameZhHans:
          data.nameZhHans.present ? data.nameZhHans.value : this.nameZhHans,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      nameJa: data.nameJa.present ? data.nameJa.value : this.nameJa,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VersionsRow(')
          ..write('id: $id, ')
          ..write('identifier: $identifier, ')
          ..write('generationId: $generationId, ')
          ..write('versionGroup: $versionGroup, ')
          ..write('nameZhHans: $nameZhHans, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameJa: $nameJa')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, identifier, generationId, versionGroup, nameZhHans, nameEn, nameJa);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VersionsRow &&
          other.id == this.id &&
          other.identifier == this.identifier &&
          other.generationId == this.generationId &&
          other.versionGroup == this.versionGroup &&
          other.nameZhHans == this.nameZhHans &&
          other.nameEn == this.nameEn &&
          other.nameJa == this.nameJa);
}

class VersionsCompanion extends UpdateCompanion<VersionsRow> {
  final Value<int> id;
  final Value<String> identifier;
  final Value<int> generationId;
  final Value<String> versionGroup;
  final Value<String?> nameZhHans;
  final Value<String> nameEn;
  final Value<String?> nameJa;
  final Value<int> rowid;
  const VersionsCompanion({
    this.id = const Value.absent(),
    this.identifier = const Value.absent(),
    this.generationId = const Value.absent(),
    this.versionGroup = const Value.absent(),
    this.nameZhHans = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.nameJa = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VersionsCompanion.insert({
    required int id,
    required String identifier,
    required int generationId,
    required String versionGroup,
    this.nameZhHans = const Value.absent(),
    required String nameEn,
    this.nameJa = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        identifier = Value(identifier),
        generationId = Value(generationId),
        versionGroup = Value(versionGroup),
        nameEn = Value(nameEn);
  static Insertable<VersionsRow> custom({
    Expression<int>? id,
    Expression<String>? identifier,
    Expression<int>? generationId,
    Expression<String>? versionGroup,
    Expression<String>? nameZhHans,
    Expression<String>? nameEn,
    Expression<String>? nameJa,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (identifier != null) 'identifier': identifier,
      if (generationId != null) 'generation_id': generationId,
      if (versionGroup != null) 'version_group': versionGroup,
      if (nameZhHans != null) 'name_zh_hans': nameZhHans,
      if (nameEn != null) 'name_en': nameEn,
      if (nameJa != null) 'name_ja': nameJa,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VersionsCompanion copyWith(
      {Value<int>? id,
      Value<String>? identifier,
      Value<int>? generationId,
      Value<String>? versionGroup,
      Value<String?>? nameZhHans,
      Value<String>? nameEn,
      Value<String?>? nameJa,
      Value<int>? rowid}) {
    return VersionsCompanion(
      id: id ?? this.id,
      identifier: identifier ?? this.identifier,
      generationId: generationId ?? this.generationId,
      versionGroup: versionGroup ?? this.versionGroup,
      nameZhHans: nameZhHans ?? this.nameZhHans,
      nameEn: nameEn ?? this.nameEn,
      nameJa: nameJa ?? this.nameJa,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (identifier.present) {
      map['identifier'] = Variable<String>(identifier.value);
    }
    if (generationId.present) {
      map['generation_id'] = Variable<int>(generationId.value);
    }
    if (versionGroup.present) {
      map['version_group'] = Variable<String>(versionGroup.value);
    }
    if (nameZhHans.present) {
      map['name_zh_hans'] = Variable<String>(nameZhHans.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (nameJa.present) {
      map['name_ja'] = Variable<String>(nameJa.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VersionsCompanion(')
          ..write('id: $id, ')
          ..write('identifier: $identifier, ')
          ..write('generationId: $generationId, ')
          ..write('versionGroup: $versionGroup, ')
          ..write('nameZhHans: $nameZhHans, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameJa: $nameJa, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FlavorTextsTable extends FlavorTexts
    with TableInfo<$FlavorTextsTable, FlavorTextsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FlavorTextsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _speciesIdMeta =
      const VerificationMeta('speciesId');
  @override
  late final GeneratedColumn<int> speciesId = GeneratedColumn<int>(
      'species_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _versionIdMeta =
      const VerificationMeta('versionId');
  @override
  late final GeneratedColumn<int> versionId = GeneratedColumn<int>(
      'version_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _languageMeta =
      const VerificationMeta('language');
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
      'language', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _flavorTextMeta =
      const VerificationMeta('flavorText');
  @override
  late final GeneratedColumn<String> flavorText = GeneratedColumn<String>(
      'flavor_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [speciesId, versionId, language, flavorText];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'flavor_texts';
  @override
  VerificationContext validateIntegrity(Insertable<FlavorTextsRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('species_id')) {
      context.handle(_speciesIdMeta,
          speciesId.isAcceptableOrUnknown(data['species_id']!, _speciesIdMeta));
    } else if (isInserting) {
      context.missing(_speciesIdMeta);
    }
    if (data.containsKey('version_id')) {
      context.handle(_versionIdMeta,
          versionId.isAcceptableOrUnknown(data['version_id']!, _versionIdMeta));
    } else if (isInserting) {
      context.missing(_versionIdMeta);
    }
    if (data.containsKey('language')) {
      context.handle(_languageMeta,
          language.isAcceptableOrUnknown(data['language']!, _languageMeta));
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('flavor_text')) {
      context.handle(
          _flavorTextMeta,
          flavorText.isAcceptableOrUnknown(
              data['flavor_text']!, _flavorTextMeta));
    } else if (isInserting) {
      context.missing(_flavorTextMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {speciesId, versionId, language};
  @override
  FlavorTextsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FlavorTextsRow(
      speciesId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}species_id'])!,
      versionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version_id'])!,
      language: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}language'])!,
      flavorText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}flavor_text'])!,
    );
  }

  @override
  $FlavorTextsTable createAlias(String alias) {
    return $FlavorTextsTable(attachedDatabase, alias);
  }
}

class FlavorTextsRow extends DataClass implements Insertable<FlavorTextsRow> {
  final int speciesId;
  final int versionId;
  final String language;
  final String flavorText;
  const FlavorTextsRow(
      {required this.speciesId,
      required this.versionId,
      required this.language,
      required this.flavorText});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['species_id'] = Variable<int>(speciesId);
    map['version_id'] = Variable<int>(versionId);
    map['language'] = Variable<String>(language);
    map['flavor_text'] = Variable<String>(flavorText);
    return map;
  }

  FlavorTextsCompanion toCompanion(bool nullToAbsent) {
    return FlavorTextsCompanion(
      speciesId: Value(speciesId),
      versionId: Value(versionId),
      language: Value(language),
      flavorText: Value(flavorText),
    );
  }

  factory FlavorTextsRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FlavorTextsRow(
      speciesId: serializer.fromJson<int>(json['speciesId']),
      versionId: serializer.fromJson<int>(json['versionId']),
      language: serializer.fromJson<String>(json['language']),
      flavorText: serializer.fromJson<String>(json['flavorText']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'speciesId': serializer.toJson<int>(speciesId),
      'versionId': serializer.toJson<int>(versionId),
      'language': serializer.toJson<String>(language),
      'flavorText': serializer.toJson<String>(flavorText),
    };
  }

  FlavorTextsRow copyWith(
          {int? speciesId,
          int? versionId,
          String? language,
          String? flavorText}) =>
      FlavorTextsRow(
        speciesId: speciesId ?? this.speciesId,
        versionId: versionId ?? this.versionId,
        language: language ?? this.language,
        flavorText: flavorText ?? this.flavorText,
      );
  FlavorTextsRow copyWithCompanion(FlavorTextsCompanion data) {
    return FlavorTextsRow(
      speciesId: data.speciesId.present ? data.speciesId.value : this.speciesId,
      versionId: data.versionId.present ? data.versionId.value : this.versionId,
      language: data.language.present ? data.language.value : this.language,
      flavorText:
          data.flavorText.present ? data.flavorText.value : this.flavorText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FlavorTextsRow(')
          ..write('speciesId: $speciesId, ')
          ..write('versionId: $versionId, ')
          ..write('language: $language, ')
          ..write('flavorText: $flavorText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(speciesId, versionId, language, flavorText);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlavorTextsRow &&
          other.speciesId == this.speciesId &&
          other.versionId == this.versionId &&
          other.language == this.language &&
          other.flavorText == this.flavorText);
}

class FlavorTextsCompanion extends UpdateCompanion<FlavorTextsRow> {
  final Value<int> speciesId;
  final Value<int> versionId;
  final Value<String> language;
  final Value<String> flavorText;
  final Value<int> rowid;
  const FlavorTextsCompanion({
    this.speciesId = const Value.absent(),
    this.versionId = const Value.absent(),
    this.language = const Value.absent(),
    this.flavorText = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FlavorTextsCompanion.insert({
    required int speciesId,
    required int versionId,
    required String language,
    required String flavorText,
    this.rowid = const Value.absent(),
  })  : speciesId = Value(speciesId),
        versionId = Value(versionId),
        language = Value(language),
        flavorText = Value(flavorText);
  static Insertable<FlavorTextsRow> custom({
    Expression<int>? speciesId,
    Expression<int>? versionId,
    Expression<String>? language,
    Expression<String>? flavorText,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (speciesId != null) 'species_id': speciesId,
      if (versionId != null) 'version_id': versionId,
      if (language != null) 'language': language,
      if (flavorText != null) 'flavor_text': flavorText,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FlavorTextsCompanion copyWith(
      {Value<int>? speciesId,
      Value<int>? versionId,
      Value<String>? language,
      Value<String>? flavorText,
      Value<int>? rowid}) {
    return FlavorTextsCompanion(
      speciesId: speciesId ?? this.speciesId,
      versionId: versionId ?? this.versionId,
      language: language ?? this.language,
      flavorText: flavorText ?? this.flavorText,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (speciesId.present) {
      map['species_id'] = Variable<int>(speciesId.value);
    }
    if (versionId.present) {
      map['version_id'] = Variable<int>(versionId.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (flavorText.present) {
      map['flavor_text'] = Variable<String>(flavorText.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FlavorTextsCompanion(')
          ..write('speciesId: $speciesId, ')
          ..write('versionId: $versionId, ')
          ..write('language: $language, ')
          ..write('flavorText: $flavorText, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PokedexesTable extends Pokedexes
    with TableInfo<$PokedexesTable, PokedexesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PokedexesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _identifierMeta =
      const VerificationMeta('identifier');
  @override
  late final GeneratedColumn<String> identifier = GeneratedColumn<String>(
      'identifier', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameZhHansMeta =
      const VerificationMeta('nameZhHans');
  @override
  late final GeneratedColumn<String> nameZhHans = GeneratedColumn<String>(
      'name_zh_hans', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _generationIdMeta =
      const VerificationMeta('generationId');
  @override
  late final GeneratedColumn<int> generationId = GeneratedColumn<int>(
      'generation_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, identifier, nameZhHans, generationId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pokedexes';
  @override
  VerificationContext validateIntegrity(Insertable<PokedexesRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('identifier')) {
      context.handle(
          _identifierMeta,
          identifier.isAcceptableOrUnknown(
              data['identifier']!, _identifierMeta));
    } else if (isInserting) {
      context.missing(_identifierMeta);
    }
    if (data.containsKey('name_zh_hans')) {
      context.handle(
          _nameZhHansMeta,
          nameZhHans.isAcceptableOrUnknown(
              data['name_zh_hans']!, _nameZhHansMeta));
    } else if (isInserting) {
      context.missing(_nameZhHansMeta);
    }
    if (data.containsKey('generation_id')) {
      context.handle(
          _generationIdMeta,
          generationId.isAcceptableOrUnknown(
              data['generation_id']!, _generationIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  PokedexesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PokedexesRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      identifier: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}identifier'])!,
      nameZhHans: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_zh_hans'])!,
      generationId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}generation_id']),
    );
  }

  @override
  $PokedexesTable createAlias(String alias) {
    return $PokedexesTable(attachedDatabase, alias);
  }
}

class PokedexesRow extends DataClass implements Insertable<PokedexesRow> {
  final int id;
  final String identifier;
  final String nameZhHans;
  final int? generationId;
  const PokedexesRow(
      {required this.id,
      required this.identifier,
      required this.nameZhHans,
      this.generationId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['identifier'] = Variable<String>(identifier);
    map['name_zh_hans'] = Variable<String>(nameZhHans);
    if (!nullToAbsent || generationId != null) {
      map['generation_id'] = Variable<int>(generationId);
    }
    return map;
  }

  PokedexesCompanion toCompanion(bool nullToAbsent) {
    return PokedexesCompanion(
      id: Value(id),
      identifier: Value(identifier),
      nameZhHans: Value(nameZhHans),
      generationId: generationId == null && nullToAbsent
          ? const Value.absent()
          : Value(generationId),
    );
  }

  factory PokedexesRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PokedexesRow(
      id: serializer.fromJson<int>(json['id']),
      identifier: serializer.fromJson<String>(json['identifier']),
      nameZhHans: serializer.fromJson<String>(json['nameZhHans']),
      generationId: serializer.fromJson<int?>(json['generationId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'identifier': serializer.toJson<String>(identifier),
      'nameZhHans': serializer.toJson<String>(nameZhHans),
      'generationId': serializer.toJson<int?>(generationId),
    };
  }

  PokedexesRow copyWith(
          {int? id,
          String? identifier,
          String? nameZhHans,
          Value<int?> generationId = const Value.absent()}) =>
      PokedexesRow(
        id: id ?? this.id,
        identifier: identifier ?? this.identifier,
        nameZhHans: nameZhHans ?? this.nameZhHans,
        generationId:
            generationId.present ? generationId.value : this.generationId,
      );
  PokedexesRow copyWithCompanion(PokedexesCompanion data) {
    return PokedexesRow(
      id: data.id.present ? data.id.value : this.id,
      identifier:
          data.identifier.present ? data.identifier.value : this.identifier,
      nameZhHans:
          data.nameZhHans.present ? data.nameZhHans.value : this.nameZhHans,
      generationId: data.generationId.present
          ? data.generationId.value
          : this.generationId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PokedexesRow(')
          ..write('id: $id, ')
          ..write('identifier: $identifier, ')
          ..write('nameZhHans: $nameZhHans, ')
          ..write('generationId: $generationId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, identifier, nameZhHans, generationId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PokedexesRow &&
          other.id == this.id &&
          other.identifier == this.identifier &&
          other.nameZhHans == this.nameZhHans &&
          other.generationId == this.generationId);
}

class PokedexesCompanion extends UpdateCompanion<PokedexesRow> {
  final Value<int> id;
  final Value<String> identifier;
  final Value<String> nameZhHans;
  final Value<int?> generationId;
  final Value<int> rowid;
  const PokedexesCompanion({
    this.id = const Value.absent(),
    this.identifier = const Value.absent(),
    this.nameZhHans = const Value.absent(),
    this.generationId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PokedexesCompanion.insert({
    required int id,
    required String identifier,
    required String nameZhHans,
    this.generationId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        identifier = Value(identifier),
        nameZhHans = Value(nameZhHans);
  static Insertable<PokedexesRow> custom({
    Expression<int>? id,
    Expression<String>? identifier,
    Expression<String>? nameZhHans,
    Expression<int>? generationId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (identifier != null) 'identifier': identifier,
      if (nameZhHans != null) 'name_zh_hans': nameZhHans,
      if (generationId != null) 'generation_id': generationId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PokedexesCompanion copyWith(
      {Value<int>? id,
      Value<String>? identifier,
      Value<String>? nameZhHans,
      Value<int?>? generationId,
      Value<int>? rowid}) {
    return PokedexesCompanion(
      id: id ?? this.id,
      identifier: identifier ?? this.identifier,
      nameZhHans: nameZhHans ?? this.nameZhHans,
      generationId: generationId ?? this.generationId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (identifier.present) {
      map['identifier'] = Variable<String>(identifier.value);
    }
    if (nameZhHans.present) {
      map['name_zh_hans'] = Variable<String>(nameZhHans.value);
    }
    if (generationId.present) {
      map['generation_id'] = Variable<int>(generationId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PokedexesCompanion(')
          ..write('id: $id, ')
          ..write('identifier: $identifier, ')
          ..write('nameZhHans: $nameZhHans, ')
          ..write('generationId: $generationId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SpeciesDexNumbersTable extends SpeciesDexNumbers
    with TableInfo<$SpeciesDexNumbersTable, SpeciesDexNumbersRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SpeciesDexNumbersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pokedexIdMeta =
      const VerificationMeta('pokedexId');
  @override
  late final GeneratedColumn<int> pokedexId = GeneratedColumn<int>(
      'pokedex_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _speciesIdMeta =
      const VerificationMeta('speciesId');
  @override
  late final GeneratedColumn<int> speciesId = GeneratedColumn<int>(
      'species_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _dexNumberMeta =
      const VerificationMeta('dexNumber');
  @override
  late final GeneratedColumn<int> dexNumber = GeneratedColumn<int>(
      'dex_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [pokedexId, speciesId, dexNumber];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'species_dex_numbers';
  @override
  VerificationContext validateIntegrity(
      Insertable<SpeciesDexNumbersRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pokedex_id')) {
      context.handle(_pokedexIdMeta,
          pokedexId.isAcceptableOrUnknown(data['pokedex_id']!, _pokedexIdMeta));
    } else if (isInserting) {
      context.missing(_pokedexIdMeta);
    }
    if (data.containsKey('species_id')) {
      context.handle(_speciesIdMeta,
          speciesId.isAcceptableOrUnknown(data['species_id']!, _speciesIdMeta));
    } else if (isInserting) {
      context.missing(_speciesIdMeta);
    }
    if (data.containsKey('dex_number')) {
      context.handle(_dexNumberMeta,
          dexNumber.isAcceptableOrUnknown(data['dex_number']!, _dexNumberMeta));
    } else if (isInserting) {
      context.missing(_dexNumberMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pokedexId, speciesId};
  @override
  SpeciesDexNumbersRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SpeciesDexNumbersRow(
      pokedexId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pokedex_id'])!,
      speciesId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}species_id'])!,
      dexNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}dex_number'])!,
    );
  }

  @override
  $SpeciesDexNumbersTable createAlias(String alias) {
    return $SpeciesDexNumbersTable(attachedDatabase, alias);
  }
}

class SpeciesDexNumbersRow extends DataClass
    implements Insertable<SpeciesDexNumbersRow> {
  final int pokedexId;
  final int speciesId;
  final int dexNumber;
  const SpeciesDexNumbersRow(
      {required this.pokedexId,
      required this.speciesId,
      required this.dexNumber});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pokedex_id'] = Variable<int>(pokedexId);
    map['species_id'] = Variable<int>(speciesId);
    map['dex_number'] = Variable<int>(dexNumber);
    return map;
  }

  SpeciesDexNumbersCompanion toCompanion(bool nullToAbsent) {
    return SpeciesDexNumbersCompanion(
      pokedexId: Value(pokedexId),
      speciesId: Value(speciesId),
      dexNumber: Value(dexNumber),
    );
  }

  factory SpeciesDexNumbersRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SpeciesDexNumbersRow(
      pokedexId: serializer.fromJson<int>(json['pokedexId']),
      speciesId: serializer.fromJson<int>(json['speciesId']),
      dexNumber: serializer.fromJson<int>(json['dexNumber']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pokedexId': serializer.toJson<int>(pokedexId),
      'speciesId': serializer.toJson<int>(speciesId),
      'dexNumber': serializer.toJson<int>(dexNumber),
    };
  }

  SpeciesDexNumbersRow copyWith(
          {int? pokedexId, int? speciesId, int? dexNumber}) =>
      SpeciesDexNumbersRow(
        pokedexId: pokedexId ?? this.pokedexId,
        speciesId: speciesId ?? this.speciesId,
        dexNumber: dexNumber ?? this.dexNumber,
      );
  SpeciesDexNumbersRow copyWithCompanion(SpeciesDexNumbersCompanion data) {
    return SpeciesDexNumbersRow(
      pokedexId: data.pokedexId.present ? data.pokedexId.value : this.pokedexId,
      speciesId: data.speciesId.present ? data.speciesId.value : this.speciesId,
      dexNumber: data.dexNumber.present ? data.dexNumber.value : this.dexNumber,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SpeciesDexNumbersRow(')
          ..write('pokedexId: $pokedexId, ')
          ..write('speciesId: $speciesId, ')
          ..write('dexNumber: $dexNumber')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(pokedexId, speciesId, dexNumber);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpeciesDexNumbersRow &&
          other.pokedexId == this.pokedexId &&
          other.speciesId == this.speciesId &&
          other.dexNumber == this.dexNumber);
}

class SpeciesDexNumbersCompanion extends UpdateCompanion<SpeciesDexNumbersRow> {
  final Value<int> pokedexId;
  final Value<int> speciesId;
  final Value<int> dexNumber;
  final Value<int> rowid;
  const SpeciesDexNumbersCompanion({
    this.pokedexId = const Value.absent(),
    this.speciesId = const Value.absent(),
    this.dexNumber = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SpeciesDexNumbersCompanion.insert({
    required int pokedexId,
    required int speciesId,
    required int dexNumber,
    this.rowid = const Value.absent(),
  })  : pokedexId = Value(pokedexId),
        speciesId = Value(speciesId),
        dexNumber = Value(dexNumber);
  static Insertable<SpeciesDexNumbersRow> custom({
    Expression<int>? pokedexId,
    Expression<int>? speciesId,
    Expression<int>? dexNumber,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pokedexId != null) 'pokedex_id': pokedexId,
      if (speciesId != null) 'species_id': speciesId,
      if (dexNumber != null) 'dex_number': dexNumber,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SpeciesDexNumbersCompanion copyWith(
      {Value<int>? pokedexId,
      Value<int>? speciesId,
      Value<int>? dexNumber,
      Value<int>? rowid}) {
    return SpeciesDexNumbersCompanion(
      pokedexId: pokedexId ?? this.pokedexId,
      speciesId: speciesId ?? this.speciesId,
      dexNumber: dexNumber ?? this.dexNumber,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pokedexId.present) {
      map['pokedex_id'] = Variable<int>(pokedexId.value);
    }
    if (speciesId.present) {
      map['species_id'] = Variable<int>(speciesId.value);
    }
    if (dexNumber.present) {
      map['dex_number'] = Variable<int>(dexNumber.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SpeciesDexNumbersCompanion(')
          ..write('pokedexId: $pokedexId, ')
          ..write('speciesId: $speciesId, ')
          ..write('dexNumber: $dexNumber, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$PokedexDatabase extends GeneratedDatabase {
  _$PokedexDatabase(QueryExecutor e) : super(e);
  $PokedexDatabaseManager get managers => $PokedexDatabaseManager(this);
  late final $MetaTable meta = $MetaTable(this);
  late final $GenerationsTable generations = $GenerationsTable(this);
  late final $TypesTable types = $TypesTable(this);
  late final $AbilitiesTable abilities = $AbilitiesTable(this);
  late final $MovesTable moves = $MovesTable(this);
  late final $SpeciesTable species = $SpeciesTable(this);
  late final $FormsTable forms = $FormsTable(this);
  late final $FormTypesTable formTypes = $FormTypesTable(this);
  late final $FormStatsTable formStats = $FormStatsTable(this);
  late final $FormAbilitiesTable formAbilities = $FormAbilitiesTable(this);
  late final $PokemonFormMovesTable pokemonFormMoves =
      $PokemonFormMovesTable(this);
  late final $EvolutionChainsTable evolutionChains =
      $EvolutionChainsTable(this);
  late final $EvolutionEdgesTable evolutionEdges = $EvolutionEdgesTable(this);
  late final $VersionsTable versions = $VersionsTable(this);
  late final $FlavorTextsTable flavorTexts = $FlavorTextsTable(this);
  late final $PokedexesTable pokedexes = $PokedexesTable(this);
  late final $SpeciesDexNumbersTable speciesDexNumbers =
      $SpeciesDexNumbersTable(this);
  late final PokedexDao pokedexDao = PokedexDao(this as PokedexDatabase);
  late final MoveDao moveDao = MoveDao(this as PokedexDatabase);
  late final EvolutionDao evolutionDao = EvolutionDao(this as PokedexDatabase);
  late final MetaDao metaDao = MetaDao(this as PokedexDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        meta,
        generations,
        types,
        abilities,
        moves,
        species,
        forms,
        formTypes,
        formStats,
        formAbilities,
        pokemonFormMoves,
        evolutionChains,
        evolutionEdges,
        versions,
        flavorTexts,
        pokedexes,
        speciesDexNumbers
      ];
}

typedef $$MetaTableCreateCompanionBuilder = MetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$MetaTableUpdateCompanionBuilder = MetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$MetaTableFilterComposer
    extends Composer<_$PokedexDatabase, $MetaTable> {
  $$MetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$MetaTableOrderingComposer
    extends Composer<_$PokedexDatabase, $MetaTable> {
  $$MetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$MetaTableAnnotationComposer
    extends Composer<_$PokedexDatabase, $MetaTable> {
  $$MetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$MetaTableTableManager extends RootTableManager<
    _$PokedexDatabase,
    $MetaTable,
    MetaRow,
    $$MetaTableFilterComposer,
    $$MetaTableOrderingComposer,
    $$MetaTableAnnotationComposer,
    $$MetaTableCreateCompanionBuilder,
    $$MetaTableUpdateCompanionBuilder,
    (MetaRow, BaseReferences<_$PokedexDatabase, $MetaTable, MetaRow>),
    MetaRow,
    PrefetchHooks Function()> {
  $$MetaTableTableManager(_$PokedexDatabase db, $MetaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MetaCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              MetaCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MetaTableProcessedTableManager = ProcessedTableManager<
    _$PokedexDatabase,
    $MetaTable,
    MetaRow,
    $$MetaTableFilterComposer,
    $$MetaTableOrderingComposer,
    $$MetaTableAnnotationComposer,
    $$MetaTableCreateCompanionBuilder,
    $$MetaTableUpdateCompanionBuilder,
    (MetaRow, BaseReferences<_$PokedexDatabase, $MetaTable, MetaRow>),
    MetaRow,
    PrefetchHooks Function()>;
typedef $$GenerationsTableCreateCompanionBuilder = GenerationsCompanion
    Function({
  required int id,
  required String identifier,
  required String region,
  Value<int> rowid,
});
typedef $$GenerationsTableUpdateCompanionBuilder = GenerationsCompanion
    Function({
  Value<int> id,
  Value<String> identifier,
  Value<String> region,
  Value<int> rowid,
});

class $$GenerationsTableFilterComposer
    extends Composer<_$PokedexDatabase, $GenerationsTable> {
  $$GenerationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get identifier => $composableBuilder(
      column: $table.identifier, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get region => $composableBuilder(
      column: $table.region, builder: (column) => ColumnFilters(column));
}

class $$GenerationsTableOrderingComposer
    extends Composer<_$PokedexDatabase, $GenerationsTable> {
  $$GenerationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get identifier => $composableBuilder(
      column: $table.identifier, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get region => $composableBuilder(
      column: $table.region, builder: (column) => ColumnOrderings(column));
}

class $$GenerationsTableAnnotationComposer
    extends Composer<_$PokedexDatabase, $GenerationsTable> {
  $$GenerationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get identifier => $composableBuilder(
      column: $table.identifier, builder: (column) => column);

  GeneratedColumn<String> get region =>
      $composableBuilder(column: $table.region, builder: (column) => column);
}

class $$GenerationsTableTableManager extends RootTableManager<
    _$PokedexDatabase,
    $GenerationsTable,
    GenerationsRow,
    $$GenerationsTableFilterComposer,
    $$GenerationsTableOrderingComposer,
    $$GenerationsTableAnnotationComposer,
    $$GenerationsTableCreateCompanionBuilder,
    $$GenerationsTableUpdateCompanionBuilder,
    (
      GenerationsRow,
      BaseReferences<_$PokedexDatabase, $GenerationsTable, GenerationsRow>
    ),
    GenerationsRow,
    PrefetchHooks Function()> {
  $$GenerationsTableTableManager(_$PokedexDatabase db, $GenerationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GenerationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GenerationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GenerationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> identifier = const Value.absent(),
            Value<String> region = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GenerationsCompanion(
            id: id,
            identifier: identifier,
            region: region,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int id,
            required String identifier,
            required String region,
            Value<int> rowid = const Value.absent(),
          }) =>
              GenerationsCompanion.insert(
            id: id,
            identifier: identifier,
            region: region,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GenerationsTableProcessedTableManager = ProcessedTableManager<
    _$PokedexDatabase,
    $GenerationsTable,
    GenerationsRow,
    $$GenerationsTableFilterComposer,
    $$GenerationsTableOrderingComposer,
    $$GenerationsTableAnnotationComposer,
    $$GenerationsTableCreateCompanionBuilder,
    $$GenerationsTableUpdateCompanionBuilder,
    (
      GenerationsRow,
      BaseReferences<_$PokedexDatabase, $GenerationsTable, GenerationsRow>
    ),
    GenerationsRow,
    PrefetchHooks Function()>;
typedef $$TypesTableCreateCompanionBuilder = TypesCompanion Function({
  required int id,
  required String identifier,
  required String nameZhHans,
  required String nameZhHant,
  required String nameEn,
  required String nameJa,
  Value<int> rowid,
});
typedef $$TypesTableUpdateCompanionBuilder = TypesCompanion Function({
  Value<int> id,
  Value<String> identifier,
  Value<String> nameZhHans,
  Value<String> nameZhHant,
  Value<String> nameEn,
  Value<String> nameJa,
  Value<int> rowid,
});

class $$TypesTableFilterComposer
    extends Composer<_$PokedexDatabase, $TypesTable> {
  $$TypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get identifier => $composableBuilder(
      column: $table.identifier, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameZhHans => $composableBuilder(
      column: $table.nameZhHans, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameZhHant => $composableBuilder(
      column: $table.nameZhHant, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameEn => $composableBuilder(
      column: $table.nameEn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameJa => $composableBuilder(
      column: $table.nameJa, builder: (column) => ColumnFilters(column));
}

class $$TypesTableOrderingComposer
    extends Composer<_$PokedexDatabase, $TypesTable> {
  $$TypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get identifier => $composableBuilder(
      column: $table.identifier, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameZhHans => $composableBuilder(
      column: $table.nameZhHans, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameZhHant => $composableBuilder(
      column: $table.nameZhHant, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameEn => $composableBuilder(
      column: $table.nameEn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameJa => $composableBuilder(
      column: $table.nameJa, builder: (column) => ColumnOrderings(column));
}

class $$TypesTableAnnotationComposer
    extends Composer<_$PokedexDatabase, $TypesTable> {
  $$TypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get identifier => $composableBuilder(
      column: $table.identifier, builder: (column) => column);

  GeneratedColumn<String> get nameZhHans => $composableBuilder(
      column: $table.nameZhHans, builder: (column) => column);

  GeneratedColumn<String> get nameZhHant => $composableBuilder(
      column: $table.nameZhHant, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get nameJa =>
      $composableBuilder(column: $table.nameJa, builder: (column) => column);
}

class $$TypesTableTableManager extends RootTableManager<
    _$PokedexDatabase,
    $TypesTable,
    TypesRow,
    $$TypesTableFilterComposer,
    $$TypesTableOrderingComposer,
    $$TypesTableAnnotationComposer,
    $$TypesTableCreateCompanionBuilder,
    $$TypesTableUpdateCompanionBuilder,
    (TypesRow, BaseReferences<_$PokedexDatabase, $TypesTable, TypesRow>),
    TypesRow,
    PrefetchHooks Function()> {
  $$TypesTableTableManager(_$PokedexDatabase db, $TypesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> identifier = const Value.absent(),
            Value<String> nameZhHans = const Value.absent(),
            Value<String> nameZhHant = const Value.absent(),
            Value<String> nameEn = const Value.absent(),
            Value<String> nameJa = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TypesCompanion(
            id: id,
            identifier: identifier,
            nameZhHans: nameZhHans,
            nameZhHant: nameZhHant,
            nameEn: nameEn,
            nameJa: nameJa,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int id,
            required String identifier,
            required String nameZhHans,
            required String nameZhHant,
            required String nameEn,
            required String nameJa,
            Value<int> rowid = const Value.absent(),
          }) =>
              TypesCompanion.insert(
            id: id,
            identifier: identifier,
            nameZhHans: nameZhHans,
            nameZhHant: nameZhHant,
            nameEn: nameEn,
            nameJa: nameJa,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TypesTableProcessedTableManager = ProcessedTableManager<
    _$PokedexDatabase,
    $TypesTable,
    TypesRow,
    $$TypesTableFilterComposer,
    $$TypesTableOrderingComposer,
    $$TypesTableAnnotationComposer,
    $$TypesTableCreateCompanionBuilder,
    $$TypesTableUpdateCompanionBuilder,
    (TypesRow, BaseReferences<_$PokedexDatabase, $TypesTable, TypesRow>),
    TypesRow,
    PrefetchHooks Function()>;
typedef $$AbilitiesTableCreateCompanionBuilder = AbilitiesCompanion Function({
  required int id,
  required String identifier,
  required String nameZhHans,
  required String nameEn,
  required String nameJa,
  required int generationId,
  Value<String?> textZhHans,
  Value<String?> textEn,
  Value<int> rowid,
});
typedef $$AbilitiesTableUpdateCompanionBuilder = AbilitiesCompanion Function({
  Value<int> id,
  Value<String> identifier,
  Value<String> nameZhHans,
  Value<String> nameEn,
  Value<String> nameJa,
  Value<int> generationId,
  Value<String?> textZhHans,
  Value<String?> textEn,
  Value<int> rowid,
});

class $$AbilitiesTableFilterComposer
    extends Composer<_$PokedexDatabase, $AbilitiesTable> {
  $$AbilitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get identifier => $composableBuilder(
      column: $table.identifier, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameZhHans => $composableBuilder(
      column: $table.nameZhHans, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameEn => $composableBuilder(
      column: $table.nameEn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameJa => $composableBuilder(
      column: $table.nameJa, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get generationId => $composableBuilder(
      column: $table.generationId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get textZhHans => $composableBuilder(
      column: $table.textZhHans, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get textEn => $composableBuilder(
      column: $table.textEn, builder: (column) => ColumnFilters(column));
}

class $$AbilitiesTableOrderingComposer
    extends Composer<_$PokedexDatabase, $AbilitiesTable> {
  $$AbilitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get identifier => $composableBuilder(
      column: $table.identifier, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameZhHans => $composableBuilder(
      column: $table.nameZhHans, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameEn => $composableBuilder(
      column: $table.nameEn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameJa => $composableBuilder(
      column: $table.nameJa, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get generationId => $composableBuilder(
      column: $table.generationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get textZhHans => $composableBuilder(
      column: $table.textZhHans, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get textEn => $composableBuilder(
      column: $table.textEn, builder: (column) => ColumnOrderings(column));
}

class $$AbilitiesTableAnnotationComposer
    extends Composer<_$PokedexDatabase, $AbilitiesTable> {
  $$AbilitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get identifier => $composableBuilder(
      column: $table.identifier, builder: (column) => column);

  GeneratedColumn<String> get nameZhHans => $composableBuilder(
      column: $table.nameZhHans, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get nameJa =>
      $composableBuilder(column: $table.nameJa, builder: (column) => column);

  GeneratedColumn<int> get generationId => $composableBuilder(
      column: $table.generationId, builder: (column) => column);

  GeneratedColumn<String> get textZhHans => $composableBuilder(
      column: $table.textZhHans, builder: (column) => column);

  GeneratedColumn<String> get textEn =>
      $composableBuilder(column: $table.textEn, builder: (column) => column);
}

class $$AbilitiesTableTableManager extends RootTableManager<
    _$PokedexDatabase,
    $AbilitiesTable,
    AbilitiesRow,
    $$AbilitiesTableFilterComposer,
    $$AbilitiesTableOrderingComposer,
    $$AbilitiesTableAnnotationComposer,
    $$AbilitiesTableCreateCompanionBuilder,
    $$AbilitiesTableUpdateCompanionBuilder,
    (
      AbilitiesRow,
      BaseReferences<_$PokedexDatabase, $AbilitiesTable, AbilitiesRow>
    ),
    AbilitiesRow,
    PrefetchHooks Function()> {
  $$AbilitiesTableTableManager(_$PokedexDatabase db, $AbilitiesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AbilitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AbilitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AbilitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> identifier = const Value.absent(),
            Value<String> nameZhHans = const Value.absent(),
            Value<String> nameEn = const Value.absent(),
            Value<String> nameJa = const Value.absent(),
            Value<int> generationId = const Value.absent(),
            Value<String?> textZhHans = const Value.absent(),
            Value<String?> textEn = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AbilitiesCompanion(
            id: id,
            identifier: identifier,
            nameZhHans: nameZhHans,
            nameEn: nameEn,
            nameJa: nameJa,
            generationId: generationId,
            textZhHans: textZhHans,
            textEn: textEn,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int id,
            required String identifier,
            required String nameZhHans,
            required String nameEn,
            required String nameJa,
            required int generationId,
            Value<String?> textZhHans = const Value.absent(),
            Value<String?> textEn = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AbilitiesCompanion.insert(
            id: id,
            identifier: identifier,
            nameZhHans: nameZhHans,
            nameEn: nameEn,
            nameJa: nameJa,
            generationId: generationId,
            textZhHans: textZhHans,
            textEn: textEn,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AbilitiesTableProcessedTableManager = ProcessedTableManager<
    _$PokedexDatabase,
    $AbilitiesTable,
    AbilitiesRow,
    $$AbilitiesTableFilterComposer,
    $$AbilitiesTableOrderingComposer,
    $$AbilitiesTableAnnotationComposer,
    $$AbilitiesTableCreateCompanionBuilder,
    $$AbilitiesTableUpdateCompanionBuilder,
    (
      AbilitiesRow,
      BaseReferences<_$PokedexDatabase, $AbilitiesTable, AbilitiesRow>
    ),
    AbilitiesRow,
    PrefetchHooks Function()>;
typedef $$MovesTableCreateCompanionBuilder = MovesCompanion Function({
  required int id,
  required String identifier,
  required int generationId,
  required int typeId,
  required String damageClass,
  Value<int?> power,
  Value<int?> pp,
  Value<int?> accuracy,
  required int priority,
  Value<String?> target,
  Value<int?> effectChance,
  required String nameZhHans,
  required String nameEn,
  required String nameJa,
  Value<String?> effectEn,
  Value<String?> flavorZhHans,
  Value<int> rowid,
});
typedef $$MovesTableUpdateCompanionBuilder = MovesCompanion Function({
  Value<int> id,
  Value<String> identifier,
  Value<int> generationId,
  Value<int> typeId,
  Value<String> damageClass,
  Value<int?> power,
  Value<int?> pp,
  Value<int?> accuracy,
  Value<int> priority,
  Value<String?> target,
  Value<int?> effectChance,
  Value<String> nameZhHans,
  Value<String> nameEn,
  Value<String> nameJa,
  Value<String?> effectEn,
  Value<String?> flavorZhHans,
  Value<int> rowid,
});

class $$MovesTableFilterComposer
    extends Composer<_$PokedexDatabase, $MovesTable> {
  $$MovesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get identifier => $composableBuilder(
      column: $table.identifier, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get generationId => $composableBuilder(
      column: $table.generationId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get typeId => $composableBuilder(
      column: $table.typeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get damageClass => $composableBuilder(
      column: $table.damageClass, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get power => $composableBuilder(
      column: $table.power, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pp => $composableBuilder(
      column: $table.pp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get accuracy => $composableBuilder(
      column: $table.accuracy, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get target => $composableBuilder(
      column: $table.target, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get effectChance => $composableBuilder(
      column: $table.effectChance, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameZhHans => $composableBuilder(
      column: $table.nameZhHans, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameEn => $composableBuilder(
      column: $table.nameEn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameJa => $composableBuilder(
      column: $table.nameJa, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get effectEn => $composableBuilder(
      column: $table.effectEn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get flavorZhHans => $composableBuilder(
      column: $table.flavorZhHans, builder: (column) => ColumnFilters(column));
}

class $$MovesTableOrderingComposer
    extends Composer<_$PokedexDatabase, $MovesTable> {
  $$MovesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get identifier => $composableBuilder(
      column: $table.identifier, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get generationId => $composableBuilder(
      column: $table.generationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get typeId => $composableBuilder(
      column: $table.typeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get damageClass => $composableBuilder(
      column: $table.damageClass, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get power => $composableBuilder(
      column: $table.power, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pp => $composableBuilder(
      column: $table.pp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get accuracy => $composableBuilder(
      column: $table.accuracy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get target => $composableBuilder(
      column: $table.target, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get effectChance => $composableBuilder(
      column: $table.effectChance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameZhHans => $composableBuilder(
      column: $table.nameZhHans, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameEn => $composableBuilder(
      column: $table.nameEn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameJa => $composableBuilder(
      column: $table.nameJa, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get effectEn => $composableBuilder(
      column: $table.effectEn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get flavorZhHans => $composableBuilder(
      column: $table.flavorZhHans,
      builder: (column) => ColumnOrderings(column));
}

class $$MovesTableAnnotationComposer
    extends Composer<_$PokedexDatabase, $MovesTable> {
  $$MovesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get identifier => $composableBuilder(
      column: $table.identifier, builder: (column) => column);

  GeneratedColumn<int> get generationId => $composableBuilder(
      column: $table.generationId, builder: (column) => column);

  GeneratedColumn<int> get typeId =>
      $composableBuilder(column: $table.typeId, builder: (column) => column);

  GeneratedColumn<String> get damageClass => $composableBuilder(
      column: $table.damageClass, builder: (column) => column);

  GeneratedColumn<int> get power =>
      $composableBuilder(column: $table.power, builder: (column) => column);

  GeneratedColumn<int> get pp =>
      $composableBuilder(column: $table.pp, builder: (column) => column);

  GeneratedColumn<int> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumn<int> get effectChance => $composableBuilder(
      column: $table.effectChance, builder: (column) => column);

  GeneratedColumn<String> get nameZhHans => $composableBuilder(
      column: $table.nameZhHans, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get nameJa =>
      $composableBuilder(column: $table.nameJa, builder: (column) => column);

  GeneratedColumn<String> get effectEn =>
      $composableBuilder(column: $table.effectEn, builder: (column) => column);

  GeneratedColumn<String> get flavorZhHans => $composableBuilder(
      column: $table.flavorZhHans, builder: (column) => column);
}

class $$MovesTableTableManager extends RootTableManager<
    _$PokedexDatabase,
    $MovesTable,
    MovesRow,
    $$MovesTableFilterComposer,
    $$MovesTableOrderingComposer,
    $$MovesTableAnnotationComposer,
    $$MovesTableCreateCompanionBuilder,
    $$MovesTableUpdateCompanionBuilder,
    (MovesRow, BaseReferences<_$PokedexDatabase, $MovesTable, MovesRow>),
    MovesRow,
    PrefetchHooks Function()> {
  $$MovesTableTableManager(_$PokedexDatabase db, $MovesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MovesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MovesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MovesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> identifier = const Value.absent(),
            Value<int> generationId = const Value.absent(),
            Value<int> typeId = const Value.absent(),
            Value<String> damageClass = const Value.absent(),
            Value<int?> power = const Value.absent(),
            Value<int?> pp = const Value.absent(),
            Value<int?> accuracy = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<String?> target = const Value.absent(),
            Value<int?> effectChance = const Value.absent(),
            Value<String> nameZhHans = const Value.absent(),
            Value<String> nameEn = const Value.absent(),
            Value<String> nameJa = const Value.absent(),
            Value<String?> effectEn = const Value.absent(),
            Value<String?> flavorZhHans = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MovesCompanion(
            id: id,
            identifier: identifier,
            generationId: generationId,
            typeId: typeId,
            damageClass: damageClass,
            power: power,
            pp: pp,
            accuracy: accuracy,
            priority: priority,
            target: target,
            effectChance: effectChance,
            nameZhHans: nameZhHans,
            nameEn: nameEn,
            nameJa: nameJa,
            effectEn: effectEn,
            flavorZhHans: flavorZhHans,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int id,
            required String identifier,
            required int generationId,
            required int typeId,
            required String damageClass,
            Value<int?> power = const Value.absent(),
            Value<int?> pp = const Value.absent(),
            Value<int?> accuracy = const Value.absent(),
            required int priority,
            Value<String?> target = const Value.absent(),
            Value<int?> effectChance = const Value.absent(),
            required String nameZhHans,
            required String nameEn,
            required String nameJa,
            Value<String?> effectEn = const Value.absent(),
            Value<String?> flavorZhHans = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MovesCompanion.insert(
            id: id,
            identifier: identifier,
            generationId: generationId,
            typeId: typeId,
            damageClass: damageClass,
            power: power,
            pp: pp,
            accuracy: accuracy,
            priority: priority,
            target: target,
            effectChance: effectChance,
            nameZhHans: nameZhHans,
            nameEn: nameEn,
            nameJa: nameJa,
            effectEn: effectEn,
            flavorZhHans: flavorZhHans,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MovesTableProcessedTableManager = ProcessedTableManager<
    _$PokedexDatabase,
    $MovesTable,
    MovesRow,
    $$MovesTableFilterComposer,
    $$MovesTableOrderingComposer,
    $$MovesTableAnnotationComposer,
    $$MovesTableCreateCompanionBuilder,
    $$MovesTableUpdateCompanionBuilder,
    (MovesRow, BaseReferences<_$PokedexDatabase, $MovesTable, MovesRow>),
    MovesRow,
    PrefetchHooks Function()>;
typedef $$SpeciesTableCreateCompanionBuilder = SpeciesCompanion Function({
  required int id,
  required int nationalDex,
  required int generationId,
  required String nameZhHans,
  required String nameZhHant,
  required String nameEn,
  required String nameJa,
  required String nameJaHrkt,
  Value<String?> nameRoomaji,
  Value<String?> genusZhHans,
  Value<String?> genusEn,
  required bool isLegendary,
  required bool isMythical,
  required bool isUltraBeast,
  required bool isBaby,
  Value<int?> evolutionChainId,
  Value<int?> captureRate,
  Value<int?> baseHappiness,
  Value<int?> genderRate,
  Value<int?> hatchCounter,
  Value<String?> growthRate,
  Value<String?> eggGroup1,
  Value<String?> eggGroup2,
  Value<String?> color,
  Value<String?> shape,
  Value<String?> habitat,
  Value<int> rowid,
});
typedef $$SpeciesTableUpdateCompanionBuilder = SpeciesCompanion Function({
  Value<int> id,
  Value<int> nationalDex,
  Value<int> generationId,
  Value<String> nameZhHans,
  Value<String> nameZhHant,
  Value<String> nameEn,
  Value<String> nameJa,
  Value<String> nameJaHrkt,
  Value<String?> nameRoomaji,
  Value<String?> genusZhHans,
  Value<String?> genusEn,
  Value<bool> isLegendary,
  Value<bool> isMythical,
  Value<bool> isUltraBeast,
  Value<bool> isBaby,
  Value<int?> evolutionChainId,
  Value<int?> captureRate,
  Value<int?> baseHappiness,
  Value<int?> genderRate,
  Value<int?> hatchCounter,
  Value<String?> growthRate,
  Value<String?> eggGroup1,
  Value<String?> eggGroup2,
  Value<String?> color,
  Value<String?> shape,
  Value<String?> habitat,
  Value<int> rowid,
});

class $$SpeciesTableFilterComposer
    extends Composer<_$PokedexDatabase, $SpeciesTable> {
  $$SpeciesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get nationalDex => $composableBuilder(
      column: $table.nationalDex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get generationId => $composableBuilder(
      column: $table.generationId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameZhHans => $composableBuilder(
      column: $table.nameZhHans, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameZhHant => $composableBuilder(
      column: $table.nameZhHant, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameEn => $composableBuilder(
      column: $table.nameEn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameJa => $composableBuilder(
      column: $table.nameJa, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameJaHrkt => $composableBuilder(
      column: $table.nameJaHrkt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameRoomaji => $composableBuilder(
      column: $table.nameRoomaji, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genusZhHans => $composableBuilder(
      column: $table.genusZhHans, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genusEn => $composableBuilder(
      column: $table.genusEn, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isLegendary => $composableBuilder(
      column: $table.isLegendary, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isMythical => $composableBuilder(
      column: $table.isMythical, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isUltraBeast => $composableBuilder(
      column: $table.isUltraBeast, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isBaby => $composableBuilder(
      column: $table.isBaby, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get evolutionChainId => $composableBuilder(
      column: $table.evolutionChainId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get captureRate => $composableBuilder(
      column: $table.captureRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get baseHappiness => $composableBuilder(
      column: $table.baseHappiness, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get genderRate => $composableBuilder(
      column: $table.genderRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hatchCounter => $composableBuilder(
      column: $table.hatchCounter, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get growthRate => $composableBuilder(
      column: $table.growthRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eggGroup1 => $composableBuilder(
      column: $table.eggGroup1, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eggGroup2 => $composableBuilder(
      column: $table.eggGroup2, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get shape => $composableBuilder(
      column: $table.shape, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get habitat => $composableBuilder(
      column: $table.habitat, builder: (column) => ColumnFilters(column));
}

class $$SpeciesTableOrderingComposer
    extends Composer<_$PokedexDatabase, $SpeciesTable> {
  $$SpeciesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get nationalDex => $composableBuilder(
      column: $table.nationalDex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get generationId => $composableBuilder(
      column: $table.generationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameZhHans => $composableBuilder(
      column: $table.nameZhHans, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameZhHant => $composableBuilder(
      column: $table.nameZhHant, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameEn => $composableBuilder(
      column: $table.nameEn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameJa => $composableBuilder(
      column: $table.nameJa, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameJaHrkt => $composableBuilder(
      column: $table.nameJaHrkt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameRoomaji => $composableBuilder(
      column: $table.nameRoomaji, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genusZhHans => $composableBuilder(
      column: $table.genusZhHans, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genusEn => $composableBuilder(
      column: $table.genusEn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isLegendary => $composableBuilder(
      column: $table.isLegendary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isMythical => $composableBuilder(
      column: $table.isMythical, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isUltraBeast => $composableBuilder(
      column: $table.isUltraBeast,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isBaby => $composableBuilder(
      column: $table.isBaby, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get evolutionChainId => $composableBuilder(
      column: $table.evolutionChainId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get captureRate => $composableBuilder(
      column: $table.captureRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get baseHappiness => $composableBuilder(
      column: $table.baseHappiness,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get genderRate => $composableBuilder(
      column: $table.genderRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hatchCounter => $composableBuilder(
      column: $table.hatchCounter,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get growthRate => $composableBuilder(
      column: $table.growthRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eggGroup1 => $composableBuilder(
      column: $table.eggGroup1, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eggGroup2 => $composableBuilder(
      column: $table.eggGroup2, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get shape => $composableBuilder(
      column: $table.shape, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get habitat => $composableBuilder(
      column: $table.habitat, builder: (column) => ColumnOrderings(column));
}

class $$SpeciesTableAnnotationComposer
    extends Composer<_$PokedexDatabase, $SpeciesTable> {
  $$SpeciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get nationalDex => $composableBuilder(
      column: $table.nationalDex, builder: (column) => column);

  GeneratedColumn<int> get generationId => $composableBuilder(
      column: $table.generationId, builder: (column) => column);

  GeneratedColumn<String> get nameZhHans => $composableBuilder(
      column: $table.nameZhHans, builder: (column) => column);

  GeneratedColumn<String> get nameZhHant => $composableBuilder(
      column: $table.nameZhHant, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get nameJa =>
      $composableBuilder(column: $table.nameJa, builder: (column) => column);

  GeneratedColumn<String> get nameJaHrkt => $composableBuilder(
      column: $table.nameJaHrkt, builder: (column) => column);

  GeneratedColumn<String> get nameRoomaji => $composableBuilder(
      column: $table.nameRoomaji, builder: (column) => column);

  GeneratedColumn<String> get genusZhHans => $composableBuilder(
      column: $table.genusZhHans, builder: (column) => column);

  GeneratedColumn<String> get genusEn =>
      $composableBuilder(column: $table.genusEn, builder: (column) => column);

  GeneratedColumn<bool> get isLegendary => $composableBuilder(
      column: $table.isLegendary, builder: (column) => column);

  GeneratedColumn<bool> get isMythical => $composableBuilder(
      column: $table.isMythical, builder: (column) => column);

  GeneratedColumn<bool> get isUltraBeast => $composableBuilder(
      column: $table.isUltraBeast, builder: (column) => column);

  GeneratedColumn<bool> get isBaby =>
      $composableBuilder(column: $table.isBaby, builder: (column) => column);

  GeneratedColumn<int> get evolutionChainId => $composableBuilder(
      column: $table.evolutionChainId, builder: (column) => column);

  GeneratedColumn<int> get captureRate => $composableBuilder(
      column: $table.captureRate, builder: (column) => column);

  GeneratedColumn<int> get baseHappiness => $composableBuilder(
      column: $table.baseHappiness, builder: (column) => column);

  GeneratedColumn<int> get genderRate => $composableBuilder(
      column: $table.genderRate, builder: (column) => column);

  GeneratedColumn<int> get hatchCounter => $composableBuilder(
      column: $table.hatchCounter, builder: (column) => column);

  GeneratedColumn<String> get growthRate => $composableBuilder(
      column: $table.growthRate, builder: (column) => column);

  GeneratedColumn<String> get eggGroup1 =>
      $composableBuilder(column: $table.eggGroup1, builder: (column) => column);

  GeneratedColumn<String> get eggGroup2 =>
      $composableBuilder(column: $table.eggGroup2, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get shape =>
      $composableBuilder(column: $table.shape, builder: (column) => column);

  GeneratedColumn<String> get habitat =>
      $composableBuilder(column: $table.habitat, builder: (column) => column);
}

class $$SpeciesTableTableManager extends RootTableManager<
    _$PokedexDatabase,
    $SpeciesTable,
    SpeciesRow,
    $$SpeciesTableFilterComposer,
    $$SpeciesTableOrderingComposer,
    $$SpeciesTableAnnotationComposer,
    $$SpeciesTableCreateCompanionBuilder,
    $$SpeciesTableUpdateCompanionBuilder,
    (SpeciesRow, BaseReferences<_$PokedexDatabase, $SpeciesTable, SpeciesRow>),
    SpeciesRow,
    PrefetchHooks Function()> {
  $$SpeciesTableTableManager(_$PokedexDatabase db, $SpeciesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SpeciesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SpeciesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SpeciesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> nationalDex = const Value.absent(),
            Value<int> generationId = const Value.absent(),
            Value<String> nameZhHans = const Value.absent(),
            Value<String> nameZhHant = const Value.absent(),
            Value<String> nameEn = const Value.absent(),
            Value<String> nameJa = const Value.absent(),
            Value<String> nameJaHrkt = const Value.absent(),
            Value<String?> nameRoomaji = const Value.absent(),
            Value<String?> genusZhHans = const Value.absent(),
            Value<String?> genusEn = const Value.absent(),
            Value<bool> isLegendary = const Value.absent(),
            Value<bool> isMythical = const Value.absent(),
            Value<bool> isUltraBeast = const Value.absent(),
            Value<bool> isBaby = const Value.absent(),
            Value<int?> evolutionChainId = const Value.absent(),
            Value<int?> captureRate = const Value.absent(),
            Value<int?> baseHappiness = const Value.absent(),
            Value<int?> genderRate = const Value.absent(),
            Value<int?> hatchCounter = const Value.absent(),
            Value<String?> growthRate = const Value.absent(),
            Value<String?> eggGroup1 = const Value.absent(),
            Value<String?> eggGroup2 = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<String?> shape = const Value.absent(),
            Value<String?> habitat = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SpeciesCompanion(
            id: id,
            nationalDex: nationalDex,
            generationId: generationId,
            nameZhHans: nameZhHans,
            nameZhHant: nameZhHant,
            nameEn: nameEn,
            nameJa: nameJa,
            nameJaHrkt: nameJaHrkt,
            nameRoomaji: nameRoomaji,
            genusZhHans: genusZhHans,
            genusEn: genusEn,
            isLegendary: isLegendary,
            isMythical: isMythical,
            isUltraBeast: isUltraBeast,
            isBaby: isBaby,
            evolutionChainId: evolutionChainId,
            captureRate: captureRate,
            baseHappiness: baseHappiness,
            genderRate: genderRate,
            hatchCounter: hatchCounter,
            growthRate: growthRate,
            eggGroup1: eggGroup1,
            eggGroup2: eggGroup2,
            color: color,
            shape: shape,
            habitat: habitat,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int id,
            required int nationalDex,
            required int generationId,
            required String nameZhHans,
            required String nameZhHant,
            required String nameEn,
            required String nameJa,
            required String nameJaHrkt,
            Value<String?> nameRoomaji = const Value.absent(),
            Value<String?> genusZhHans = const Value.absent(),
            Value<String?> genusEn = const Value.absent(),
            required bool isLegendary,
            required bool isMythical,
            required bool isUltraBeast,
            required bool isBaby,
            Value<int?> evolutionChainId = const Value.absent(),
            Value<int?> captureRate = const Value.absent(),
            Value<int?> baseHappiness = const Value.absent(),
            Value<int?> genderRate = const Value.absent(),
            Value<int?> hatchCounter = const Value.absent(),
            Value<String?> growthRate = const Value.absent(),
            Value<String?> eggGroup1 = const Value.absent(),
            Value<String?> eggGroup2 = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<String?> shape = const Value.absent(),
            Value<String?> habitat = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SpeciesCompanion.insert(
            id: id,
            nationalDex: nationalDex,
            generationId: generationId,
            nameZhHans: nameZhHans,
            nameZhHant: nameZhHant,
            nameEn: nameEn,
            nameJa: nameJa,
            nameJaHrkt: nameJaHrkt,
            nameRoomaji: nameRoomaji,
            genusZhHans: genusZhHans,
            genusEn: genusEn,
            isLegendary: isLegendary,
            isMythical: isMythical,
            isUltraBeast: isUltraBeast,
            isBaby: isBaby,
            evolutionChainId: evolutionChainId,
            captureRate: captureRate,
            baseHappiness: baseHappiness,
            genderRate: genderRate,
            hatchCounter: hatchCounter,
            growthRate: growthRate,
            eggGroup1: eggGroup1,
            eggGroup2: eggGroup2,
            color: color,
            shape: shape,
            habitat: habitat,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SpeciesTableProcessedTableManager = ProcessedTableManager<
    _$PokedexDatabase,
    $SpeciesTable,
    SpeciesRow,
    $$SpeciesTableFilterComposer,
    $$SpeciesTableOrderingComposer,
    $$SpeciesTableAnnotationComposer,
    $$SpeciesTableCreateCompanionBuilder,
    $$SpeciesTableUpdateCompanionBuilder,
    (SpeciesRow, BaseReferences<_$PokedexDatabase, $SpeciesTable, SpeciesRow>),
    SpeciesRow,
    PrefetchHooks Function()>;
typedef $$FormsTableCreateCompanionBuilder = FormsCompanion Function({
  required int id,
  required int speciesId,
  Value<String?> formIdentifier,
  required String formNameZh,
  required String formNameEn,
  required bool isDefault,
  required bool isMega,
  required bool isGmax,
  required bool isRegional,
  required bool isBattleOnly,
  required int formOrder,
  Value<int?> height,
  Value<int?> weight,
  Value<int?> baseExperience,
  required bool hasGenderDifference,
  Value<String?> artworkAsset,
  Value<String?> thumbAsset,
  Value<int> rowid,
});
typedef $$FormsTableUpdateCompanionBuilder = FormsCompanion Function({
  Value<int> id,
  Value<int> speciesId,
  Value<String?> formIdentifier,
  Value<String> formNameZh,
  Value<String> formNameEn,
  Value<bool> isDefault,
  Value<bool> isMega,
  Value<bool> isGmax,
  Value<bool> isRegional,
  Value<bool> isBattleOnly,
  Value<int> formOrder,
  Value<int?> height,
  Value<int?> weight,
  Value<int?> baseExperience,
  Value<bool> hasGenderDifference,
  Value<String?> artworkAsset,
  Value<String?> thumbAsset,
  Value<int> rowid,
});

class $$FormsTableFilterComposer
    extends Composer<_$PokedexDatabase, $FormsTable> {
  $$FormsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get speciesId => $composableBuilder(
      column: $table.speciesId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get formIdentifier => $composableBuilder(
      column: $table.formIdentifier,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get formNameZh => $composableBuilder(
      column: $table.formNameZh, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get formNameEn => $composableBuilder(
      column: $table.formNameEn, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isMega => $composableBuilder(
      column: $table.isMega, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isGmax => $composableBuilder(
      column: $table.isGmax, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRegional => $composableBuilder(
      column: $table.isRegional, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isBattleOnly => $composableBuilder(
      column: $table.isBattleOnly, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get formOrder => $composableBuilder(
      column: $table.formOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get baseExperience => $composableBuilder(
      column: $table.baseExperience,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hasGenderDifference => $composableBuilder(
      column: $table.hasGenderDifference,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artworkAsset => $composableBuilder(
      column: $table.artworkAsset, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbAsset => $composableBuilder(
      column: $table.thumbAsset, builder: (column) => ColumnFilters(column));
}

class $$FormsTableOrderingComposer
    extends Composer<_$PokedexDatabase, $FormsTable> {
  $$FormsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get speciesId => $composableBuilder(
      column: $table.speciesId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get formIdentifier => $composableBuilder(
      column: $table.formIdentifier,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get formNameZh => $composableBuilder(
      column: $table.formNameZh, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get formNameEn => $composableBuilder(
      column: $table.formNameEn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isMega => $composableBuilder(
      column: $table.isMega, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isGmax => $composableBuilder(
      column: $table.isGmax, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRegional => $composableBuilder(
      column: $table.isRegional, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isBattleOnly => $composableBuilder(
      column: $table.isBattleOnly,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get formOrder => $composableBuilder(
      column: $table.formOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get baseExperience => $composableBuilder(
      column: $table.baseExperience,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hasGenderDifference => $composableBuilder(
      column: $table.hasGenderDifference,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artworkAsset => $composableBuilder(
      column: $table.artworkAsset,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbAsset => $composableBuilder(
      column: $table.thumbAsset, builder: (column) => ColumnOrderings(column));
}

class $$FormsTableAnnotationComposer
    extends Composer<_$PokedexDatabase, $FormsTable> {
  $$FormsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get speciesId =>
      $composableBuilder(column: $table.speciesId, builder: (column) => column);

  GeneratedColumn<String> get formIdentifier => $composableBuilder(
      column: $table.formIdentifier, builder: (column) => column);

  GeneratedColumn<String> get formNameZh => $composableBuilder(
      column: $table.formNameZh, builder: (column) => column);

  GeneratedColumn<String> get formNameEn => $composableBuilder(
      column: $table.formNameEn, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<bool> get isMega =>
      $composableBuilder(column: $table.isMega, builder: (column) => column);

  GeneratedColumn<bool> get isGmax =>
      $composableBuilder(column: $table.isGmax, builder: (column) => column);

  GeneratedColumn<bool> get isRegional => $composableBuilder(
      column: $table.isRegional, builder: (column) => column);

  GeneratedColumn<bool> get isBattleOnly => $composableBuilder(
      column: $table.isBattleOnly, builder: (column) => column);

  GeneratedColumn<int> get formOrder =>
      $composableBuilder(column: $table.formOrder, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<int> get baseExperience => $composableBuilder(
      column: $table.baseExperience, builder: (column) => column);

  GeneratedColumn<bool> get hasGenderDifference => $composableBuilder(
      column: $table.hasGenderDifference, builder: (column) => column);

  GeneratedColumn<String> get artworkAsset => $composableBuilder(
      column: $table.artworkAsset, builder: (column) => column);

  GeneratedColumn<String> get thumbAsset => $composableBuilder(
      column: $table.thumbAsset, builder: (column) => column);
}

class $$FormsTableTableManager extends RootTableManager<
    _$PokedexDatabase,
    $FormsTable,
    FormsRow,
    $$FormsTableFilterComposer,
    $$FormsTableOrderingComposer,
    $$FormsTableAnnotationComposer,
    $$FormsTableCreateCompanionBuilder,
    $$FormsTableUpdateCompanionBuilder,
    (FormsRow, BaseReferences<_$PokedexDatabase, $FormsTable, FormsRow>),
    FormsRow,
    PrefetchHooks Function()> {
  $$FormsTableTableManager(_$PokedexDatabase db, $FormsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FormsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FormsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FormsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> speciesId = const Value.absent(),
            Value<String?> formIdentifier = const Value.absent(),
            Value<String> formNameZh = const Value.absent(),
            Value<String> formNameEn = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<bool> isMega = const Value.absent(),
            Value<bool> isGmax = const Value.absent(),
            Value<bool> isRegional = const Value.absent(),
            Value<bool> isBattleOnly = const Value.absent(),
            Value<int> formOrder = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<int?> weight = const Value.absent(),
            Value<int?> baseExperience = const Value.absent(),
            Value<bool> hasGenderDifference = const Value.absent(),
            Value<String?> artworkAsset = const Value.absent(),
            Value<String?> thumbAsset = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FormsCompanion(
            id: id,
            speciesId: speciesId,
            formIdentifier: formIdentifier,
            formNameZh: formNameZh,
            formNameEn: formNameEn,
            isDefault: isDefault,
            isMega: isMega,
            isGmax: isGmax,
            isRegional: isRegional,
            isBattleOnly: isBattleOnly,
            formOrder: formOrder,
            height: height,
            weight: weight,
            baseExperience: baseExperience,
            hasGenderDifference: hasGenderDifference,
            artworkAsset: artworkAsset,
            thumbAsset: thumbAsset,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int id,
            required int speciesId,
            Value<String?> formIdentifier = const Value.absent(),
            required String formNameZh,
            required String formNameEn,
            required bool isDefault,
            required bool isMega,
            required bool isGmax,
            required bool isRegional,
            required bool isBattleOnly,
            required int formOrder,
            Value<int?> height = const Value.absent(),
            Value<int?> weight = const Value.absent(),
            Value<int?> baseExperience = const Value.absent(),
            required bool hasGenderDifference,
            Value<String?> artworkAsset = const Value.absent(),
            Value<String?> thumbAsset = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FormsCompanion.insert(
            id: id,
            speciesId: speciesId,
            formIdentifier: formIdentifier,
            formNameZh: formNameZh,
            formNameEn: formNameEn,
            isDefault: isDefault,
            isMega: isMega,
            isGmax: isGmax,
            isRegional: isRegional,
            isBattleOnly: isBattleOnly,
            formOrder: formOrder,
            height: height,
            weight: weight,
            baseExperience: baseExperience,
            hasGenderDifference: hasGenderDifference,
            artworkAsset: artworkAsset,
            thumbAsset: thumbAsset,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FormsTableProcessedTableManager = ProcessedTableManager<
    _$PokedexDatabase,
    $FormsTable,
    FormsRow,
    $$FormsTableFilterComposer,
    $$FormsTableOrderingComposer,
    $$FormsTableAnnotationComposer,
    $$FormsTableCreateCompanionBuilder,
    $$FormsTableUpdateCompanionBuilder,
    (FormsRow, BaseReferences<_$PokedexDatabase, $FormsTable, FormsRow>),
    FormsRow,
    PrefetchHooks Function()>;
typedef $$FormTypesTableCreateCompanionBuilder = FormTypesCompanion Function({
  required int formId,
  required int slot,
  required int typeId,
  Value<int> rowid,
});
typedef $$FormTypesTableUpdateCompanionBuilder = FormTypesCompanion Function({
  Value<int> formId,
  Value<int> slot,
  Value<int> typeId,
  Value<int> rowid,
});

class $$FormTypesTableFilterComposer
    extends Composer<_$PokedexDatabase, $FormTypesTable> {
  $$FormTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get formId => $composableBuilder(
      column: $table.formId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get slot => $composableBuilder(
      column: $table.slot, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get typeId => $composableBuilder(
      column: $table.typeId, builder: (column) => ColumnFilters(column));
}

class $$FormTypesTableOrderingComposer
    extends Composer<_$PokedexDatabase, $FormTypesTable> {
  $$FormTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get formId => $composableBuilder(
      column: $table.formId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get slot => $composableBuilder(
      column: $table.slot, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get typeId => $composableBuilder(
      column: $table.typeId, builder: (column) => ColumnOrderings(column));
}

class $$FormTypesTableAnnotationComposer
    extends Composer<_$PokedexDatabase, $FormTypesTable> {
  $$FormTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get formId =>
      $composableBuilder(column: $table.formId, builder: (column) => column);

  GeneratedColumn<int> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<int> get typeId =>
      $composableBuilder(column: $table.typeId, builder: (column) => column);
}

class $$FormTypesTableTableManager extends RootTableManager<
    _$PokedexDatabase,
    $FormTypesTable,
    FormTypesRow,
    $$FormTypesTableFilterComposer,
    $$FormTypesTableOrderingComposer,
    $$FormTypesTableAnnotationComposer,
    $$FormTypesTableCreateCompanionBuilder,
    $$FormTypesTableUpdateCompanionBuilder,
    (
      FormTypesRow,
      BaseReferences<_$PokedexDatabase, $FormTypesTable, FormTypesRow>
    ),
    FormTypesRow,
    PrefetchHooks Function()> {
  $$FormTypesTableTableManager(_$PokedexDatabase db, $FormTypesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FormTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FormTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FormTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> formId = const Value.absent(),
            Value<int> slot = const Value.absent(),
            Value<int> typeId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FormTypesCompanion(
            formId: formId,
            slot: slot,
            typeId: typeId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int formId,
            required int slot,
            required int typeId,
            Value<int> rowid = const Value.absent(),
          }) =>
              FormTypesCompanion.insert(
            formId: formId,
            slot: slot,
            typeId: typeId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FormTypesTableProcessedTableManager = ProcessedTableManager<
    _$PokedexDatabase,
    $FormTypesTable,
    FormTypesRow,
    $$FormTypesTableFilterComposer,
    $$FormTypesTableOrderingComposer,
    $$FormTypesTableAnnotationComposer,
    $$FormTypesTableCreateCompanionBuilder,
    $$FormTypesTableUpdateCompanionBuilder,
    (
      FormTypesRow,
      BaseReferences<_$PokedexDatabase, $FormTypesTable, FormTypesRow>
    ),
    FormTypesRow,
    PrefetchHooks Function()>;
typedef $$FormStatsTableCreateCompanionBuilder = FormStatsCompanion Function({
  required int formId,
  required String stat,
  required int baseValue,
  Value<int> rowid,
});
typedef $$FormStatsTableUpdateCompanionBuilder = FormStatsCompanion Function({
  Value<int> formId,
  Value<String> stat,
  Value<int> baseValue,
  Value<int> rowid,
});

class $$FormStatsTableFilterComposer
    extends Composer<_$PokedexDatabase, $FormStatsTable> {
  $$FormStatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get formId => $composableBuilder(
      column: $table.formId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stat => $composableBuilder(
      column: $table.stat, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get baseValue => $composableBuilder(
      column: $table.baseValue, builder: (column) => ColumnFilters(column));
}

class $$FormStatsTableOrderingComposer
    extends Composer<_$PokedexDatabase, $FormStatsTable> {
  $$FormStatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get formId => $composableBuilder(
      column: $table.formId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stat => $composableBuilder(
      column: $table.stat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get baseValue => $composableBuilder(
      column: $table.baseValue, builder: (column) => ColumnOrderings(column));
}

class $$FormStatsTableAnnotationComposer
    extends Composer<_$PokedexDatabase, $FormStatsTable> {
  $$FormStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get formId =>
      $composableBuilder(column: $table.formId, builder: (column) => column);

  GeneratedColumn<String> get stat =>
      $composableBuilder(column: $table.stat, builder: (column) => column);

  GeneratedColumn<int> get baseValue =>
      $composableBuilder(column: $table.baseValue, builder: (column) => column);
}

class $$FormStatsTableTableManager extends RootTableManager<
    _$PokedexDatabase,
    $FormStatsTable,
    FormStatsRow,
    $$FormStatsTableFilterComposer,
    $$FormStatsTableOrderingComposer,
    $$FormStatsTableAnnotationComposer,
    $$FormStatsTableCreateCompanionBuilder,
    $$FormStatsTableUpdateCompanionBuilder,
    (
      FormStatsRow,
      BaseReferences<_$PokedexDatabase, $FormStatsTable, FormStatsRow>
    ),
    FormStatsRow,
    PrefetchHooks Function()> {
  $$FormStatsTableTableManager(_$PokedexDatabase db, $FormStatsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FormStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FormStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FormStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> formId = const Value.absent(),
            Value<String> stat = const Value.absent(),
            Value<int> baseValue = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FormStatsCompanion(
            formId: formId,
            stat: stat,
            baseValue: baseValue,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int formId,
            required String stat,
            required int baseValue,
            Value<int> rowid = const Value.absent(),
          }) =>
              FormStatsCompanion.insert(
            formId: formId,
            stat: stat,
            baseValue: baseValue,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FormStatsTableProcessedTableManager = ProcessedTableManager<
    _$PokedexDatabase,
    $FormStatsTable,
    FormStatsRow,
    $$FormStatsTableFilterComposer,
    $$FormStatsTableOrderingComposer,
    $$FormStatsTableAnnotationComposer,
    $$FormStatsTableCreateCompanionBuilder,
    $$FormStatsTableUpdateCompanionBuilder,
    (
      FormStatsRow,
      BaseReferences<_$PokedexDatabase, $FormStatsTable, FormStatsRow>
    ),
    FormStatsRow,
    PrefetchHooks Function()>;
typedef $$FormAbilitiesTableCreateCompanionBuilder = FormAbilitiesCompanion
    Function({
  required int formId,
  required int slot,
  required int abilityId,
  required bool isHidden,
  Value<int> rowid,
});
typedef $$FormAbilitiesTableUpdateCompanionBuilder = FormAbilitiesCompanion
    Function({
  Value<int> formId,
  Value<int> slot,
  Value<int> abilityId,
  Value<bool> isHidden,
  Value<int> rowid,
});

class $$FormAbilitiesTableFilterComposer
    extends Composer<_$PokedexDatabase, $FormAbilitiesTable> {
  $$FormAbilitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get formId => $composableBuilder(
      column: $table.formId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get slot => $composableBuilder(
      column: $table.slot, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get abilityId => $composableBuilder(
      column: $table.abilityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isHidden => $composableBuilder(
      column: $table.isHidden, builder: (column) => ColumnFilters(column));
}

class $$FormAbilitiesTableOrderingComposer
    extends Composer<_$PokedexDatabase, $FormAbilitiesTable> {
  $$FormAbilitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get formId => $composableBuilder(
      column: $table.formId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get slot => $composableBuilder(
      column: $table.slot, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get abilityId => $composableBuilder(
      column: $table.abilityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isHidden => $composableBuilder(
      column: $table.isHidden, builder: (column) => ColumnOrderings(column));
}

class $$FormAbilitiesTableAnnotationComposer
    extends Composer<_$PokedexDatabase, $FormAbilitiesTable> {
  $$FormAbilitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get formId =>
      $composableBuilder(column: $table.formId, builder: (column) => column);

  GeneratedColumn<int> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<int> get abilityId =>
      $composableBuilder(column: $table.abilityId, builder: (column) => column);

  GeneratedColumn<bool> get isHidden =>
      $composableBuilder(column: $table.isHidden, builder: (column) => column);
}

class $$FormAbilitiesTableTableManager extends RootTableManager<
    _$PokedexDatabase,
    $FormAbilitiesTable,
    FormAbilitiesRow,
    $$FormAbilitiesTableFilterComposer,
    $$FormAbilitiesTableOrderingComposer,
    $$FormAbilitiesTableAnnotationComposer,
    $$FormAbilitiesTableCreateCompanionBuilder,
    $$FormAbilitiesTableUpdateCompanionBuilder,
    (
      FormAbilitiesRow,
      BaseReferences<_$PokedexDatabase, $FormAbilitiesTable, FormAbilitiesRow>
    ),
    FormAbilitiesRow,
    PrefetchHooks Function()> {
  $$FormAbilitiesTableTableManager(
      _$PokedexDatabase db, $FormAbilitiesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FormAbilitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FormAbilitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FormAbilitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> formId = const Value.absent(),
            Value<int> slot = const Value.absent(),
            Value<int> abilityId = const Value.absent(),
            Value<bool> isHidden = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FormAbilitiesCompanion(
            formId: formId,
            slot: slot,
            abilityId: abilityId,
            isHidden: isHidden,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int formId,
            required int slot,
            required int abilityId,
            required bool isHidden,
            Value<int> rowid = const Value.absent(),
          }) =>
              FormAbilitiesCompanion.insert(
            formId: formId,
            slot: slot,
            abilityId: abilityId,
            isHidden: isHidden,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FormAbilitiesTableProcessedTableManager = ProcessedTableManager<
    _$PokedexDatabase,
    $FormAbilitiesTable,
    FormAbilitiesRow,
    $$FormAbilitiesTableFilterComposer,
    $$FormAbilitiesTableOrderingComposer,
    $$FormAbilitiesTableAnnotationComposer,
    $$FormAbilitiesTableCreateCompanionBuilder,
    $$FormAbilitiesTableUpdateCompanionBuilder,
    (
      FormAbilitiesRow,
      BaseReferences<_$PokedexDatabase, $FormAbilitiesTable, FormAbilitiesRow>
    ),
    FormAbilitiesRow,
    PrefetchHooks Function()>;
typedef $$PokemonFormMovesTableCreateCompanionBuilder
    = PokemonFormMovesCompanion Function({
  required int formId,
  required int moveId,
  required String method,
  Value<int?> level,
  required String versionGroup,
  Value<int> rowid,
});
typedef $$PokemonFormMovesTableUpdateCompanionBuilder
    = PokemonFormMovesCompanion Function({
  Value<int> formId,
  Value<int> moveId,
  Value<String> method,
  Value<int?> level,
  Value<String> versionGroup,
  Value<int> rowid,
});

class $$PokemonFormMovesTableFilterComposer
    extends Composer<_$PokedexDatabase, $PokemonFormMovesTable> {
  $$PokemonFormMovesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get formId => $composableBuilder(
      column: $table.formId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get moveId => $composableBuilder(
      column: $table.moveId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get versionGroup => $composableBuilder(
      column: $table.versionGroup, builder: (column) => ColumnFilters(column));
}

class $$PokemonFormMovesTableOrderingComposer
    extends Composer<_$PokedexDatabase, $PokemonFormMovesTable> {
  $$PokemonFormMovesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get formId => $composableBuilder(
      column: $table.formId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get moveId => $composableBuilder(
      column: $table.moveId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get versionGroup => $composableBuilder(
      column: $table.versionGroup,
      builder: (column) => ColumnOrderings(column));
}

class $$PokemonFormMovesTableAnnotationComposer
    extends Composer<_$PokedexDatabase, $PokemonFormMovesTable> {
  $$PokemonFormMovesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get formId =>
      $composableBuilder(column: $table.formId, builder: (column) => column);

  GeneratedColumn<int> get moveId =>
      $composableBuilder(column: $table.moveId, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get versionGroup => $composableBuilder(
      column: $table.versionGroup, builder: (column) => column);
}

class $$PokemonFormMovesTableTableManager extends RootTableManager<
    _$PokedexDatabase,
    $PokemonFormMovesTable,
    PokemonFormMovesRow,
    $$PokemonFormMovesTableFilterComposer,
    $$PokemonFormMovesTableOrderingComposer,
    $$PokemonFormMovesTableAnnotationComposer,
    $$PokemonFormMovesTableCreateCompanionBuilder,
    $$PokemonFormMovesTableUpdateCompanionBuilder,
    (
      PokemonFormMovesRow,
      BaseReferences<_$PokedexDatabase, $PokemonFormMovesTable,
          PokemonFormMovesRow>
    ),
    PokemonFormMovesRow,
    PrefetchHooks Function()> {
  $$PokemonFormMovesTableTableManager(
      _$PokedexDatabase db, $PokemonFormMovesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PokemonFormMovesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PokemonFormMovesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PokemonFormMovesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> formId = const Value.absent(),
            Value<int> moveId = const Value.absent(),
            Value<String> method = const Value.absent(),
            Value<int?> level = const Value.absent(),
            Value<String> versionGroup = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PokemonFormMovesCompanion(
            formId: formId,
            moveId: moveId,
            method: method,
            level: level,
            versionGroup: versionGroup,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int formId,
            required int moveId,
            required String method,
            Value<int?> level = const Value.absent(),
            required String versionGroup,
            Value<int> rowid = const Value.absent(),
          }) =>
              PokemonFormMovesCompanion.insert(
            formId: formId,
            moveId: moveId,
            method: method,
            level: level,
            versionGroup: versionGroup,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PokemonFormMovesTableProcessedTableManager = ProcessedTableManager<
    _$PokedexDatabase,
    $PokemonFormMovesTable,
    PokemonFormMovesRow,
    $$PokemonFormMovesTableFilterComposer,
    $$PokemonFormMovesTableOrderingComposer,
    $$PokemonFormMovesTableAnnotationComposer,
    $$PokemonFormMovesTableCreateCompanionBuilder,
    $$PokemonFormMovesTableUpdateCompanionBuilder,
    (
      PokemonFormMovesRow,
      BaseReferences<_$PokedexDatabase, $PokemonFormMovesTable,
          PokemonFormMovesRow>
    ),
    PokemonFormMovesRow,
    PrefetchHooks Function()>;
typedef $$EvolutionChainsTableCreateCompanionBuilder = EvolutionChainsCompanion
    Function({
  required int id,
  required int rootSpeciesId,
  Value<int> rowid,
});
typedef $$EvolutionChainsTableUpdateCompanionBuilder = EvolutionChainsCompanion
    Function({
  Value<int> id,
  Value<int> rootSpeciesId,
  Value<int> rowid,
});

class $$EvolutionChainsTableFilterComposer
    extends Composer<_$PokedexDatabase, $EvolutionChainsTable> {
  $$EvolutionChainsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rootSpeciesId => $composableBuilder(
      column: $table.rootSpeciesId, builder: (column) => ColumnFilters(column));
}

class $$EvolutionChainsTableOrderingComposer
    extends Composer<_$PokedexDatabase, $EvolutionChainsTable> {
  $$EvolutionChainsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rootSpeciesId => $composableBuilder(
      column: $table.rootSpeciesId,
      builder: (column) => ColumnOrderings(column));
}

class $$EvolutionChainsTableAnnotationComposer
    extends Composer<_$PokedexDatabase, $EvolutionChainsTable> {
  $$EvolutionChainsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get rootSpeciesId => $composableBuilder(
      column: $table.rootSpeciesId, builder: (column) => column);
}

class $$EvolutionChainsTableTableManager extends RootTableManager<
    _$PokedexDatabase,
    $EvolutionChainsTable,
    EvolutionChainsRow,
    $$EvolutionChainsTableFilterComposer,
    $$EvolutionChainsTableOrderingComposer,
    $$EvolutionChainsTableAnnotationComposer,
    $$EvolutionChainsTableCreateCompanionBuilder,
    $$EvolutionChainsTableUpdateCompanionBuilder,
    (
      EvolutionChainsRow,
      BaseReferences<_$PokedexDatabase, $EvolutionChainsTable,
          EvolutionChainsRow>
    ),
    EvolutionChainsRow,
    PrefetchHooks Function()> {
  $$EvolutionChainsTableTableManager(
      _$PokedexDatabase db, $EvolutionChainsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EvolutionChainsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EvolutionChainsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EvolutionChainsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> rootSpeciesId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EvolutionChainsCompanion(
            id: id,
            rootSpeciesId: rootSpeciesId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int id,
            required int rootSpeciesId,
            Value<int> rowid = const Value.absent(),
          }) =>
              EvolutionChainsCompanion.insert(
            id: id,
            rootSpeciesId: rootSpeciesId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EvolutionChainsTableProcessedTableManager = ProcessedTableManager<
    _$PokedexDatabase,
    $EvolutionChainsTable,
    EvolutionChainsRow,
    $$EvolutionChainsTableFilterComposer,
    $$EvolutionChainsTableOrderingComposer,
    $$EvolutionChainsTableAnnotationComposer,
    $$EvolutionChainsTableCreateCompanionBuilder,
    $$EvolutionChainsTableUpdateCompanionBuilder,
    (
      EvolutionChainsRow,
      BaseReferences<_$PokedexDatabase, $EvolutionChainsTable,
          EvolutionChainsRow>
    ),
    EvolutionChainsRow,
    PrefetchHooks Function()>;
typedef $$EvolutionEdgesTableCreateCompanionBuilder = EvolutionEdgesCompanion
    Function({
  required int chainId,
  Value<int?> fromSpeciesId,
  required int toSpeciesId,
  required String trigger,
  Value<int?> minLevel,
  Value<String?> item,
  Value<String?> heldItem,
  Value<String?> knownMove,
  Value<String?> knownMoveType,
  Value<String?> location,
  Value<String?> timeOfDay,
  Value<String?> gender,
  Value<int?> minHappiness,
  Value<int?> minAffection,
  Value<int?> minBeauty,
  Value<String?> relativePhysicalStats,
  Value<String?> partySpecies,
  Value<String?> partyType,
  Value<String?> tradeSpecies,
  required bool needsOverworldRain,
  required bool turnUpsideDown,
  Value<int> rowid,
});
typedef $$EvolutionEdgesTableUpdateCompanionBuilder = EvolutionEdgesCompanion
    Function({
  Value<int> chainId,
  Value<int?> fromSpeciesId,
  Value<int> toSpeciesId,
  Value<String> trigger,
  Value<int?> minLevel,
  Value<String?> item,
  Value<String?> heldItem,
  Value<String?> knownMove,
  Value<String?> knownMoveType,
  Value<String?> location,
  Value<String?> timeOfDay,
  Value<String?> gender,
  Value<int?> minHappiness,
  Value<int?> minAffection,
  Value<int?> minBeauty,
  Value<String?> relativePhysicalStats,
  Value<String?> partySpecies,
  Value<String?> partyType,
  Value<String?> tradeSpecies,
  Value<bool> needsOverworldRain,
  Value<bool> turnUpsideDown,
  Value<int> rowid,
});

class $$EvolutionEdgesTableFilterComposer
    extends Composer<_$PokedexDatabase, $EvolutionEdgesTable> {
  $$EvolutionEdgesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get chainId => $composableBuilder(
      column: $table.chainId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fromSpeciesId => $composableBuilder(
      column: $table.fromSpeciesId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get toSpeciesId => $composableBuilder(
      column: $table.toSpeciesId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trigger => $composableBuilder(
      column: $table.trigger, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minLevel => $composableBuilder(
      column: $table.minLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get item => $composableBuilder(
      column: $table.item, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get heldItem => $composableBuilder(
      column: $table.heldItem, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get knownMove => $composableBuilder(
      column: $table.knownMove, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get knownMoveType => $composableBuilder(
      column: $table.knownMoveType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get timeOfDay => $composableBuilder(
      column: $table.timeOfDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minHappiness => $composableBuilder(
      column: $table.minHappiness, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minAffection => $composableBuilder(
      column: $table.minAffection, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minBeauty => $composableBuilder(
      column: $table.minBeauty, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get relativePhysicalStats => $composableBuilder(
      column: $table.relativePhysicalStats,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get partySpecies => $composableBuilder(
      column: $table.partySpecies, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get partyType => $composableBuilder(
      column: $table.partyType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tradeSpecies => $composableBuilder(
      column: $table.tradeSpecies, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get needsOverworldRain => $composableBuilder(
      column: $table.needsOverworldRain,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get turnUpsideDown => $composableBuilder(
      column: $table.turnUpsideDown,
      builder: (column) => ColumnFilters(column));
}

class $$EvolutionEdgesTableOrderingComposer
    extends Composer<_$PokedexDatabase, $EvolutionEdgesTable> {
  $$EvolutionEdgesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get chainId => $composableBuilder(
      column: $table.chainId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fromSpeciesId => $composableBuilder(
      column: $table.fromSpeciesId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get toSpeciesId => $composableBuilder(
      column: $table.toSpeciesId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trigger => $composableBuilder(
      column: $table.trigger, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minLevel => $composableBuilder(
      column: $table.minLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get item => $composableBuilder(
      column: $table.item, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get heldItem => $composableBuilder(
      column: $table.heldItem, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get knownMove => $composableBuilder(
      column: $table.knownMove, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get knownMoveType => $composableBuilder(
      column: $table.knownMoveType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get timeOfDay => $composableBuilder(
      column: $table.timeOfDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minHappiness => $composableBuilder(
      column: $table.minHappiness,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minAffection => $composableBuilder(
      column: $table.minAffection,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minBeauty => $composableBuilder(
      column: $table.minBeauty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relativePhysicalStats => $composableBuilder(
      column: $table.relativePhysicalStats,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get partySpecies => $composableBuilder(
      column: $table.partySpecies,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get partyType => $composableBuilder(
      column: $table.partyType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tradeSpecies => $composableBuilder(
      column: $table.tradeSpecies,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get needsOverworldRain => $composableBuilder(
      column: $table.needsOverworldRain,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get turnUpsideDown => $composableBuilder(
      column: $table.turnUpsideDown,
      builder: (column) => ColumnOrderings(column));
}

class $$EvolutionEdgesTableAnnotationComposer
    extends Composer<_$PokedexDatabase, $EvolutionEdgesTable> {
  $$EvolutionEdgesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get chainId =>
      $composableBuilder(column: $table.chainId, builder: (column) => column);

  GeneratedColumn<int> get fromSpeciesId => $composableBuilder(
      column: $table.fromSpeciesId, builder: (column) => column);

  GeneratedColumn<int> get toSpeciesId => $composableBuilder(
      column: $table.toSpeciesId, builder: (column) => column);

  GeneratedColumn<String> get trigger =>
      $composableBuilder(column: $table.trigger, builder: (column) => column);

  GeneratedColumn<int> get minLevel =>
      $composableBuilder(column: $table.minLevel, builder: (column) => column);

  GeneratedColumn<String> get item =>
      $composableBuilder(column: $table.item, builder: (column) => column);

  GeneratedColumn<String> get heldItem =>
      $composableBuilder(column: $table.heldItem, builder: (column) => column);

  GeneratedColumn<String> get knownMove =>
      $composableBuilder(column: $table.knownMove, builder: (column) => column);

  GeneratedColumn<String> get knownMoveType => $composableBuilder(
      column: $table.knownMoveType, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get timeOfDay =>
      $composableBuilder(column: $table.timeOfDay, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<int> get minHappiness => $composableBuilder(
      column: $table.minHappiness, builder: (column) => column);

  GeneratedColumn<int> get minAffection => $composableBuilder(
      column: $table.minAffection, builder: (column) => column);

  GeneratedColumn<int> get minBeauty =>
      $composableBuilder(column: $table.minBeauty, builder: (column) => column);

  GeneratedColumn<String> get relativePhysicalStats => $composableBuilder(
      column: $table.relativePhysicalStats, builder: (column) => column);

  GeneratedColumn<String> get partySpecies => $composableBuilder(
      column: $table.partySpecies, builder: (column) => column);

  GeneratedColumn<String> get partyType =>
      $composableBuilder(column: $table.partyType, builder: (column) => column);

  GeneratedColumn<String> get tradeSpecies => $composableBuilder(
      column: $table.tradeSpecies, builder: (column) => column);

  GeneratedColumn<bool> get needsOverworldRain => $composableBuilder(
      column: $table.needsOverworldRain, builder: (column) => column);

  GeneratedColumn<bool> get turnUpsideDown => $composableBuilder(
      column: $table.turnUpsideDown, builder: (column) => column);
}

class $$EvolutionEdgesTableTableManager extends RootTableManager<
    _$PokedexDatabase,
    $EvolutionEdgesTable,
    EvolutionEdgesRow,
    $$EvolutionEdgesTableFilterComposer,
    $$EvolutionEdgesTableOrderingComposer,
    $$EvolutionEdgesTableAnnotationComposer,
    $$EvolutionEdgesTableCreateCompanionBuilder,
    $$EvolutionEdgesTableUpdateCompanionBuilder,
    (
      EvolutionEdgesRow,
      BaseReferences<_$PokedexDatabase, $EvolutionEdgesTable, EvolutionEdgesRow>
    ),
    EvolutionEdgesRow,
    PrefetchHooks Function()> {
  $$EvolutionEdgesTableTableManager(
      _$PokedexDatabase db, $EvolutionEdgesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EvolutionEdgesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EvolutionEdgesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EvolutionEdgesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> chainId = const Value.absent(),
            Value<int?> fromSpeciesId = const Value.absent(),
            Value<int> toSpeciesId = const Value.absent(),
            Value<String> trigger = const Value.absent(),
            Value<int?> minLevel = const Value.absent(),
            Value<String?> item = const Value.absent(),
            Value<String?> heldItem = const Value.absent(),
            Value<String?> knownMove = const Value.absent(),
            Value<String?> knownMoveType = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<String?> timeOfDay = const Value.absent(),
            Value<String?> gender = const Value.absent(),
            Value<int?> minHappiness = const Value.absent(),
            Value<int?> minAffection = const Value.absent(),
            Value<int?> minBeauty = const Value.absent(),
            Value<String?> relativePhysicalStats = const Value.absent(),
            Value<String?> partySpecies = const Value.absent(),
            Value<String?> partyType = const Value.absent(),
            Value<String?> tradeSpecies = const Value.absent(),
            Value<bool> needsOverworldRain = const Value.absent(),
            Value<bool> turnUpsideDown = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EvolutionEdgesCompanion(
            chainId: chainId,
            fromSpeciesId: fromSpeciesId,
            toSpeciesId: toSpeciesId,
            trigger: trigger,
            minLevel: minLevel,
            item: item,
            heldItem: heldItem,
            knownMove: knownMove,
            knownMoveType: knownMoveType,
            location: location,
            timeOfDay: timeOfDay,
            gender: gender,
            minHappiness: minHappiness,
            minAffection: minAffection,
            minBeauty: minBeauty,
            relativePhysicalStats: relativePhysicalStats,
            partySpecies: partySpecies,
            partyType: partyType,
            tradeSpecies: tradeSpecies,
            needsOverworldRain: needsOverworldRain,
            turnUpsideDown: turnUpsideDown,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int chainId,
            Value<int?> fromSpeciesId = const Value.absent(),
            required int toSpeciesId,
            required String trigger,
            Value<int?> minLevel = const Value.absent(),
            Value<String?> item = const Value.absent(),
            Value<String?> heldItem = const Value.absent(),
            Value<String?> knownMove = const Value.absent(),
            Value<String?> knownMoveType = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<String?> timeOfDay = const Value.absent(),
            Value<String?> gender = const Value.absent(),
            Value<int?> minHappiness = const Value.absent(),
            Value<int?> minAffection = const Value.absent(),
            Value<int?> minBeauty = const Value.absent(),
            Value<String?> relativePhysicalStats = const Value.absent(),
            Value<String?> partySpecies = const Value.absent(),
            Value<String?> partyType = const Value.absent(),
            Value<String?> tradeSpecies = const Value.absent(),
            required bool needsOverworldRain,
            required bool turnUpsideDown,
            Value<int> rowid = const Value.absent(),
          }) =>
              EvolutionEdgesCompanion.insert(
            chainId: chainId,
            fromSpeciesId: fromSpeciesId,
            toSpeciesId: toSpeciesId,
            trigger: trigger,
            minLevel: minLevel,
            item: item,
            heldItem: heldItem,
            knownMove: knownMove,
            knownMoveType: knownMoveType,
            location: location,
            timeOfDay: timeOfDay,
            gender: gender,
            minHappiness: minHappiness,
            minAffection: minAffection,
            minBeauty: minBeauty,
            relativePhysicalStats: relativePhysicalStats,
            partySpecies: partySpecies,
            partyType: partyType,
            tradeSpecies: tradeSpecies,
            needsOverworldRain: needsOverworldRain,
            turnUpsideDown: turnUpsideDown,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EvolutionEdgesTableProcessedTableManager = ProcessedTableManager<
    _$PokedexDatabase,
    $EvolutionEdgesTable,
    EvolutionEdgesRow,
    $$EvolutionEdgesTableFilterComposer,
    $$EvolutionEdgesTableOrderingComposer,
    $$EvolutionEdgesTableAnnotationComposer,
    $$EvolutionEdgesTableCreateCompanionBuilder,
    $$EvolutionEdgesTableUpdateCompanionBuilder,
    (
      EvolutionEdgesRow,
      BaseReferences<_$PokedexDatabase, $EvolutionEdgesTable, EvolutionEdgesRow>
    ),
    EvolutionEdgesRow,
    PrefetchHooks Function()>;
typedef $$VersionsTableCreateCompanionBuilder = VersionsCompanion Function({
  required int id,
  required String identifier,
  required int generationId,
  required String versionGroup,
  Value<String?> nameZhHans,
  required String nameEn,
  Value<String?> nameJa,
  Value<int> rowid,
});
typedef $$VersionsTableUpdateCompanionBuilder = VersionsCompanion Function({
  Value<int> id,
  Value<String> identifier,
  Value<int> generationId,
  Value<String> versionGroup,
  Value<String?> nameZhHans,
  Value<String> nameEn,
  Value<String?> nameJa,
  Value<int> rowid,
});

class $$VersionsTableFilterComposer
    extends Composer<_$PokedexDatabase, $VersionsTable> {
  $$VersionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get identifier => $composableBuilder(
      column: $table.identifier, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get generationId => $composableBuilder(
      column: $table.generationId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get versionGroup => $composableBuilder(
      column: $table.versionGroup, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameZhHans => $composableBuilder(
      column: $table.nameZhHans, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameEn => $composableBuilder(
      column: $table.nameEn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameJa => $composableBuilder(
      column: $table.nameJa, builder: (column) => ColumnFilters(column));
}

class $$VersionsTableOrderingComposer
    extends Composer<_$PokedexDatabase, $VersionsTable> {
  $$VersionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get identifier => $composableBuilder(
      column: $table.identifier, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get generationId => $composableBuilder(
      column: $table.generationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get versionGroup => $composableBuilder(
      column: $table.versionGroup,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameZhHans => $composableBuilder(
      column: $table.nameZhHans, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameEn => $composableBuilder(
      column: $table.nameEn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameJa => $composableBuilder(
      column: $table.nameJa, builder: (column) => ColumnOrderings(column));
}

class $$VersionsTableAnnotationComposer
    extends Composer<_$PokedexDatabase, $VersionsTable> {
  $$VersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get identifier => $composableBuilder(
      column: $table.identifier, builder: (column) => column);

  GeneratedColumn<int> get generationId => $composableBuilder(
      column: $table.generationId, builder: (column) => column);

  GeneratedColumn<String> get versionGroup => $composableBuilder(
      column: $table.versionGroup, builder: (column) => column);

  GeneratedColumn<String> get nameZhHans => $composableBuilder(
      column: $table.nameZhHans, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get nameJa =>
      $composableBuilder(column: $table.nameJa, builder: (column) => column);
}

class $$VersionsTableTableManager extends RootTableManager<
    _$PokedexDatabase,
    $VersionsTable,
    VersionsRow,
    $$VersionsTableFilterComposer,
    $$VersionsTableOrderingComposer,
    $$VersionsTableAnnotationComposer,
    $$VersionsTableCreateCompanionBuilder,
    $$VersionsTableUpdateCompanionBuilder,
    (
      VersionsRow,
      BaseReferences<_$PokedexDatabase, $VersionsTable, VersionsRow>
    ),
    VersionsRow,
    PrefetchHooks Function()> {
  $$VersionsTableTableManager(_$PokedexDatabase db, $VersionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VersionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> identifier = const Value.absent(),
            Value<int> generationId = const Value.absent(),
            Value<String> versionGroup = const Value.absent(),
            Value<String?> nameZhHans = const Value.absent(),
            Value<String> nameEn = const Value.absent(),
            Value<String?> nameJa = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VersionsCompanion(
            id: id,
            identifier: identifier,
            generationId: generationId,
            versionGroup: versionGroup,
            nameZhHans: nameZhHans,
            nameEn: nameEn,
            nameJa: nameJa,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int id,
            required String identifier,
            required int generationId,
            required String versionGroup,
            Value<String?> nameZhHans = const Value.absent(),
            required String nameEn,
            Value<String?> nameJa = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VersionsCompanion.insert(
            id: id,
            identifier: identifier,
            generationId: generationId,
            versionGroup: versionGroup,
            nameZhHans: nameZhHans,
            nameEn: nameEn,
            nameJa: nameJa,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VersionsTableProcessedTableManager = ProcessedTableManager<
    _$PokedexDatabase,
    $VersionsTable,
    VersionsRow,
    $$VersionsTableFilterComposer,
    $$VersionsTableOrderingComposer,
    $$VersionsTableAnnotationComposer,
    $$VersionsTableCreateCompanionBuilder,
    $$VersionsTableUpdateCompanionBuilder,
    (
      VersionsRow,
      BaseReferences<_$PokedexDatabase, $VersionsTable, VersionsRow>
    ),
    VersionsRow,
    PrefetchHooks Function()>;
typedef $$FlavorTextsTableCreateCompanionBuilder = FlavorTextsCompanion
    Function({
  required int speciesId,
  required int versionId,
  required String language,
  required String flavorText,
  Value<int> rowid,
});
typedef $$FlavorTextsTableUpdateCompanionBuilder = FlavorTextsCompanion
    Function({
  Value<int> speciesId,
  Value<int> versionId,
  Value<String> language,
  Value<String> flavorText,
  Value<int> rowid,
});

class $$FlavorTextsTableFilterComposer
    extends Composer<_$PokedexDatabase, $FlavorTextsTable> {
  $$FlavorTextsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get speciesId => $composableBuilder(
      column: $table.speciesId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get versionId => $composableBuilder(
      column: $table.versionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get flavorText => $composableBuilder(
      column: $table.flavorText, builder: (column) => ColumnFilters(column));
}

class $$FlavorTextsTableOrderingComposer
    extends Composer<_$PokedexDatabase, $FlavorTextsTable> {
  $$FlavorTextsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get speciesId => $composableBuilder(
      column: $table.speciesId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get versionId => $composableBuilder(
      column: $table.versionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get flavorText => $composableBuilder(
      column: $table.flavorText, builder: (column) => ColumnOrderings(column));
}

class $$FlavorTextsTableAnnotationComposer
    extends Composer<_$PokedexDatabase, $FlavorTextsTable> {
  $$FlavorTextsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get speciesId =>
      $composableBuilder(column: $table.speciesId, builder: (column) => column);

  GeneratedColumn<int> get versionId =>
      $composableBuilder(column: $table.versionId, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get flavorText => $composableBuilder(
      column: $table.flavorText, builder: (column) => column);
}

class $$FlavorTextsTableTableManager extends RootTableManager<
    _$PokedexDatabase,
    $FlavorTextsTable,
    FlavorTextsRow,
    $$FlavorTextsTableFilterComposer,
    $$FlavorTextsTableOrderingComposer,
    $$FlavorTextsTableAnnotationComposer,
    $$FlavorTextsTableCreateCompanionBuilder,
    $$FlavorTextsTableUpdateCompanionBuilder,
    (
      FlavorTextsRow,
      BaseReferences<_$PokedexDatabase, $FlavorTextsTable, FlavorTextsRow>
    ),
    FlavorTextsRow,
    PrefetchHooks Function()> {
  $$FlavorTextsTableTableManager(_$PokedexDatabase db, $FlavorTextsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FlavorTextsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FlavorTextsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FlavorTextsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> speciesId = const Value.absent(),
            Value<int> versionId = const Value.absent(),
            Value<String> language = const Value.absent(),
            Value<String> flavorText = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FlavorTextsCompanion(
            speciesId: speciesId,
            versionId: versionId,
            language: language,
            flavorText: flavorText,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int speciesId,
            required int versionId,
            required String language,
            required String flavorText,
            Value<int> rowid = const Value.absent(),
          }) =>
              FlavorTextsCompanion.insert(
            speciesId: speciesId,
            versionId: versionId,
            language: language,
            flavorText: flavorText,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FlavorTextsTableProcessedTableManager = ProcessedTableManager<
    _$PokedexDatabase,
    $FlavorTextsTable,
    FlavorTextsRow,
    $$FlavorTextsTableFilterComposer,
    $$FlavorTextsTableOrderingComposer,
    $$FlavorTextsTableAnnotationComposer,
    $$FlavorTextsTableCreateCompanionBuilder,
    $$FlavorTextsTableUpdateCompanionBuilder,
    (
      FlavorTextsRow,
      BaseReferences<_$PokedexDatabase, $FlavorTextsTable, FlavorTextsRow>
    ),
    FlavorTextsRow,
    PrefetchHooks Function()>;
typedef $$PokedexesTableCreateCompanionBuilder = PokedexesCompanion Function({
  required int id,
  required String identifier,
  required String nameZhHans,
  Value<int?> generationId,
  Value<int> rowid,
});
typedef $$PokedexesTableUpdateCompanionBuilder = PokedexesCompanion Function({
  Value<int> id,
  Value<String> identifier,
  Value<String> nameZhHans,
  Value<int?> generationId,
  Value<int> rowid,
});

class $$PokedexesTableFilterComposer
    extends Composer<_$PokedexDatabase, $PokedexesTable> {
  $$PokedexesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get identifier => $composableBuilder(
      column: $table.identifier, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameZhHans => $composableBuilder(
      column: $table.nameZhHans, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get generationId => $composableBuilder(
      column: $table.generationId, builder: (column) => ColumnFilters(column));
}

class $$PokedexesTableOrderingComposer
    extends Composer<_$PokedexDatabase, $PokedexesTable> {
  $$PokedexesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get identifier => $composableBuilder(
      column: $table.identifier, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameZhHans => $composableBuilder(
      column: $table.nameZhHans, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get generationId => $composableBuilder(
      column: $table.generationId,
      builder: (column) => ColumnOrderings(column));
}

class $$PokedexesTableAnnotationComposer
    extends Composer<_$PokedexDatabase, $PokedexesTable> {
  $$PokedexesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get identifier => $composableBuilder(
      column: $table.identifier, builder: (column) => column);

  GeneratedColumn<String> get nameZhHans => $composableBuilder(
      column: $table.nameZhHans, builder: (column) => column);

  GeneratedColumn<int> get generationId => $composableBuilder(
      column: $table.generationId, builder: (column) => column);
}

class $$PokedexesTableTableManager extends RootTableManager<
    _$PokedexDatabase,
    $PokedexesTable,
    PokedexesRow,
    $$PokedexesTableFilterComposer,
    $$PokedexesTableOrderingComposer,
    $$PokedexesTableAnnotationComposer,
    $$PokedexesTableCreateCompanionBuilder,
    $$PokedexesTableUpdateCompanionBuilder,
    (
      PokedexesRow,
      BaseReferences<_$PokedexDatabase, $PokedexesTable, PokedexesRow>
    ),
    PokedexesRow,
    PrefetchHooks Function()> {
  $$PokedexesTableTableManager(_$PokedexDatabase db, $PokedexesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PokedexesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PokedexesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PokedexesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> identifier = const Value.absent(),
            Value<String> nameZhHans = const Value.absent(),
            Value<int?> generationId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PokedexesCompanion(
            id: id,
            identifier: identifier,
            nameZhHans: nameZhHans,
            generationId: generationId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int id,
            required String identifier,
            required String nameZhHans,
            Value<int?> generationId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PokedexesCompanion.insert(
            id: id,
            identifier: identifier,
            nameZhHans: nameZhHans,
            generationId: generationId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PokedexesTableProcessedTableManager = ProcessedTableManager<
    _$PokedexDatabase,
    $PokedexesTable,
    PokedexesRow,
    $$PokedexesTableFilterComposer,
    $$PokedexesTableOrderingComposer,
    $$PokedexesTableAnnotationComposer,
    $$PokedexesTableCreateCompanionBuilder,
    $$PokedexesTableUpdateCompanionBuilder,
    (
      PokedexesRow,
      BaseReferences<_$PokedexDatabase, $PokedexesTable, PokedexesRow>
    ),
    PokedexesRow,
    PrefetchHooks Function()>;
typedef $$SpeciesDexNumbersTableCreateCompanionBuilder
    = SpeciesDexNumbersCompanion Function({
  required int pokedexId,
  required int speciesId,
  required int dexNumber,
  Value<int> rowid,
});
typedef $$SpeciesDexNumbersTableUpdateCompanionBuilder
    = SpeciesDexNumbersCompanion Function({
  Value<int> pokedexId,
  Value<int> speciesId,
  Value<int> dexNumber,
  Value<int> rowid,
});

class $$SpeciesDexNumbersTableFilterComposer
    extends Composer<_$PokedexDatabase, $SpeciesDexNumbersTable> {
  $$SpeciesDexNumbersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get pokedexId => $composableBuilder(
      column: $table.pokedexId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get speciesId => $composableBuilder(
      column: $table.speciesId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dexNumber => $composableBuilder(
      column: $table.dexNumber, builder: (column) => ColumnFilters(column));
}

class $$SpeciesDexNumbersTableOrderingComposer
    extends Composer<_$PokedexDatabase, $SpeciesDexNumbersTable> {
  $$SpeciesDexNumbersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get pokedexId => $composableBuilder(
      column: $table.pokedexId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get speciesId => $composableBuilder(
      column: $table.speciesId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dexNumber => $composableBuilder(
      column: $table.dexNumber, builder: (column) => ColumnOrderings(column));
}

class $$SpeciesDexNumbersTableAnnotationComposer
    extends Composer<_$PokedexDatabase, $SpeciesDexNumbersTable> {
  $$SpeciesDexNumbersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get pokedexId =>
      $composableBuilder(column: $table.pokedexId, builder: (column) => column);

  GeneratedColumn<int> get speciesId =>
      $composableBuilder(column: $table.speciesId, builder: (column) => column);

  GeneratedColumn<int> get dexNumber =>
      $composableBuilder(column: $table.dexNumber, builder: (column) => column);
}

class $$SpeciesDexNumbersTableTableManager extends RootTableManager<
    _$PokedexDatabase,
    $SpeciesDexNumbersTable,
    SpeciesDexNumbersRow,
    $$SpeciesDexNumbersTableFilterComposer,
    $$SpeciesDexNumbersTableOrderingComposer,
    $$SpeciesDexNumbersTableAnnotationComposer,
    $$SpeciesDexNumbersTableCreateCompanionBuilder,
    $$SpeciesDexNumbersTableUpdateCompanionBuilder,
    (
      SpeciesDexNumbersRow,
      BaseReferences<_$PokedexDatabase, $SpeciesDexNumbersTable,
          SpeciesDexNumbersRow>
    ),
    SpeciesDexNumbersRow,
    PrefetchHooks Function()> {
  $$SpeciesDexNumbersTableTableManager(
      _$PokedexDatabase db, $SpeciesDexNumbersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SpeciesDexNumbersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SpeciesDexNumbersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SpeciesDexNumbersTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> pokedexId = const Value.absent(),
            Value<int> speciesId = const Value.absent(),
            Value<int> dexNumber = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SpeciesDexNumbersCompanion(
            pokedexId: pokedexId,
            speciesId: speciesId,
            dexNumber: dexNumber,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int pokedexId,
            required int speciesId,
            required int dexNumber,
            Value<int> rowid = const Value.absent(),
          }) =>
              SpeciesDexNumbersCompanion.insert(
            pokedexId: pokedexId,
            speciesId: speciesId,
            dexNumber: dexNumber,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SpeciesDexNumbersTableProcessedTableManager = ProcessedTableManager<
    _$PokedexDatabase,
    $SpeciesDexNumbersTable,
    SpeciesDexNumbersRow,
    $$SpeciesDexNumbersTableFilterComposer,
    $$SpeciesDexNumbersTableOrderingComposer,
    $$SpeciesDexNumbersTableAnnotationComposer,
    $$SpeciesDexNumbersTableCreateCompanionBuilder,
    $$SpeciesDexNumbersTableUpdateCompanionBuilder,
    (
      SpeciesDexNumbersRow,
      BaseReferences<_$PokedexDatabase, $SpeciesDexNumbersTable,
          SpeciesDexNumbersRow>
    ),
    SpeciesDexNumbersRow,
    PrefetchHooks Function()>;

class $PokedexDatabaseManager {
  final _$PokedexDatabase _db;
  $PokedexDatabaseManager(this._db);
  $$MetaTableTableManager get meta => $$MetaTableTableManager(_db, _db.meta);
  $$GenerationsTableTableManager get generations =>
      $$GenerationsTableTableManager(_db, _db.generations);
  $$TypesTableTableManager get types =>
      $$TypesTableTableManager(_db, _db.types);
  $$AbilitiesTableTableManager get abilities =>
      $$AbilitiesTableTableManager(_db, _db.abilities);
  $$MovesTableTableManager get moves =>
      $$MovesTableTableManager(_db, _db.moves);
  $$SpeciesTableTableManager get species =>
      $$SpeciesTableTableManager(_db, _db.species);
  $$FormsTableTableManager get forms =>
      $$FormsTableTableManager(_db, _db.forms);
  $$FormTypesTableTableManager get formTypes =>
      $$FormTypesTableTableManager(_db, _db.formTypes);
  $$FormStatsTableTableManager get formStats =>
      $$FormStatsTableTableManager(_db, _db.formStats);
  $$FormAbilitiesTableTableManager get formAbilities =>
      $$FormAbilitiesTableTableManager(_db, _db.formAbilities);
  $$PokemonFormMovesTableTableManager get pokemonFormMoves =>
      $$PokemonFormMovesTableTableManager(_db, _db.pokemonFormMoves);
  $$EvolutionChainsTableTableManager get evolutionChains =>
      $$EvolutionChainsTableTableManager(_db, _db.evolutionChains);
  $$EvolutionEdgesTableTableManager get evolutionEdges =>
      $$EvolutionEdgesTableTableManager(_db, _db.evolutionEdges);
  $$VersionsTableTableManager get versions =>
      $$VersionsTableTableManager(_db, _db.versions);
  $$FlavorTextsTableTableManager get flavorTexts =>
      $$FlavorTextsTableTableManager(_db, _db.flavorTexts);
  $$PokedexesTableTableManager get pokedexes =>
      $$PokedexesTableTableManager(_db, _db.pokedexes);
  $$SpeciesDexNumbersTableTableManager get speciesDexNumbers =>
      $$SpeciesDexNumbersTableTableManager(_db, _db.speciesDexNumbers);
}

mixin _$PokedexDaoMixin on DatabaseAccessor<PokedexDatabase> {}
mixin _$MoveDaoMixin on DatabaseAccessor<PokedexDatabase> {}
mixin _$EvolutionDaoMixin on DatabaseAccessor<PokedexDatabase> {}
mixin _$MetaDaoMixin on DatabaseAccessor<PokedexDatabase> {}
