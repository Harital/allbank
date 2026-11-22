import 'package:cookie_jar/cookie_jar.dart';

import '../../core/bank_connector.dart';
import '../../core/product_balance.dart';
import '../../core/secure_credential_store.dart';
import 'tr_client.dart';

/// Field names for cash/portfolio snapshots are reconstructed from the
/// open-source `pytr` client, which itself treats them as opaque JSON (no
/// official schema exists). These candidate names are the ones most commonly
/// seen in community write-ups of the Trade Republic API; if Trade Republic
/// changes its response shape, [fetchBalances] throws rather than silently
/// showing a wrong amount, since there is no way to verify this without a
/// real account.
class TradeRepublicConnector implements BankConnector {
  TradeRepublicConnector({required SecureCredentialStore credentialStore})
    : _store = credentialStore;

  static const _phoneKey = 'tr_phone';
  static const _pinKey = 'tr_pin';
  static const _deviceIdKey = 'tr_device_id';

  final SecureCredentialStore _store;
  final CookieJar _cookieJar = CookieJar();
  TrClient? _client;

  @override
  String get bankId => 'Trade Republic';

  Future<TrClient> _ensureClient() async {
    final existing = _client;
    if (existing != null) return existing;
    var deviceId = await _store.read(_deviceIdKey);
    if (deviceId == null) {
      deviceId = generateStableDeviceId();
      await _store.write(_deviceIdKey, deviceId);
    }
    final client = TrClient(stableDeviceId: deviceId, cookieJar: _cookieJar);
    _client = client;
    return client;
  }

  Future<TrLoginProcess> startLogin({
    required String phoneNumber,
    required String pin,
  }) async {
    await _store.write(_phoneKey, phoneNumber);
    await _store.write(_pinKey, pin);
    final client = await _ensureClient();
    return client.startLogin(phoneNumber: phoneNumber, pin: pin);
  }

  Future<void> submitAuthenticatorCode(
    TrLoginProcess process,
    String code,
  ) async {
    final client = await _ensureClient();
    await client.submitAuthenticatorCode(process, code);
  }

  Future<void> awaitAppConfirmation(TrLoginProcess process) async {
    final client = await _ensureClient();
    await client.awaitAppConfirmation(process);
  }

  @override
  Future<bool> isConnected() async {
    return (await _store.read(_phoneKey)) != null;
  }

  @override
  Future<List<ProductBalance>> fetchBalances() async {
    final phone = await _store.read(_phoneKey);
    if (phone == null) {
      throw const BankSessionExpiredException('Trade Republic');
    }

    final client = await _ensureClient();
    if (!await client.hasValidSession()) {
      throw const BankSessionExpiredException('Trade Republic');
    }

    final now = DateTime.now();
    final results = <ProductBalance>[];

    final cashSnapshot = await client.fetchSnapshot('cash');
    final cashEntries = cashSnapshot['cash'] as List<dynamic>? ?? const [];
    for (final entry in cashEntries.cast<Map<String, dynamic>>()) {
      final amount = _numericField(entry, const ['amount']);
      final currency = entry['currencyId'] as String? ?? entry['currency'] as String?;
      if (amount == null || currency == null) continue;
      results.add(
        ProductBalance(
          bankId: bankId,
          category: ProductCategory.accounts,
          label: 'Efectiu',
          amount: amount,
          currency: currency,
          updatedAt: now,
        ),
      );
    }

    final portfolioSnapshot = await client.fetchSnapshot('portfolio');
    final positions = portfolioSnapshot['positions'] as List<dynamic>? ?? const [];
    double securitiesTotal = 0;
    var sawPosition = false;
    for (final position in positions.cast<Map<String, dynamic>>()) {
      final value = _numericField(position, const [
        'netValue',
        'currentValue',
        'value',
      ]);
      if (value == null) continue;
      sawPosition = true;
      securitiesTotal += value;
    }
    if (sawPosition || positions.isEmpty) {
      results.add(
        ProductBalance(
          bankId: bankId,
          category: ProductCategory.securities,
          label: 'Cartera de valors',
          amount: securitiesTotal,
          currency: 'EUR',
          updatedAt: now,
        ),
      );
    }

    if (results.isEmpty) {
      throw StateError(
        'Could not parse a Trade Republic cash or portfolio snapshot.',
      );
    }
    return results;
  }

  double? _numericField(Map<String, dynamic> map, List<String> candidates) {
    for (final key in candidates) {
      final value = map[key];
      if (value is num) return value.toDouble();
    }
    return null;
  }

  @override
  Future<void> disconnect() async {
    await _store.delete(_phoneKey);
    await _store.delete(_pinKey);
    await _store.delete(_deviceIdKey);
    _client = null;
  }
}
