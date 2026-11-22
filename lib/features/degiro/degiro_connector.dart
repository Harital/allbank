import '../../core/bank_connector.dart';
import '../../core/product_balance.dart';
import '../../core/secure_credential_store.dart';
import 'degiro_client.dart';

class DegiroConnector implements BankConnector {
  DegiroConnector({required SecureCredentialStore credentialStore})
    : _store = credentialStore;

  static const _usernameKey = 'degiro_username';
  static const _passwordKey = 'degiro_password';

  final SecureCredentialStore _store;
  DegiroClient? _client;
  String? _sessionId;
  int? _accountId;

  @override
  String get bankId => 'DEGIRO';

  DegiroClient _ensureClient() => _client ??= DegiroClient();

  /// Throws [DegiroTwoFactorRequiredException] if the account has 2FA
  /// enabled and [oneTimePassword] was not provided.
  Future<void> login({
    required String username,
    required String password,
    String? oneTimePassword,
  }) async {
    final client = _ensureClient();
    final sessionId = await client.login(
      username: username,
      password: password,
      oneTimePassword: oneTimePassword,
    );
    _sessionId = sessionId;
    _accountId = await client.getAccountId(sessionId);
    await _store.write(_usernameKey, username);
    await _store.write(_passwordKey, password);
  }

  @override
  Future<bool> isConnected() async {
    return (await _store.read(_usernameKey)) != null;
  }

  @override
  Future<List<ProductBalance>> fetchBalances() async {
    final username = await _store.read(_usernameKey);
    if (username == null || _sessionId == null || _accountId == null) {
      throw const BankSessionExpiredException('DEGIRO');
    }

    final client = _ensureClient();
    final Map<String, dynamic> update;
    try {
      update = await client.fetchUpdate(
        sessionId: _sessionId!,
        accountId: _accountId!,
      );
    } catch (_) {
      throw const BankSessionExpiredException('DEGIRO');
    }

    final now = DateTime.now();
    final results = <ProductBalance>[];

    final cashFunds = update['cashFunds'] as Map<String, dynamic>? ?? const {};
    for (final entry in cashFunds.values) {
      if (entry is! Map) continue;
      final amount = _numericField(entry, const ['value']);
      final currency = entry['currencyCode'] as String?;
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

    final portfolio = update['portfolio'] as Map<String, dynamic>? ?? const {};
    double securitiesTotal = 0;
    var sawPosition = false;
    for (final entry in portfolio.values) {
      if (entry is! Map) continue;
      final positionType = entry['positionType'] as String?;
      if (positionType != null && positionType != 'PRODUCT') continue;
      final value = _numericField(entry, const ['value']);
      if (value == null) continue;
      sawPosition = true;
      securitiesTotal += value;
    }
    if (sawPosition || portfolio.isEmpty) {
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
      throw StateError('Could not parse a DEGIRO cash or portfolio snapshot.');
    }
    return results;
  }

  double? _numericField(Map entry, List<String> candidates) {
    for (final key in candidates) {
      final value = entry[key];
      if (value is num) return value.toDouble();
    }
    return null;
  }

  @override
  Future<void> disconnect() async {
    await _store.delete(_usernameKey);
    await _store.delete(_passwordKey);
    _client = null;
    _sessionId = null;
    _accountId = null;
  }
}
