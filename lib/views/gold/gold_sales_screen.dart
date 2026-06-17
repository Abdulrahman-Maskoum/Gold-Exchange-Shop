import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/inventory_controller.dart';
import '../../models/inventory_model.dart';
import '../../services/firestore_service.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/inventory_summary.dart';

class GoldSalesScreen extends StatefulWidget {
  const GoldSalesScreen({super.key});

  @override
  State<GoldSalesScreen> createState() => _GoldSalesScreenState();
}

class _GoldSalesScreenState extends State<GoldSalesScreen> {
  final _formKey = GlobalKey<FormState>();
  String _currency = AppConstants.currencies.first;
  final _grams = TextEditingController();
  final _price = TextEditingController();
  final _desc = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _grams.dispose();
    _price.dispose();
    _desc.dispose();
    super.dispose();
  }

  double _parse(String s) => double.tryParse(s.replaceAll(',', '.')) ?? 0;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final grams = _parse(_grams.text);
    final price = _parse(_price.text);
    final total = grams * price;

    final ok = await showConfirmDialog(
      context: context,
      title: 'Confirm Gold Sale',
      details: [
        Text('Received currency: $_currency'),
        Text('Gold grams: ${grams.toStringAsFixed(3)}'),
        Text('Gram price: ${price.toStringAsFixed(2)}'),
        Text('Total: ${total.toStringAsFixed(2)} $_currency'),
        const SizedBox(height: 8),
        Text('Description: ${_desc.text.trim()}'),
      ],
    );

    if (!ok) return;

    if (!mounted) return;
    setState(() => _loading = true);
    final uid = context.read<AuthController>().firebaseUser?.uid;
    final firestoreService = context.read<FirestoreService>();
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      await firestoreService.goldSale(
        uid: uid,
        receivedCurrency: _currency,
        goldGrams: grams,
        gramPrice: price,
        operationDescription: _desc.text.trim(),
      );
      if (mounted) {
        _grams.clear();
        _price.clear();
        _desc.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } on ValidationException catch (e) {
      _alert(e.message);
    } on InsufficientBalanceException catch (e) {
      _alert(e.message);
    } catch (_) {
      _alert('Operation failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _alert(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Alert'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final invCtrl = context.watch<InventoryController>();

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
      child: StreamBuilder<InventoryModel>(
        stream: invCtrl.stream(),
        builder: (context, snap) {
          final inv = snap.data ?? InventoryModel.empty();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              InventorySummaryCard(inventory: inv),
              const SizedBox(height: 24),

              // Form Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.sell_rounded,
                                color: primaryColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gold Sale',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                  Text(
                                    'Sell gold and receive currency',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Currency Dropdown
                        DropdownButtonFormField<String>(
                          value: _currency,
                          decoration: InputDecoration(
                            labelText: 'Received currency',
                            prefixIcon: Icon(Icons.currency_exchange_rounded,
                                color: primaryColor),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: primaryColor, width: 2),
                            ),
                          ),
                          items: AppConstants.currencies
                              .map((c) =>
                                  DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _currency = v ?? _currency),
                        ),
                        const SizedBox(height: 20),

                        // Gold Grams
                        TextFormField(
                          controller: _grams,
                          decoration: InputDecoration(
                            labelText: 'Gold grams',
                            prefixIcon: Icon(Icons.workspace_premium_rounded,
                                color: primaryColor),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: primaryColor, width: 2),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              (_parse(v ?? '') <= 0) ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),

                        // Gram Price
                        TextFormField(
                          controller: _price,
                          decoration: InputDecoration(
                            labelText: 'Gram price',
                            prefixIcon: Icon(Icons.attach_money_rounded,
                                color: primaryColor),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: primaryColor, width: 2),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              (_parse(v ?? '') <= 0) ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),

                        // Description
                        TextFormField(
                          controller: _desc,
                          decoration: InputDecoration(
                            labelText: 'Operation description',
                            prefixIcon: Icon(Icons.description_outlined,
                                color: primaryColor),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: primaryColor, width: 2),
                            ),
                          ),
                          maxLines: 3,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 32),

                        // Submit Button
                        FilledButton(
                          onPressed: _loading ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Confirm Sale',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
