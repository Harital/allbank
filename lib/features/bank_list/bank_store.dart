import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class BankStore {
  Future<List<String>> read();
  Future<void> write(List<String> names);
}

class SecureBankStore implements BankStore {
  static const _key = 'selected_banks';
  final _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
  );

  @override
  Future<List<String>> read() async {
    final value = await _storage.read(key: _key);
    if (value == null) return [];
    final decoded = jsonDecode(value);
    if (decoded is! List || decoded.any((item) => item is! String)) {
      throw const FormatException('Invalid bank list');
    }
    return decoded.cast<String>();
  }

  @override
  Future<void> write(List<String> names) =>
      _storage.write(key: _key, value: jsonEncode(names));
}
