// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_database.dart';

// ignore_for_file: type=lint
class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, FavoriteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _speciesIdMeta =
      const VerificationMeta('speciesId');
  @override
  late final GeneratedColumn<int> speciesId = GeneratedColumn<int>(
      'species_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [speciesId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(Insertable<FavoriteRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('species_id')) {
      context.handle(_speciesIdMeta,
          speciesId.isAcceptableOrUnknown(data['species_id']!, _speciesIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {speciesId};
  @override
  FavoriteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteRow(
      speciesId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}species_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class FavoriteRow extends DataClass implements Insertable<FavoriteRow> {
  final int speciesId;
  final String createdAt;
  const FavoriteRow({required this.speciesId, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['species_id'] = Variable<int>(speciesId);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(
      speciesId: Value(speciesId),
      createdAt: Value(createdAt),
    );
  }

  factory FavoriteRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteRow(
      speciesId: serializer.fromJson<int>(json['speciesId']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'speciesId': serializer.toJson<int>(speciesId),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  FavoriteRow copyWith({int? speciesId, String? createdAt}) => FavoriteRow(
        speciesId: speciesId ?? this.speciesId,
        createdAt: createdAt ?? this.createdAt,
      );
  FavoriteRow copyWithCompanion(FavoritesCompanion data) {
    return FavoriteRow(
      speciesId: data.speciesId.present ? data.speciesId.value : this.speciesId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteRow(')
          ..write('speciesId: $speciesId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(speciesId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteRow &&
          other.speciesId == this.speciesId &&
          other.createdAt == this.createdAt);
}

class FavoritesCompanion extends UpdateCompanion<FavoriteRow> {
  final Value<int> speciesId;
  final Value<String> createdAt;
  const FavoritesCompanion({
    this.speciesId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FavoritesCompanion.insert({
    this.speciesId = const Value.absent(),
    required String createdAt,
  }) : createdAt = Value(createdAt);
  static Insertable<FavoriteRow> custom({
    Expression<int>? speciesId,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (speciesId != null) 'species_id': speciesId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FavoritesCompanion copyWith(
      {Value<int>? speciesId, Value<String>? createdAt}) {
    return FavoritesCompanion(
      speciesId: speciesId ?? this.speciesId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (speciesId.present) {
      map['species_id'] = Variable<int>(speciesId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('speciesId: $speciesId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $RecentsTable extends Recents with TableInfo<$RecentsTable, RecentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _speciesIdMeta =
      const VerificationMeta('speciesId');
  @override
  late final GeneratedColumn<int> speciesId = GeneratedColumn<int>(
      'species_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _viewedAtMeta =
      const VerificationMeta('viewedAt');
  @override
  late final GeneratedColumn<String> viewedAt = GeneratedColumn<String>(
      'viewed_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [speciesId, viewedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recents';
  @override
  VerificationContext validateIntegrity(Insertable<RecentRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('species_id')) {
      context.handle(_speciesIdMeta,
          speciesId.isAcceptableOrUnknown(data['species_id']!, _speciesIdMeta));
    }
    if (data.containsKey('viewed_at')) {
      context.handle(_viewedAtMeta,
          viewedAt.isAcceptableOrUnknown(data['viewed_at']!, _viewedAtMeta));
    } else if (isInserting) {
      context.missing(_viewedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {speciesId};
  @override
  RecentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecentRow(
      speciesId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}species_id'])!,
      viewedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}viewed_at'])!,
    );
  }

  @override
  $RecentsTable createAlias(String alias) {
    return $RecentsTable(attachedDatabase, alias);
  }
}

class RecentRow extends DataClass implements Insertable<RecentRow> {
  final int speciesId;
  final String viewedAt;
  const RecentRow({required this.speciesId, required this.viewedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['species_id'] = Variable<int>(speciesId);
    map['viewed_at'] = Variable<String>(viewedAt);
    return map;
  }

  RecentsCompanion toCompanion(bool nullToAbsent) {
    return RecentsCompanion(
      speciesId: Value(speciesId),
      viewedAt: Value(viewedAt),
    );
  }

  factory RecentRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecentRow(
      speciesId: serializer.fromJson<int>(json['speciesId']),
      viewedAt: serializer.fromJson<String>(json['viewedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'speciesId': serializer.toJson<int>(speciesId),
      'viewedAt': serializer.toJson<String>(viewedAt),
    };
  }

  RecentRow copyWith({int? speciesId, String? viewedAt}) => RecentRow(
        speciesId: speciesId ?? this.speciesId,
        viewedAt: viewedAt ?? this.viewedAt,
      );
  RecentRow copyWithCompanion(RecentsCompanion data) {
    return RecentRow(
      speciesId: data.speciesId.present ? data.speciesId.value : this.speciesId,
      viewedAt: data.viewedAt.present ? data.viewedAt.value : this.viewedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecentRow(')
          ..write('speciesId: $speciesId, ')
          ..write('viewedAt: $viewedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(speciesId, viewedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecentRow &&
          other.speciesId == this.speciesId &&
          other.viewedAt == this.viewedAt);
}

class RecentsCompanion extends UpdateCompanion<RecentRow> {
  final Value<int> speciesId;
  final Value<String> viewedAt;
  const RecentsCompanion({
    this.speciesId = const Value.absent(),
    this.viewedAt = const Value.absent(),
  });
  RecentsCompanion.insert({
    this.speciesId = const Value.absent(),
    required String viewedAt,
  }) : viewedAt = Value(viewedAt);
  static Insertable<RecentRow> custom({
    Expression<int>? speciesId,
    Expression<String>? viewedAt,
  }) {
    return RawValuesInsertable({
      if (speciesId != null) 'species_id': speciesId,
      if (viewedAt != null) 'viewed_at': viewedAt,
    });
  }

  RecentsCompanion copyWith({Value<int>? speciesId, Value<String>? viewedAt}) {
    return RecentsCompanion(
      speciesId: speciesId ?? this.speciesId,
      viewedAt: viewedAt ?? this.viewedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (speciesId.present) {
      map['species_id'] = Variable<int>(speciesId.value);
    }
    if (viewedAt.present) {
      map['viewed_at'] = Variable<String>(viewedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecentsCompanion(')
          ..write('speciesId: $speciesId, ')
          ..write('viewedAt: $viewedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$UserDatabase extends GeneratedDatabase {
  _$UserDatabase(QueryExecutor e) : super(e);
  $UserDatabaseManager get managers => $UserDatabaseManager(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $RecentsTable recents = $RecentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [favorites, recents];
}

typedef $$FavoritesTableCreateCompanionBuilder = FavoritesCompanion Function({
  Value<int> speciesId,
  required String createdAt,
});
typedef $$FavoritesTableUpdateCompanionBuilder = FavoritesCompanion Function({
  Value<int> speciesId,
  Value<String> createdAt,
});

class $$FavoritesTableFilterComposer
    extends Composer<_$UserDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get speciesId => $composableBuilder(
      column: $table.speciesId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$UserDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get speciesId => $composableBuilder(
      column: $table.speciesId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$UserDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get speciesId =>
      $composableBuilder(column: $table.speciesId, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FavoritesTableTableManager extends RootTableManager<
    _$UserDatabase,
    $FavoritesTable,
    FavoriteRow,
    $$FavoritesTableFilterComposer,
    $$FavoritesTableOrderingComposer,
    $$FavoritesTableAnnotationComposer,
    $$FavoritesTableCreateCompanionBuilder,
    $$FavoritesTableUpdateCompanionBuilder,
    (FavoriteRow, BaseReferences<_$UserDatabase, $FavoritesTable, FavoriteRow>),
    FavoriteRow,
    PrefetchHooks Function()> {
  $$FavoritesTableTableManager(_$UserDatabase db, $FavoritesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> speciesId = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
          }) =>
              FavoritesCompanion(
            speciesId: speciesId,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> speciesId = const Value.absent(),
            required String createdAt,
          }) =>
              FavoritesCompanion.insert(
            speciesId: speciesId,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FavoritesTableProcessedTableManager = ProcessedTableManager<
    _$UserDatabase,
    $FavoritesTable,
    FavoriteRow,
    $$FavoritesTableFilterComposer,
    $$FavoritesTableOrderingComposer,
    $$FavoritesTableAnnotationComposer,
    $$FavoritesTableCreateCompanionBuilder,
    $$FavoritesTableUpdateCompanionBuilder,
    (FavoriteRow, BaseReferences<_$UserDatabase, $FavoritesTable, FavoriteRow>),
    FavoriteRow,
    PrefetchHooks Function()>;
typedef $$RecentsTableCreateCompanionBuilder = RecentsCompanion Function({
  Value<int> speciesId,
  required String viewedAt,
});
typedef $$RecentsTableUpdateCompanionBuilder = RecentsCompanion Function({
  Value<int> speciesId,
  Value<String> viewedAt,
});

class $$RecentsTableFilterComposer
    extends Composer<_$UserDatabase, $RecentsTable> {
  $$RecentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get speciesId => $composableBuilder(
      column: $table.speciesId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get viewedAt => $composableBuilder(
      column: $table.viewedAt, builder: (column) => ColumnFilters(column));
}

class $$RecentsTableOrderingComposer
    extends Composer<_$UserDatabase, $RecentsTable> {
  $$RecentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get speciesId => $composableBuilder(
      column: $table.speciesId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get viewedAt => $composableBuilder(
      column: $table.viewedAt, builder: (column) => ColumnOrderings(column));
}

class $$RecentsTableAnnotationComposer
    extends Composer<_$UserDatabase, $RecentsTable> {
  $$RecentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get speciesId =>
      $composableBuilder(column: $table.speciesId, builder: (column) => column);

  GeneratedColumn<String> get viewedAt =>
      $composableBuilder(column: $table.viewedAt, builder: (column) => column);
}

class $$RecentsTableTableManager extends RootTableManager<
    _$UserDatabase,
    $RecentsTable,
    RecentRow,
    $$RecentsTableFilterComposer,
    $$RecentsTableOrderingComposer,
    $$RecentsTableAnnotationComposer,
    $$RecentsTableCreateCompanionBuilder,
    $$RecentsTableUpdateCompanionBuilder,
    (RecentRow, BaseReferences<_$UserDatabase, $RecentsTable, RecentRow>),
    RecentRow,
    PrefetchHooks Function()> {
  $$RecentsTableTableManager(_$UserDatabase db, $RecentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> speciesId = const Value.absent(),
            Value<String> viewedAt = const Value.absent(),
          }) =>
              RecentsCompanion(
            speciesId: speciesId,
            viewedAt: viewedAt,
          ),
          createCompanionCallback: ({
            Value<int> speciesId = const Value.absent(),
            required String viewedAt,
          }) =>
              RecentsCompanion.insert(
            speciesId: speciesId,
            viewedAt: viewedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RecentsTableProcessedTableManager = ProcessedTableManager<
    _$UserDatabase,
    $RecentsTable,
    RecentRow,
    $$RecentsTableFilterComposer,
    $$RecentsTableOrderingComposer,
    $$RecentsTableAnnotationComposer,
    $$RecentsTableCreateCompanionBuilder,
    $$RecentsTableUpdateCompanionBuilder,
    (RecentRow, BaseReferences<_$UserDatabase, $RecentsTable, RecentRow>),
    RecentRow,
    PrefetchHooks Function()>;

class $UserDatabaseManager {
  final _$UserDatabase _db;
  $UserDatabaseManager(this._db);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$RecentsTableTableManager get recents =>
      $$RecentsTableTableManager(_db, _db.recents);
}
