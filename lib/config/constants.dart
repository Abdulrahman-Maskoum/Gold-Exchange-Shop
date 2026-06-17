class AppConstants {
  static const List<String> currencies = ['USD', 'EUR', 'TRY'];

  static const String inventoryDocId = 'inventory';

  // Transaction types
  static const String txGoldSale = 'gold_sale';
  static const String txGoldPurchase = 'gold_purchase';
  static const String txCurrencyExchange = 'currency_exchange';
  static const String txAdjustment = 'Edit Inventory';
}

String normalizeUsername(String username) {
  return username.trim().toLowerCase();
}
