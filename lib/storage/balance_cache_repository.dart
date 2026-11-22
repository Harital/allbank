import '../core/product_balance.dart';
import 'app_database.dart';

class BalanceCacheRepository {
  BalanceCacheRepository(this._db);

  final AppDatabase _db;

  Future<List<ProductBalance>> read(String bankId) async {
    final rows = await (_db.select(
      _db.cachedBalances,
    )..where((t) => t.bankId.equals(bankId))).get();
    return rows
        .map(
          (row) => ProductBalance(
            bankId: row.bankId,
            category: ProductCategory.values.byName(row.category),
            label: row.label,
            amount: row.amount,
            currency: row.currency,
            updatedAt: row.updatedAt,
          ),
        )
        .toList();
  }

  Future<void> replace(String bankId, List<ProductBalance> balances) {
    return _db.transaction(() async {
      await (_db.delete(
        _db.cachedBalances,
      )..where((t) => t.bankId.equals(bankId))).go();
      for (final balance in balances) {
        await _db
            .into(_db.cachedBalances)
            .insert(
              CachedBalancesCompanion.insert(
                bankId: balance.bankId,
                category: balance.category.name,
                label: balance.label,
                amount: balance.amount,
                currency: balance.currency,
                updatedAt: balance.updatedAt,
              ),
            );
      }
    });
  }

  Future<void> clear(String bankId) {
    return (_db.delete(
      _db.cachedBalances,
    )..where((t) => t.bankId.equals(bankId))).go();
  }
}
