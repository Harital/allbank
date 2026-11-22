import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../core/bank_connector.dart';
import '../../providers/providers.dart';
import '../caixabank/caixabank_connect_screen.dart';
import '../degiro/degiro_connect_screen.dart';
import '../trade_republic/tr_connect_screen.dart';
import 'bank_catalog.dart';
import 'bank_store.dart';
import 'device_authenticator.dart';
import 'strings.dart';

class AllBankApp extends StatelessWidget {
  const AllBankApp({
    super.key,
    required this.store,
    required this.authenticator,
    this.providerOverrides = const [],
  });

  final BankStore store;
  final DeviceAuthenticator authenticator;

  /// Riverpod provider overrides, used by tests to inject fake bank
  /// connectors instead of the real ones.
  final List<Override> providerOverrides;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: providerOverrides,
    child: MaterialApp(
      title: 'All Bank',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff174b67)),
        useMaterial3: true,
      ),
      supportedLocales: const [Locale('ca'), Locale('es'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: BankHome(store: store, authenticator: authenticator),
    ),
  );
}

class BankHome extends ConsumerStatefulWidget {
  const BankHome({super.key, required this.store, required this.authenticator});

  final BankStore store;
  final DeviceAuthenticator authenticator;

  @override
  ConsumerState<BankHome> createState() => _BankHomeState();
}

