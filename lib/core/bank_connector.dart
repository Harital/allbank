import 'product_balance.dart';

/// Common contract once a bank is already connected. Each connector exposes
/// its own bank-specific login/2FA methods in addition to this interface --
/// the login flow differs too much between an OAuth redirect (CaixaBank),
/// a phone+PIN+SMS code (Trade Republic) and a username+password+TOTP
/// (DEGIRO) to be unified.
abstract interface class BankConnector {
  String get bankId;

  Future<bool> isConnected();

  Future<List<ProductBalance>> fetchBalances();

  Future<void> disconnect();
}

/// Thrown by [BankConnector.fetchBalances] when the stored session/token is
/// no longer valid and the user must go through the connect flow again.
class BankSessionExpiredException implements Exception {
  const BankSessionExpiredException(this.bankId);

  final String bankId;

  @override
  String toString() => 'BankSessionExpiredException($bankId)';
}
