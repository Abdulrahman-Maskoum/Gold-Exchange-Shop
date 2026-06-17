class InventoryModel {
  final double goldGrams;
  final Map<String, double> balances;

  const InventoryModel({
    required this.goldGrams,
    required this.balances,
  });

  factory InventoryModel.empty() {
    return const InventoryModel(
      goldGrams: 0,
      balances: {'USD': 0, 'EUR': 0, 'TRY': 0},
    );
  }

  factory InventoryModel.fromMap(Map<String, dynamic> data) {
    final balancesData = (data['balances'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    double numToDouble(dynamic v) {
      if (v is int) return v.toDouble();
      if (v is double) return v;
      return 0;
    }

    return InventoryModel(
      goldGrams: numToDouble(data['goldGrams']),
      balances: {
        'USD': numToDouble(balancesData['USD']),
        'EUR': numToDouble(balancesData['EUR']),
        'TRY': numToDouble(balancesData['TRY']),
      },
    );
  }

  double balanceOf(String currency) => balances[currency] ?? 0;
}
