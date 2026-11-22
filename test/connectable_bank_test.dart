import 'package:all_bank/core/bank_connector.dart';
import 'package:all_bank/core/product_balance.dart';
import 'package:all_bank/main.dart';
import 'package:all_bank/providers/providers.dart';
import 'package:all_bank/storage/app_database.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryStore implements BankStore {
  List<String> names = [];

  @override
  Future<List<String>> read() async => List.of(names);

  @override
  Future<void> write(List<String> names) async => this.names = List.of(names);
}

class FakeAuthenticator implements DeviceAuthenticator {
  @override
  Future<bool> authenticate(String reason) async => true;
}

class FakeConnector implements BankConnector {
  FakeConnector(
    this.bankId, {
    this.connected = false,
    this.balances = const [],
    this.throwExpiredOnFetch = false,
  });

  @override
  final String bankId;
  bool connected;
  List<ProductBalance> balances;
  bool throwExpiredOnFetch;

  @override
  Future<bool> isConnected() async => connected;

  @override
  Future<List<ProductBalance>> fetchBalances() async {
    if (!connected || throwExpiredOnFetch) {
      throw BankSessionExpiredException(bankId);
    }
    return balances;
  }

  @override
  Future<void> disconnect() async => connected = false;
}

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  testWidgets(
    'shows a connect button for a connectable bank that is not linked yet',
    (tester) async {
      final store = MemoryStore()..names = ['CaixaBank'];
      final fake = FakeConnector('CaixaBank');
      await tester.pumpWidget(
        AllBankApp(
          store: store,
          authenticator: FakeAuthenticator(),
          providerOverrides: [
            connectorsProvider.overrideWithValue({'CaixaBank': fake}),
            appDatabaseProvider.overrideWithValue(
              AppDatabase.forTesting(NativeDatabase.memory()),
            ),
          ],
        ),
      );
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CaixaBank'));
      await tester.pumpAndSettle();
      expect(find.text('Connect'), findsOneWidget);
    },
  );

  testWidgets('shows fetched balances for a connected bank', (tester) async {
    final store = MemoryStore()..names = ['CaixaBank'];
    final fake = FakeConnector(
      'CaixaBank',
      connected: true,
      balances: [
        ProductBalance(
          bankId: 'CaixaBank',
          category: ProductCategory.accounts,
          label: 'Compte corrent',
          amount: 1234.56,
          currency: 'EUR',
          updatedAt: DateTime(2026),
        ),
      ],
    );
    await tester.pumpWidget(
      AllBankApp(
        store: store,
        authenticator: FakeAuthenticator(),
        providerOverrides: [
          connectorsProvider.overrideWithValue({'CaixaBank': fake}),
          appDatabaseProvider.overrideWithValue(
            AppDatabase.forTesting(NativeDatabase.memory()),
          ),
        ],
      ),
    );
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CaixaBank'));
    await tester.pumpAndSettle();
    expect(find.text('Compte corrent'), findsOneWidget);
    expect(find.text('1234.56 EUR'), findsOneWidget);
  });

  testWidgets('offers to reconnect when the session has expired', (
    tester,
  ) async {
    final store = MemoryStore()..names = ['DEGIRO'];
    final fake = FakeConnector('DEGIRO', connected: true, throwExpiredOnFetch: true);
    await tester.pumpWidget(
      AllBankApp(
        store: store,
        authenticator: FakeAuthenticator(),
        providerOverrides: [
          connectorsProvider.overrideWithValue({'DEGIRO': fake}),
          appDatabaseProvider.overrideWithValue(
            AppDatabase.forTesting(NativeDatabase.memory()),
          ),
        ],
      ),
    );
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DEGIRO'));
    await tester.pumpAndSettle();
    expect(find.text('The session has expired.'), findsOneWidget);
    expect(find.text('Reconnect'), findsOneWidget);
  });
}
