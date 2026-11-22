import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Generic encrypted key/value store used by every bank connector to persist
/// tokens, session cookies and (for DEGIRO/Trade Republic) credentials
/// locally. Nothing written here ever leaves the device: it is backed by the
/// iOS Keychain / Android Keystore, the same mechanism [SecureBankStore] in
/// `main.dart` already uses for the selected-bank list.
abstract interface class SecureCredentialStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

class FlutterSecureCredentialStore implements SecureCredentialStore {
  const FlutterSecureCredentialStore();

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
