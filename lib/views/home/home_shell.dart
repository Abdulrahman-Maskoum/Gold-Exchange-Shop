import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../currency/currency_exchange_screen.dart';
import '../gold/gold_purchases_screen.dart';
import '../gold/gold_sales_screen.dart';
import '../transactions/transactions_screen.dart';
import 'home_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _titles = [
    'Home',
    'Gold Sales',
    'Gold Purchases',
    'Currency Exchange',
    'Transactions',
  ];

  static const _icons = [
    Icons.home_rounded,
    Icons.sell_rounded,
    Icons.shopping_cart_rounded,
    Icons.swap_horiz_rounded,
    Icons.receipt_long_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final auth = context.watch<AuthController>();
    final username = auth.profile?.username ?? '';

    final pages = const [
      HomeScreen(),
      GoldSalesScreen(),
      GoldPurchasesScreen(),
      CurrencyExchangeScreen(),
      TransactionsScreen(),
    ];

    return Scaffold(
      appBar: _buildAppBar(colorScheme, theme, username),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: _buildBottomNav(context, colorScheme),
    );
  }

  PreferredSizeWidget _buildAppBar(
    ColorScheme colorScheme,
    ThemeData theme,
    String username,
  ) {
    final title = _titles[_index];

    return AppBar(
      elevation: 0,
      backgroundColor: colorScheme.primary,
      foregroundColor: Colors.white,
      centerTitle: false,
      titleSpacing: 12,
      title: Row(
        children: [
          Icon(_icons[_index], color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (_index == 0)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withOpacity(0.25)),
                  ),
                  backgroundColor: Colors.white.withOpacity(0.12),
                ),
                onPressed: () => context.go('/profile'),
                icon: const Icon(Icons.person_rounded, size: 18),
                label: Text(
                  username.isEmpty ? 'Profile' : username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        IconButton(
          tooltip: 'Logout',
          icon: const Icon(Icons.logout_rounded),
          onPressed: () async {
            final auth = context.read<AuthController>();
            await auth.signOut();

            if (!mounted) return;
            context.go('/login');
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context, ColorScheme colorScheme) {
    final primaryColor = colorScheme.primary;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: primaryColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: Colors.transparent,
              indicatorColor: Colors.white.withOpacity(0.18),
              labelTextStyle: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  );
                }
                return TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.75),
                );
              }),
              iconTheme: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return const IconThemeData(
                    color: Colors.white,
                    size: 24,
                  );
                }
                return IconThemeData(
                  color: Colors.white.withOpacity(0.75),
                  size: 24,
                );
              }),
            ),
          ),
          child: NavigationBar(
            height: 70,
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            backgroundColor: Colors.transparent,
            indicatorColor: Colors.white.withOpacity(0.18),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.sell_outlined),
                selectedIcon: Icon(Icons.sell_rounded),
                label: 'Sales',
              ),
              NavigationDestination(
                icon: Icon(Icons.shopping_cart_outlined),
                selectedIcon: Icon(Icons.shopping_cart_rounded),
                label: 'Purchases',
              ),
              NavigationDestination(
                icon: Icon(Icons.swap_horiz_outlined),
                selectedIcon: Icon(Icons.swap_horiz_rounded),
                label: 'Exchange',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Transactions',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
