import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../../providers/providers.dart';
import '../settings/gocardless_settings_screen.dart';
import 'caixabank_connector.dart';
import 'gocardless_client.dart';

class CaixaBankConnectScreen extends ConsumerStatefulWidget {
  const CaixaBankConnectScreen({super.key});

  @override
  ConsumerState<CaixaBankConnectScreen> createState() =>
      _CaixaBankConnectScreenState();
}

class _CaixaBankConnectScreenState
    extends ConsumerState<CaixaBankConnectScreen> {
  final _queryController = TextEditingController(text: 'caixabank');
  bool _busy = true;
  bool _hasCredentials = false;
  String? _error;
  List<GoCardlessInstitution> _institutions = const [];
  String _query = 'caixabank';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final connector = ref.read(caixaBankConnectorProvider);
    final hasCredentials = await connector.hasApiCredentials();
    if (!hasCredentials) {
      if (mounted) {
        setState(() {
          _hasCredentials = false;
          _busy = false;
        });
      }
      return;
    }
    try {
      final institutions = await connector.searchInstitutions();
      if (!mounted) return;
      setState(() {
        _hasCredentials = true;
        _institutions = institutions;
        _busy = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasCredentials = true;
          _error = e.toString();
          _busy = false;
        });
      }
    }
  }

  Future<void> _connect(GoCardlessInstitution institution) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final connector = ref.read(caixaBankConnectorProvider);
      final link = await connector.startRequisition(institution);
      await FlutterWebAuth2.authenticate(
        url: link,
        callbackUrlScheme: caixaBankCallbackScheme,
      );
      final linked = await connector.completeRequisition();
      if (!mounted) return;
      if (linked) {
        ref.invalidate(connectionStatusProvider('CaixaBank'));
        ref.invalidate(balancesProvider('CaixaBank'));
        Navigator.of(context).pop(true);
      } else {
        setState(() => _error = 'El banc no ha confirmat la connexió encara.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _institutions
        .where((i) => i.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Connecta CaixaBank')),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : !_hasCredentials
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Primer cal configurar les teves pròpies claus de '
                        'GoCardless Bank Account Data.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () async {
                          final saved = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => const GoCardlessSettingsScreen(),
                            ),
                          );
                          if (saved == true) _load();
                        },
                        child: const Text('Configura GoCardless'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _queryController,
                        decoration: const InputDecoration(
                          labelText: 'Cerca la teva entitat',
                        ),
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    Expanded(
                      child: ListView(
                        children: [
                          for (final institution in filtered)
                            ListTile(
                              title: Text(institution.name),
                              subtitle: Text(institution.bic),
                              onTap: () => _connect(institution),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