class _BankHomeState extends ConsumerState<BankHome> with WidgetsBindingObserver {
  bool _unlocked = false;
  bool _busy = false;
  String? _errorKey;
  List<String> _selected = [];
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_unlocked &&
        (state == AppLifecycleState.hidden ||
            state == AppLifecycleState.paused)) {
      _generation++;
      Navigator.of(context).popUntil((route) => route.isFirst);
      setState(() {
        _unlocked = false;
        _selected = [];
      });
    }
  }

  Future<void> _unlock() async {
    if (_busy) return;
    final generation = _generation;
    setState(() {
      _busy = true;
      _errorKey = null;
    });
    try {
      final authenticated = await widget.authenticator.authenticate(
        text(context, 'authReason'),
      );
      if (!mounted || generation != _generation) return;
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle == AppLifecycleState.hidden ||
          lifecycle == AppLifecycleState.paused ||
          lifecycle == AppLifecycleState.detached) {
        return;
      }
      if (!authenticated) {
        setState(() => _errorKey = 'authFailed');
        return;
      }
      final selected = await widget.store.read();
      if (!mounted || generation != _generation) return;
      final currentState = WidgetsBinding.instance.lifecycleState;
      if (currentState == AppLifecycleState.hidden ||
          currentState == AppLifecycleState.paused ||
          currentState == AppLifecycleState.detached) {
        return;
      }
      setState(() {
        _selected = selected.where(banks.contains).toSet().toList();
        _unlocked = true;
      });
    } on LocalAuthException {
      if (mounted) setState(() => _errorKey = 'authFailed');
    } on PlatformException {
      if (mounted) setState(() => _errorKey = 'storageError');
    } on FormatException {
      if (mounted) setState(() => _errorKey = 'storageError');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(List<String> names) async {
    setState(() => _busy = true);
    try {
      await widget.store.write(names);
      if (mounted && _unlocked) setState(() => _selected = names);
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text(context, 'storageError'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addBank() async {
    final bank = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                text(context, 'chooseBank'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final bank in banks.where((bank) => !_selected.contains(bank)))
              ListTile(
                title: Text(bank),
                subtitle: Text(text(context, 'notConnected')),
                onTap: () => Navigator.pop(context, bank),
              ),
          ],
        ),
      ),
    );
    if (bank != null && mounted && _unlocked) {
      await _save([..._selected, bank]);
    }
  }

  Future<void> _removeBank(String bank) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(text(context, 'removeTitle')),
        content: Text('${text(context, 'removeBody')} $bank?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(text(context, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(text(context, 'remove')),
          ),
        ],
      ),
    );
    if (remove == true && mounted && _unlocked) {
      if (connectableBankIds.contains(bank)) {
        await ref.read(connectorsProvider)[bank]?.disconnect();
        ref.invalidate(connectionStatusProvider(bank));
        ref.invalidate(balancesProvider(bank));
      }
      await _save(_selected.where((item) => item != bank).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Bank')),
      floatingActionButton: _unlocked && _selected.length < banks.length
          ? FloatingActionButton(
              onPressed: _busy ? null : _addBank,
              tooltip: text(context, 'add'),
              child: const Icon(Icons.add),
            )
          : null,
      body: !_unlocked
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 52),
                    const SizedBox(height: 16),
                    Text(
                      text(context, 'locked'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (_errorKey != null) ...[
                      Text(
                        text(context, _errorKey!),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    FilledButton(
                      onPressed: _busy ? null : _unlock,
                      child: Text(text(context, 'unlock')),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text(context, 'overview'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(text(context, 'noTotal')),
                        const SizedBox(height: 8),
                        Text(text(context, 'disclaimer')),
                      ],
                    ),
                  ),
                ),
                if (_selected.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      text(context, 'empty'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final bank in _selected)
                  Card(
                    child: ExpansionTile(
                      title: Text(bank),
                      subtitle: connectableBankIds.contains(bank)
                          ? null
                          : Text(text(context, 'notConnected')),
                      children: [
                        if (connectableBankIds.contains(bank))
                          _ConnectableBankBody(bankId: bank)
                        else ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            child: Text(text(context, 'productsUnavailable')),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                text(context, 'productCategories'),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 8,
                                children: [
                                  for (final category in productCategories)
                                    Chip(label: Text(text(context, category))),
                                ],
                              ),
                            ),
                          ),
                        ],
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _busy ? null : () => _removeBank(bank),
                            icon: const Icon(Icons.delete_outline),
                            label: Text(text(context, 'remove')),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Body shown for a bank that has a real connector (CaixaBank, Trade
/// Republic, DEGIRO): either a "Connect" button, or the fetched balances.
class _ConnectableBankBody extends ConsumerWidget {
  const _ConnectableBankBody({required this.bankId});

  final String bankId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionAsync = ref.watch(connectionStatusProvider(bankId));
    return connectionAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text(context, 'fetchError')),
      ),
      data: (connected) {
        if (!connected) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: () => _openConnectScreen(context, ref, bankId),
                child: Text(text(context, 'connect')),
              ),
            ),
          );
        }
        return _BalancesList(bankId: bankId);
      },
    );
  }
}

class _BalancesList extends ConsumerWidget {
  const _BalancesList({required this.bankId});

  final String bankId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(balancesProvider(bankId));
    return balancesAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text(context, 'loadingBalances')),
      ),
      error: (error, stackTrace) {
        final expired = error is BankSessionExpiredException;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                expired ? text(context, 'sessionExpired') : text(context, 'fetchError'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => expired
                    ? _openConnectScreen(context, ref, bankId)
                    : ref.invalidate(balancesProvider(bankId)),
                child: Text(text(context, expired ? 'reconnect' : 'refresh')),
              ),
            ],
          ),
        );
      },
      data: (balances) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final balance in balances)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(balance.label)),
                    Text('${balance.amount.toStringAsFixed(2)} ${balance.currency}'),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => ref.invalidate(balancesProvider(bankId)),
                icon: const Icon(Icons.refresh),
                label: Text(text(context, 'refresh')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _openConnectScreen(BuildContext context, WidgetRef ref, String bankId) {
  final screen = switch (bankId) {
    'CaixaBank' => const CaixaBankConnectScreen(),
    'Trade Republic' => const TrConnectScreen(),
    'DEGIRO' => const DegiroConnectScreen(),
    _ => null,
  };
  if (screen == null) return;
  Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => screen));
}
