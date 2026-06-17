import 'dart:convert';
import 'package:http/http.dart' as http;

class LivePrices {
  final DateTime fetchedAt;

  final double? goldUsdPerOz;
  final double? goldTryPerOz;
  final double? goldTryPerGram;

  final double? gold24;
  final double? gold22;
  final double? gold21;

  final Map<String, double> fx;
  final double? eurToTry;

  LivePrices({
    required this.fetchedAt,
    required this.goldUsdPerOz,
    this.goldTryPerOz,
    this.goldTryPerGram,
    this.gold24,
    this.gold22,
    this.gold21,
    required this.fx,
    this.eurToTry,
  });
}

class GoldApiService {
  Future<double?> _fetchGoldUsdPerOzYahoo() async {
    try {
      final res = await http
          .get(Uri.parse(
              'https://query1.finance.yahoo.com/v8/finance/chart/GC=F?range=1d&interval=1m'))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        return null;
      }

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final result = (json['chart']?['result'] as List?)?.first;
      final meta = result?['meta'] as Map<String, dynamic>?;
      final price = meta?['regularMarketPrice'];

      if (price is num && price > 0) {
        return price.toDouble();
      }
    } catch (_) {}
    return null;
  }

  Future<LivePrices> fetchDisplayPrices() async {
    final now = DateTime.now();

    try {
      await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 10));
    } catch (_) {}

    final goldPriceUsdPerOz = await _fetchGoldUsdPerOzYahoo();

    Map<String, double> fx = {'USD': 1.0, 'EUR': 0, 'TRY': 0};

    try {
      final fxRes = await http
          .get(Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'))
          .timeout(const Duration(seconds: 10));

      if (fxRes.statusCode == 200) {
        final json = jsonDecode(fxRes.body) as Map<String, dynamic>;
        final rates = json['rates'] as Map<String, dynamic>?;
        if (rates != null) {
          fx = {
            'USD': 1.0,
            'EUR': (rates['EUR'] as num?)?.toDouble() ?? 0,
            'TRY': (rates['TRY'] as num?)?.toDouble() ?? 0,
          };
        }
      }
    } catch (_) {}

    double? eurToTry;
    if (fx['EUR']! > 0 && fx['TRY']! > 0) {
      eurToTry = fx['TRY']! / fx['EUR']!;
    }

    double? goldTryPerOz;
    if (goldPriceUsdPerOz != null && fx['TRY']! > 0) {
      goldTryPerOz = goldPriceUsdPerOz * fx['TRY']!;
    }

    double? goldTryPerGram;
    double? gold24;
    double? gold22;
    double? gold21;

    if (goldTryPerOz != null) {
      goldTryPerGram = goldTryPerOz / 31.1034768;
    }

    return LivePrices(
      fetchedAt: now,
      goldUsdPerOz: goldPriceUsdPerOz,
      goldTryPerOz: goldTryPerOz,
      goldTryPerGram: goldTryPerGram,
      gold24: gold24,
      gold22: gold22,
      gold21: gold21,
      fx: fx,
      eurToTry: eurToTry,
    );
  }
}
