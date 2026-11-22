// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedBalancesTable extends CachedBalances
    with TableInfo<$CachedBalancesTable, CachedBalance> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedBalancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bankIdMeta = const VerificationMeta('bankId');
  @override
  late final GeneratedColumn<String> bankId = GeneratedColumn<String>(
    'bank_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    bankId,
    category,
    label,
    amount,
    currency,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_balances';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedBalance> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('bank_id')) {
      context.handle(
        _bankIdMeta,
        bankId.isAcceptableOrUnknown(data['bank_id']!, _bankIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bankIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bankId, category, label};
  @override
  CachedBalance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedBalance(
      bankId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedBalancesTable createAlias(String alias) {
    return $CachedBalancesTable(attachedDatabase, alias);
  }
}

class CachedBalance extends DataClass implements Insertable<CachedBalance> {
  final String bankId;
  final String category;
  final String label;
  final double amount;
  final String currency;
  final DateTime updatedAt;
  const CachedBalance({
    required this.bankId,
    required this.category,
    required this.label,
    required this.amount,
    required this.currency,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['bank_id'] = Variable<String>(bankId);
    map['category'] = Variable<String>(category);
    map['label'] = Variable<String>(label);
    map['amount'] = Variable<double>(amount);
    map['currency'] = Variable<String>(currency);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedBalancesCompanion toCompanion(bool nullToAbsent) {
    return CachedBalancesCompanion(
      bankId: Value(bankId),
      category: Value(category),
      label: Value(label),
      amount: Value(amount),
      currency: Value(currency),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedBalance.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedBalance(
      bankId: serializer.fromJson<String>(json['bankId']),
      category: serializer.fromJson<String>(json['category']),
      label: serializer.fromJson<String>(json['label']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bankId': serializer.toJson<String>(bankId),
      'category': serializer.toJson<String>(category),
      'label': serializer.toJson<String>(label),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String>(currency),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedBalance copyWith({
    String? bankId,
    String? category,
    String? label,
    double? amount,
    String? currency,
    DateTime? updatedAt,
  }) => CachedBalance(
    bankId: bankId ?? this.bankId,
    category: category ?? this.category,
    label: label ?? this.label,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedBalance copyWithCompanion(CachedBalancesCompanion data) {
    return CachedBalance(
      bankId: data.bankId.present ? data.bankId.value : this.bankId,
      category: data.category.present ? data.category.value : this.category,
      label: data.label.present ? data.label.value : this.label,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedBalance(')
          ..write('bankId: $bankId, ')
          ..write('category: $category, ')
          ..write('label: $label, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(bankId, category, label, amount, currency, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedBalance &&
          other.bankId == this.bankId &&
          other.category == this.category &&
          other.label == this.label &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.updatedAt == this.updatedAt);
}

class CachedBalancesCompanion extends UpdateCompanion<CachedBalance> {
  final Value<String> bankId;
  final Value<String> category;
  final Value<String> label;
  final Value<double> amount;
  final Value<String> currency;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedBalancesCompanion({
    this.bankId = const Value.absent(),
    this.category = const Value.absent(),
    this.label = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedBalancesCompanion.insert({
    required String bankId,
    required String category,
    required String label,
    required double amount,
    required String currency,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : bankId = Value(bankId),
       category = Value(category),
       label = Value(label),
       amount = Value(amount),
       currency = Value(currency),
       updatedAt = Value(updatedAt);
  static Insertable<CachedBalance> custom({
    Expression<String>? bankId,
    Expression<String>? category,
    Expression<String>? label,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bankId != null) 'bank_id': bankId,
      if (category != null) 'category': category,
      if (label != null) 'label': label,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedBalancesCompanion copyWith({
    Value<String>? bankId,
    Value<String>? category,
    Value<String>? label,
    Value<double>? amount,
    Value<String>? currency,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedBalancesCompanion(
      bankId: bankId ?? this.bankId,
      category: category ?? this.category,
      label: label ?? this.label,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bankId.present) {
      map['bank_id'] = Variable<String>(bankId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedBalancesCompanion(')
          ..write('bankId: $bankId, ')
          ..write('category: $category, ')
          ..write('label: $label, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedBalancesTable cachedBalances = $CachedBalancesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [cachedBalances];
}

typedef $$CachedBalancesTableCreateCompanionBuilder =
    CachedBalancesCompanion Function({
      required String bankId,
      required String category,
      required String label,
      required double amount,
      required String currency,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedBalancesTableUpdateCompanionBuilder =
    CachedBalancesCompanion Function({
      Value<String> bankId,
      Value<String> category,
      Value<String> label,
      Value<double> amount,
      Value<String> currency,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedBalancesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedBalancesTable> {
  $$CachedBalancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get bankId => $composableBuilder(
    column: $table.bankId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedBalancesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedBalancesTable> {
  $$CachedBalancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get bankId => $composableBuilder(
    column: $table.bankId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedBalancesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedBalancesTable> {
  $$CachedBalancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get bankId =>
      $composableBuilder(column: $table.bankId, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedBalancesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedBalancesTable,
          CachedBalance,
          $$CachedBalancesTableFilterComposer,
          $$CachedBalancesTableOrderingComposer,
          $$CachedBalancesTableAnnotationComposer,
          $$CachedBalancesTableCreateCompanionBuilder,
          $$CachedBalancesTableUpdateCompanionBuilder,
          (
            CachedBalance,
            BaseReferences<_$AppDatabase, $CachedBalancesTable, CachedBalance>,
          ),
          CachedBalance,
          PrefetchHooks Function()
        > {
  $$CachedBalancesTableTableManager(
    _$AppDatabase db,
    $CachedBalancesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedBalancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedBalancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedBalancesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> bankId = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedBalancesCompanion(
                bankId: bankId,
                category: category,
                label: label,
                amount: amount,
                currency: currency,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bankId,
                required String category,
                required String label,
                required double amount,
                required String currency,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedBalancesCompanion.insert(
                bankId: bankId,
                category: category,
                label: label,
                amount: amount,
                currency: currency,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedBalancesTable, CachedBalance>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedBalancesTable,
                    CachedBalance
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedBalancesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedBalancesTable,
      CachedBalance,
      $$CachedBalancesTableFilterComposer,
      $$CachedBalancesTableOrderingComposer,
      $$CachedBalancesTableAnnotationComposer,
      $$CachedBalancesTableCreateCompanionBuilder,
      $$CachedBalancesTableUpdateCompanionBuilder,
      (
        CachedBalance,
        BaseReferences<_$AppDatabase, $CachedBalancesTable, CachedBalance>,
      ),
      CachedBalance,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedBalancesTableTableManager get cachedBalances =>
      $$CachedBalancesTableTableManager(_db, _db.cachedBalances);
}
