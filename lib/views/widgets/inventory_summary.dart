import 'package:flutter/material.dart';
import '../../models/inventory_model.dart';

class InventorySummaryCard extends StatelessWidget {
  final InventoryModel inventory;
  const InventorySummaryCard({super.key, required this.inventory});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Inventory',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Rows
            _InvDisplayRow(
              value: inventory.goldGrams.toStringAsFixed(3),
              label: 'Gold',
              icon: Icons.workspace_premium_rounded,
            ),
            const SizedBox(height: 12),
            _InvDisplayRow(
              value: inventory.balanceOf('USD').toStringAsFixed(3),
              label: 'USD',
              icon: Icons.attach_money_rounded,
            ),
            const SizedBox(height: 12),
            _InvDisplayRow(
              value: inventory.balanceOf('EUR').toStringAsFixed(3),
              label: 'EUR',
              icon: Icons.euro_rounded,
            ),
            const SizedBox(height: 12),
            _InvDisplayRow(
              value: inventory.balanceOf('TRY').toStringAsFixed(3),
              label: 'TRY',
              icon: Icons.currency_lira_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _InvDisplayRow extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _InvDisplayRow({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: primary, size: 20),
          ),
          const SizedBox(width: 12),

          // Label
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),

          // Value
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }
}
