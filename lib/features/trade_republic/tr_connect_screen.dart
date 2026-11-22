import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import 'tr_client.dart';

class TrConnectScreen extends ConsumerStatefulWidget {
  const TrConnectScreen({super.key});

  @override
  ConsumerState<TrConnectScreen> createState() => _TrConnectScreenState();
}

class _TrConnectScreenState extends ConsumerState<TrConnectScreen> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _codeController = TextEditingController();

  bool _busy = false;
  String? _error;
  TrLoginProcess? _process;
  bool _waitingForAppConfirmation = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _startLogin() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final connector = ref.read(tradeRepublicConnectorProvider);
      final process = await connector.startLogin(
        phoneNumber: _phoneController.text.trim(),
        pin: _pinController.text.trim(),
      );
      if (!mounted) return;
      if (process.requiredAction == TrLoginRequiredAction.appConfirmation) {
        setState(() {
          _process = process;
          _waitingForAppConfirmation = true;
        });
        await connector.awaitAppConfirmation(process);
        if (!mounted) return;
        _finish();
      } else {
        setState(() => _process = process);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _waitingForAppConfirmation = false;
        });
      }
    }
  }

  Future<void> _submitCode() async {
    final process = _process;
    if (process == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final connector = ref.read(tradeRepublicConnectorProvider);
      await connector.submitAuthenticatorCode(process, _codeController.text.trim());
      if (!mounted) return;
      _finish();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _finish() {
    ref.invalidate(connectionStatusProvider('Trade Republic'));
    ref.invalidate(balancesProvider('Trade Republic'));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final needsCode = _process?.requiredAction == TrLoginRequiredAction.authenticatorCode;
    return Scaffold(
      appBar: AppBar(title: const Text('Connecta Trade Republic')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!needsCode && !_waitingForAppConfirmation) ...[
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telèfon (+34...)',
                ),
                keyboardType: TextInputType.phone,
                enabled: !_busy,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pinController,
                decoration: const InputDecoration(labelText: 'PIN'),
                keyboardType: TextInputType.number,
                obscureText: true,
                enabled: !_busy,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _startLogin,
                child: const Text('Entra'),
              ),
            ] else if (_waitingForAppConfirmation) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              const Text(
                'Obre l\'app de Trade Republic i confirma l\'inici de sessió.',
                textAlign: TextAlign.center,
              ),
            ] else ...[
              const Text('Introdueix el codi de la teva app d\'autenticació.'),
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Codi'),
                keyboardType: TextInputType.number,
                enabled: !_busy,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _submitCode,
                child: const Text('Confirma'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}
