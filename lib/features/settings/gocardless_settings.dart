import '../../core/secure_credential_store.dart';

typedef GoCardlessCredentials = ({String secretId, String secretKey});

/// Stores the user's own GoCardless Bank Account Data API credentials.
/// These are *the app's* API keys (obtained by the user creating their own
/// free account at https://bankaccountdata.gocardless.com), never a bank
/// password -- the bank password is only ever entered on the bank's own
/// login page during the requisition flow.
class GoCardlessSettings {
  GoCardlessSettings(this._store);

  final SecureCredentialStore _store;

  static const _secretIdKey = 'gocardless_secret_id';
  static const _secretKeyKey = 'gocardless_secret_key';

  Future<GoCardlessCredentials?> read() async {
    final id = await _store.read(_secretIdKey);
    final key = await _store.read(_secretKeyKey);
    if (id == null || key == null || id.isEmpty || key.isEmpty) return null;
    return (secretId: id, secretKey: key);
  }

  Future<void> save({required String secretId, required String secretKey}) async {
    await _store.write(_secretIdKey, secretId);
    await _store.write(_secretKeyKey, secretKey);
  }

  Future<void> clear() async {
    await _store.delete(_secretIdKey);
    await _store.delete(_secretKeyKey);
  }
}
