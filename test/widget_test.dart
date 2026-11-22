import 'package:all_bank/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryStore implements BankStore {
  List<String> names = [];

  @override
  Future<List<String>> read() async => List.of(names);

  @override
  Future<void> write(List<String> names) async => this.names = List.of(names);
}

class FakeAuthenticator implements DeviceAuthenticator {
  bool success = true;

  @override
  Future<bool> authenticate(String reason) async => success;
}

void main() {
  testWidgets('requires authentication and adds and removes an institution', (
    tester,
  ) async {
    final store = MemoryStore();
    final auth = FakeAuthenticator();
    await tester.pumpWidget(AllBankApp(store: store, authenticator: auth));
    expect(find.text('The app is locked'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);

    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revolut'));
    await tester.pumpAndSettle();
    expect(store.names, ['Revolut']);
    expect(find.text('Not connected'), findsOneWidget);
    expect(find.text('Total unavailable'), findsOneWidget);

    await tester.tap(find.text('Revolut'));
    await tester.pumpAndSettle();
    expect(find.text('Product categories (unavailable)'), findsOneWidget);
    expect(find.text('Accounts and deposits'), findsOneWidget);
    expect(find.text('Pension plans'), findsOneWidget);
    await tester.ensureVisible(find.text('Remove'));
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove').last);
    await tester.pumpAndSettle();
    expect(store.names, isEmpty);
  });

  testWidgets('failed authentication never exposes saved institutions', (
    tester,
  ) async {
    final store = MemoryStore()..names = ['Revolut'];
    final auth = FakeAuthenticator()..success = false;
    await tester.pumpWidget(AllBankApp(store: store, authenticator: auth));
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(find.text('Revolut'), findsNothing);
    expect(find.textContaining('Authentication failed'), findsOneWidget);
  });

  testWidgets('locks again when the app is backgrounded', (tester) async {
    final store = MemoryStore()..names = ['Revolut'];
    await tester.pumpWidget(
      AllBankApp(store: store, authenticator: FakeAuthenticator()),
    );
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(find.text('Revolut'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('CaixaBank'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Revolut'), findsNothing);
    expect(find.text('CaixaBank'), findsNothing);
    expect(find.text('The app is locked'), findsOneWidget);
  });
}
