const banks = [
  'CaixaBank',
  'Revolut',
  'ING',
  'MyInvestor',
  'Pibank',
  'Trade Republic',
  'DEGIRO',
  'Raisin',
];

const productCategories = [
  'accounts',
  'funds',
  'pensions',
  'securities',
  'crypto',
  'loans',
  'cards',
];

/// Banks with a real connector (see providers/providers.dart). Any other
/// entry in [banks] has no automated connection yet -- see README.md.
const connectableBankIds = {'CaixaBank', 'Trade Republic', 'DEGIRO'};
