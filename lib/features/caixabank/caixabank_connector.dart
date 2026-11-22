import '../../core/bank_connector.dart';
import '../../core/product_balance.dart';
import '../../core/secure_credential_store.dart';
import '../settings/gocardless_settings.dart';
import 'gocardless_client.dart';

const caixaBankRedirectUri = 'allbank://gocardless-callback';
const caixaBankCallbackScheme = 'allbank';

class CaixaBankConnector implements BankConnector {
  CaixaBankConnector({required SecureCredentialStore credentialStore})
    : _store = credentialStore,
      _settings = GoCardlessSettings(credentialStore);

  static const _requisitionIdKey = 'caixabank_requisition_id';
  static const _accountIdsKey = 'caixabank_account_ids';

  final SecureCredentialStore _store;
  final GoCardlessSettings _settings;

  @override
  String get bankId => 'CaixaBank';

  Future<GoCardlessClient> _client() async {
    final credentials = await _settings.read();
    if (credentials == null) {
      throw StateError('GoCardless API credentials are not configured yet.');
    }
    return GoCardlessClient(
      secretId: credentials.secretId,
      secretKey: credentials.secretKey,
    );
  }

  Future<bool> hasApiCredentials() async => (await _settings.read()) != null;

  Future<List<GoCardlessInstitution>> searchInstitutions() async {
    final client = await _client();
    final institutions = await client.listInstitutions(country: 'ES');
    institutions.sort((a, b) => a.name.compareTo(b.name));
    return institutions;
  }

  /// Creates a requisition and returns the link the user must open in a
  /// browser to log in directly on the bank's own site.
  Future<String> startRequisition(GoCardlessInstitution institution) async {
    final client = await _client();
    final requisition = await client.createRequisition(
      institutionId: institution.id,
      redirectUri: caixaBankRedirectUri,
      reference: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    await _store.write(_requisitionIdKey, requisition.id);
    return requisition.link;
  }

  /// Call after the browser redirected back, to confirm the requisition is
  /// linked and persist the resulting account ids.
  Future<bool> completeRequisition() async {
    final requisitionId = await _store.read(_requisitionIdKey);
    if (requisitionId == null) return false;
    final client = await _client();
    final accountIds = await client.getLinkedAccountIds(requisitionId);
    if (accountIds.isEmpty) return false;
    await _store.write(_accountIdsKey, accountIds.join(','));
    return true;
  }

  @override
  Future<bool> isConnected() async {
    final accountIds = await _store.read(_accountIdsKey);
    return accountIds != null && accountIds.isNotEmpty;
  }

  @override
  Future<List<ProductBalance>> fetchBalances() async {
    final accountIdsRaw = await _store.read(_accountIdsKey);
    if (accountIdsRaw == null || accountIdsRaw.isEmpty) {
      throw const BankSessionExpiredException('CaixaBank');
    }
    final client = await _client();
    final now = DateTime.now();
    final results = <ProductBalance>[];
    for (final accountId in accountIdsRaw.split(',')) {
      final name = await client.getAccountDisplayName(accountId);
      final balances = await client.getAccountBalances(accountId);
      if (balances.isEmpty) continue;
      final preferred = balances.firstWhere(
        (b) =>
            b.balanceType == 'interimAvailable' ||
            b.balanceType == 'closingBooked',
        orElse: () => balances.first,
      );
      results.add(
        ProductBalance(
          bankId: bankId,
          category: ProductCategory.accounts,
          label: name,
          amount: preferred.amount,
          currency: preferred.currency,
          updatedAt: now,
        ),
      );
    }
    if (results.isEmpty) {
      throw const BankSessionExpiredException('CaixaBank');
    }
    return results;
  }

  @override
  Future<void> disconnect() async {
    await _store.delete(_requisitionIdKey);
    await _store.delete(_accountIdsKey);
  }
}
