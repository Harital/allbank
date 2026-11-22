import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import 'gocardless_settings.dart';

class GoCardlessSettingsScreen extends ConsumerStatefulWidget {
  const GoCardlessSettingsScreen({super.key});

  @override
  ConsumerState<GoCardlessSettingsScreen> createState() =>
      _GoCardlessSettingsScreenState();
}

class _GoCardlessSettingsScreenState
    extends ConsumerState<GoCardlessSettingsScreen> {
  final _secretIdController = TextEditingController();
  final _secretKeyController = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = GoCardlessSettings(ref.read(secureCredentialStoreProvider));
    final credentials = await settings.read();
    if (!mounted) return;
    setState(() {
      _secretIdController.text = credentials?.secretId ?? '';
      _secretKeyController.text = credentials?.secretKey ?? '';
      _loading = false;
    });
  }

  @override
  void dispose() {
    _secretIdController.dispose();
    _secretKeyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final settings = GoCardlessSettings(ref.read(secureCredentialStoreProvider));
    await settings.save(
      secretId: _secretIdController.text.trim(),
      secretKey: _secretKeyController.text.trim(),
    );
    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustos de GoCardless')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Crea un compte gratuït a bankaccountdata.gocardless.com '
                    'i enganxa aquí les teves pròpies claus d\'API. No són la '
                    'contrasenya de cap banc.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _secretIdController,
                    decoration: const InputDecoration(labelText: 'Secret ID'),
                    enabled: !_saving,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _secretKeyController,
                    decoration: const InputDecoration(labelText: 'Secret Key'),
                    obscureText: true,
                    enabled: !_saving,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: const Text('Desa'),
                  ),
                ],
              ),
            ),
    );
  }
}
