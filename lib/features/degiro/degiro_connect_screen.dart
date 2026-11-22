import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import 'degiro_client.dart';

class DegiroConnectScreen extends ConsumerStatefulWidget {
  const DegiroConnectScreen({super.key});

  @override
  ConsumerState<DegiroConnectScreen> createState() => _DegiroConnectScreenState();
}

class _DegiroConnectScreenState extends ConsumerState<DegiroConnectScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _totpController = TextEditingController();

  bool _busy = false;
  bool _needsTotp = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _totpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final connector = ref.read(degiroConnectorProvider);
      await connector.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        oneTimePassword: _needsTotp ? _totpController.text.trim() : null,
      );
      if (!mounted) return;
      ref.invalidate(connectionStatusProvider('DEGIRO'));
      ref.invalidate(balancesProvider('DEGIRO'));
      Navigator.of(context).pop(true);
    } on DegiroTwoFactorRequiredException {
      if (mounted) setState(() => _needsTotp = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connecta DEGIRO')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Usuari'),
              enabled: !_busy && !_needsTotp,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contrasenya'),
              obscureText: true,
              enabled: !_busy && !_needsTotp,
            ),
            if (_needsTotp) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _totpController,
                decoration: const InputDecoration(
                  labelText: 'Codi de verificació en dos passos',
                ),
                keyboardType: TextInputType.number,
                enabled: !_busy,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_needsTotp ? 'Confirma' : 'Entra'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
