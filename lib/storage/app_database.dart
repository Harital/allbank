import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Local cache of the last successfully fetched balances per bank, so the
/// overview screen can show something while a fresh fetch is in flight or
/// when offline. This never substitutes a real connection: it is only
/// populated from data a [BankConnector] actually fetched.
class CachedBalances extends Table {
  TextColumn get bankId => text()();
  TextColumn get category => text()();
  TextColumn get label => text()();
  RealColumn get amount => real()();
  TextColumn get currency => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {bankId, category, label};
}

@DriftDatabase(tables: [CachedBalances])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() => driftDatabase(name: 'all_bank');
}
