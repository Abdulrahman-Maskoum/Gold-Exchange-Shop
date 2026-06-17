import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/gold_api_service.dart';

class PriceCardColors {
  // Gold card colors
  static const Color goldLight = Color(0xFFFFB300);
  static const Color goldDark = Color(0xFFE65100);

  // EUR card colors
  static const Color eurLight = Color.fromARGB(255, 104, 113, 121);
  static const Color eurDark = Color.fromARGB(255, 95, 115, 166);

  // TRY card colors
  static const Color tryLight = Color.fromARGB(255, 6, 175, 138);
  static const Color tryDark = Color.fromARGB(255, 104, 113, 121);

  // EUR → TRY card colors
  static const Color eurToTryLight = Color.fromARGB(255, 104, 113, 121);
  static const Color eurToTryDark = Color.fromARGB(255, 118, 54, 129);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = GoldApiService();
  Future<LivePrices>? _future;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchDisplayPrices();
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    if (!mounted) return;

    setState(() {
      _isRefreshing = true;
    });

    final newFuture = _api.fetchDisplayPrices();

    if (!mounted) return;
    setState(() {
      _future = newFuture;
    });

    await Future.delayed(const Duration(milliseconds: 450));

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isLargeScreen = screenWidth > 1200;

    return RefreshIndicator(
      onRefresh: _refresh,
      color: theme.colorScheme.primary,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isLargeScreen ? 1000 : (isSmallScreen ? double.infinity : 800),
          ),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              isSmallScreen ? 16 : 20,
              isSmallScreen ? 16 : 20,
              isSmallScreen ? 16 : 20,
              24,
            ),
        children: [
          _buildHeaderCard(theme),
          const SizedBox(height: 20),
          FutureBuilder<LivePrices>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(60),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snap.hasError || snap.data == null) {
                return _buildErrorCard(theme);
              }

              final data = snap.data!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildGoldCard(data, theme),
                  const SizedBox(height: 16),
                  _buildCurrencyRow(data, theme),
                  const SizedBox(height: 16),
                  _buildUpdateTime(data.fetchedAt, theme),
                ],
              );
            },
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme) {
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.primary.withOpacity(0.85)],
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Prices',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                /* const SizedBox(height: 6),
                Text(
                  'Display only • Pull to refresh',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.w600,
                  ),
                ), */
              ],
            ),
          ),
          IconButton(
            onPressed: _isRefreshing ? null : _refresh,
            icon: _buildRefreshIcon(_isRefreshing),
            tooltip: 'Refresh',
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(
                Colors.white.withAlpha(51),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshIcon(bool isRefreshing) {
    if (isRefreshing) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    return const Icon(Icons.refresh_rounded, color: Colors.white);
  }

  Widget _buildGoldCard(LivePrices data, ThemeData theme) {
    double? ozTry = data.goldTryPerOz;
    if (ozTry == null &&
        data.goldUsdPerOz != null &&
        (data.fx['TRY'] ?? 0) > 0) {
      ozTry = data.goldUsdPerOz! * data.fx['TRY']!;
    }

    final gram24 = (ozTry != null && ozTry > 0) ? (ozTry / 31.1034768) : null;
    final gram22 = (gram24 != null) ? (gram24 * (22 / 24)) : null;
    final gram21 = (gram24 != null) ? (gram24 * (21 / 24)) : null;

    final hasPrice = gram24 != null && gram24 > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasPrice
              ? [PriceCardColors.goldLight, PriceCardColors.goldDark]
              : [Colors.grey.shade300, Colors.grey.shade400],
        ),
        boxShadow: [
          BoxShadow(
            color: (hasPrice ? Colors.orange : Colors.grey).withOpacity(0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gold',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  (gram24 != null && gram24 > 0)
                      ? '₺${gram24.toStringAsFixed(3)}'
                      : 'N/A',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '24K per gram',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withAlpha(242),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _karatLine(
                        theme: theme,
                        label: '22K',
                        value: gram22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _karatLine(
                        theme: theme,
                        label: '21K',
                        value: gram21,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _karatLine({
    required ThemeData theme,
    required String label,
    required double? value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.2),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.95),
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Text(
            value != null ? '₺${value.toStringAsFixed(3)}' : 'N/A',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyRow(LivePrices data, ThemeData theme) {
    final eur = data.fx['EUR'] ?? 0;
    final tryRate = data.fx['TRY'] ?? 0;
    final eurToTry = data.eurToTry;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCurrencyCard(
                code: 'EUR',
                symbol: '€',
                rate: eur,
                theme: theme,
                light: PriceCardColors.eurLight,
                dark: PriceCardColors.eurDark,
                label: 'USD → EUR',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCurrencyCard(
                code: 'TRY',
                symbol: '₺',
                rate: tryRate,
                theme: theme,
                light: PriceCardColors.tryLight,
                dark: PriceCardColors.tryDark,
                label: 'USD → TRY',
              ),
            ),
          ],
        ),
        if (eurToTry != null && eurToTry > 0) ...[
          const SizedBox(height: 12),
          _buildCurrencyCard(
            code: 'TRY',
            symbol: '₺',
            rate: eurToTry,
            theme: theme,
            light: PriceCardColors.eurToTryLight,
            dark: PriceCardColors.eurToTryDark,
            label: 'EUR → TRY',
          ),
        ],
      ],
    );
  }

  Widget _buildCurrencyCard({
    required String code,
    required String symbol,
    required double rate,
    required ThemeData theme,
    required Color light,
    required Color dark,
    String? label,
  }) {
    final hasRate = rate > 0;
    final displayLabel = label ?? 'USD → $code';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasRate
              ? [light, dark]
              : [Colors.grey.shade300, Colors.grey.shade400],
        ),
        boxShadow: [
          BoxShadow(
            color: (hasRate ? dark : Colors.grey).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                symbol,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            displayLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasRate ? rate.toStringAsFixed(3) : 'N/A',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateTime(DateTime date, ThemeData theme) {
    final formatter = DateFormat('MMM dd, yyyy • HH:mm:ss');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: theme.dividerColor.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.update_rounded,
              color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Updated: ${formatter.format(date)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: Colors.red, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Failed to load prices',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
