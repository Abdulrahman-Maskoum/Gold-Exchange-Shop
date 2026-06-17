import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/inventory_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/inventory_model.dart';
import '../../models/transaction_model.dart';
import '../../services/firestore_service.dart';
import '../widgets/alert_dialog.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/transaction_tile.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final invCtrl = context.watch<InventoryController>();
    final txCtrl = context.watch<TransactionController>();

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isLargeScreen = screenWidth > 1200;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor.withOpacity(0.03),
            Colors.white,
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isLargeScreen ? 1000 : (isSmallScreen ? double.infinity : 800),
          ),
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 24,
              vertical: isSmallScreen ? 16 : 20,
            ),
        children: [
          StreamBuilder<InventoryModel>(
            stream: invCtrl.stream(),
            builder: (context, invSnap) {
              final inv = invSnap.data ?? InventoryModel.empty();
              return _InventoryEditable(inv: inv);
            },
          ),
          const SizedBox(height: 20),
          _FiltersBar(controller: txCtrl),
          const SizedBox(height: 20),
          StreamBuilder<List<TransactionModel>>(
            stream: txCtrl.stream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final txs = snap.data ?? [];
              if (txs.isEmpty) {
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: txs.map((t) => TransactionTile(tx: t)).toList(),
              );
            },
          ),
        ],
      ),
        ),
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  final TransactionController controller;
  const _FiltersBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<PeriodFilter>(
                value: controller.period,
                decoration: InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today_outlined, color: primaryColor),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: PeriodFilter.today,
                    child: Text('Today'),
                  ),
                  DropdownMenuItem(
                    value: PeriodFilter.week,
                    child: Text('Week'),
                  ),
                  DropdownMenuItem(
                    value: PeriodFilter.month,
                    child: Text('Month'),
                  ),
                  DropdownMenuItem(
                    value: PeriodFilter.year,
                    child: Text('Year'),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  controller.setPeriod(v);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: controller.filter,
                decoration: InputDecoration(
                  labelText: 'Filter',
                  prefixIcon: Icon(Icons.filter_list_rounded, color: primaryColor),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                items: ['ALL', 'Gold', ...AppConstants.currencies]
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  controller.setFilter(v);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryEditable extends StatelessWidget {
  final InventoryModel inv;
  const _InventoryEditable({required this.inv});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 20),
            _InvItem(
              label: 'Gold',
              value: inv.goldGrams.toStringAsFixed(3),
              itemKey: 'Gold',
              icon: Icons.workspace_premium_rounded,
            ),
            const Divider(height: 32),
            _InvItem(
              label: 'USD',
              value: inv.balanceOf('USD').toStringAsFixed(3),
              itemKey: 'USD',
              icon: Icons.attach_money_rounded,
            ),
            const SizedBox(height: 12),
            _InvItem(
              label: 'EUR',
              value: inv.balanceOf('EUR').toStringAsFixed(3),
              itemKey: 'EUR',
              icon: Icons.euro_rounded,
            ),
            const SizedBox(height: 12),
            _InvItem(
              label: 'TRY',
              value: inv.balanceOf('TRY').toStringAsFixed(3),
              itemKey: 'TRY',
              icon: Icons.currency_lira_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _InvItem extends StatelessWidget {
  final String label;
  final String value;
  final String itemKey;
  final IconData icon;
  const _InvItem({
    required this.label,
    required this.value,
    required this.itemKey,
    required this.icon,
  });

  Future<void> _edit(BuildContext context) async {
    final amountCtrl = TextEditingController();
    bool increase = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Edit $label'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Increase')),
                      ButtonSegment(value: false, label: Text('Decrease')),
                    ],
                    selected: {increase},
                    onSelectionChanged: (s) => setState(() => increase = s.first),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;

    final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) {
      if (context.mounted) {
        showAlertDialog(
          context: context,
          message: 'Invalid amount',
          type: AlertType.error,
        );
      }
      return;
    }

    if (!context.mounted) return;
    final ok = await showConfirmDialog(
      context: context,
      title: 'Confirm Adjustment',
      details: [
        Text('Item: $label'),
        Text('Action: ${increase ? 'Increase' : 'Decrease'}'),
        Text('Amount: ${amount.toStringAsFixed(3)}'),
      ],
    );

    if (!ok) return;

    if (!context.mounted) return;
    final uid = context.read<AuthController>().firebaseUser?.uid;
    final firestoreService = context.read<FirestoreService>();
    if (uid == null) return;

    try {
      await firestoreService.adjustInventory(
        uid: uid,
        item: itemKey,
        increase: increase,
        amount: amount,
      );
    } on InsufficientBalanceException {
      if (context.mounted) {
        final itemName = itemKey == 'Gold' ? 'Gold' : itemKey;
        showAlertDialog(
          context: context,
          message: 'Insufficient $itemName balance',
          type: AlertType.error,
        );
      }
    } on ValidationException catch (e) {
      if (context.mounted) {
        showAlertDialog(
          context: context,
          message: e.message,
          type: AlertType.error,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showAlertDialog(
          context: context,
          message: 'Operation failed: ${e.toString()}',
          type: AlertType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Slidable(
      key: ValueKey(itemKey),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _edit(context),
            icon: Icons.edit_rounded,
            label: 'Edit',
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
