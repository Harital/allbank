import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/bank_connector.dart';
import '../core/product_balance.dart';
import '../core/secure_credential_store.dart';
import '../features/caixabank/caixabank_connector.dart';
import '../features/degiro/degiro_connector.dart';
import '../features/trade_republic/tr_connector.dart';
import '../storage/app_database.dart';
import '../storage/balance_cache_repository.dart';

final secureCredentialStoreProvider = Provider<SecureCredentialStore>(
  (ref) => const FlutterSecureCredentialStore(),
);

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final balanceCacheRepositoryProvider = Provider<BalanceCacheRepository>(
  (ref) => BalanceCacheRepository(ref.watch(appDatabaseProvider)),
);

final caixaBankConnectorProvider = Provider<CaixaBankConnector>(
  (ref) => CaixaBankConnector(
    credentialStore: ref.watch(secureCredentialStoreProvider),
  ),
);

final tradeRepublicConnectorProvider = Provider<TradeRepublicConnector>(
  (ref) => TradeRepublicConnector(
    credentialStore: ref.watch(secureCredentialStoreProvider),
  ),
);

final degiroConnectorProvider = Provider<DegiroConnector>(
  (ref) => DegiroConnector(
    credentialStore: ref.watch(secureCredentialStoreProvider),
  ),
);

/// Banks with a real connector in this MVP. Any other entry in the main
/// `banks` list (Revolut, ING, MyInvestor, Pibank, Raisin) has no connector
/// yet, see README.md.
final connectorsProvider = Provider<Map<String, BankConnector>>((ref) {
  return {
    'CaixaBank': ref.watch(caixaBankConnectorProvider),
    'Trade Republic': ref.watch(tradeRepublicConnectorProvider),
    'DEGIRO': ref.watch(degiroConnectorProvider),
  };
});

// Errors here (no connection yet, expired session) are states to show the
// user immediately, not transient glitches -- Riverpod's default automatic
// retry (with growing backoff) would just leave the UI stuck on a loading
// spinner for several seconds before showing them, so it is disabled.
Duration? _noRetry(int retryCount, Object error) => null;

final connectionStatusProvider = FutureProvider.family<bool, String>((
  ref,
  bankId,
) async {
  final connector = ref.watch(connectorsProvider)[bankId];
  if (connector == null) return false;
  return connector.isConnected();
}, retry: _noRetry);

/// Fetches fresh balances for [bankId] and refreshes the local cache. Call
/// `ref.invalidate(balancesProvider(bankId))` to force a refresh (e.g. after
/// connecting, or from a pull-to-refresh action).
final balancesProvider = FutureProvider.family<List<ProductBalance>, String>((
  ref,
  bankId,
) async {
  final connector = ref.watch(connectorsProvider)[bankId];
  final cache = ref.watch(balanceCacheRepositoryProvider);
  if (connector == null) return const [];
  final fresh = await connector.fetchBalances();
  await cache.replace(bankId, fresh);
  return fresh;
}, retry: _noRetry);
