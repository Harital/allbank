enum ProductCategory { accounts, funds, pensions, securities, crypto, loans, cards }

class ProductBalance {
  const ProductBalance({
    required this.bankId,
    required this.category,
    required this.label,
    required this.amount,
    required this.currency,
    required this.updatedAt,
  });

  final String bankId;
  final ProductCategory category;
  final String label;
  final double amount;
  final String currency;
  final DateTime updatedAt;
}
