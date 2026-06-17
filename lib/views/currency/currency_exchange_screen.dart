import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/inventory_controller.dart';
import '../../models/inventory_model.dart';
import '../../services/firestore_service.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/inventory_summary.dart';

class CurrencyExchangeScreen extends StatefulWidget {
  const CurrencyExchangeScreen({super.key});

  @override
  State<CurrencyExchangeScreen> createState() => _CurrencyExchangeScreenState();
}

class _CurrencyExchangeScreenState extends State<CurrencyExchangeScreen> {
  final _formKey = GlobalKey<FormState>();
  String _from = AppConstants.currencies.first;
  String _to = AppConstants.currencies[1];
  String? _rateBaseFrom;
  String? _rateBaseTo;
  final _amount = TextEditingController();
  final _rate = TextEditingController();
  final _desc = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _rateBaseFrom = _from;
    _rateBaseTo = _to;
  }

  @override
  void dispose() {
    _amount.dispose();
    _rate.dispose();
    _desc.dispose();
    super.dispose();
  }

  double _parse(String s) => double.tryParse(s.replaceAll(',', '.')) ?? 0;

  void _updateBaseRate() {
    // عند تغيير العملات يدوياً، اعتبر أن المستخدم عرّف زوج جديد
    _rateBaseFrom = _from;
    _rateBaseTo = _to;
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _from;
      _from = _to;
      _to = temp;
      // عند swap، لا تغير الرقم المدخل
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = _parse(_amount.text);
    final baseRate = _parse(_rate.text);

    // حساب rateUsed بناءً على الاتجاه
    final isBaseDirection = (_from == _rateBaseFrom && _to == _rateBaseTo);
    final rateUsed = isBaseDirection ? baseRate : (1 / baseRate);

    final amountTotal = amount * rateUsed;

    final ok = await showConfirmDialog(
      context: context,
      title: 'Confirm Exchange',
      details: [
        Text('From: $_from'),
        Text('To: $_to'),
        Text('Amount: ${amount.toStringAsFixed(2)} $_from'),
        Text('Rate used: 1 $_from = ${rateUsed.toStringAsFixed(3)} $_to'),
        Text('Amount Total: ${amountTotal.toStringAsFixed(2)} $_to'),
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
      await firestoreService.currencyExchange(
        uid: uid,
        fromCurrency: _from,
        toCurrency: _to,
        amountFrom: amount,
        amountTo: amountTotal,
        rateUsed: rateUsed,
        operationDescription: _desc.text.trim(),
      );
      if (mounted) {
        _amount.clear();
        _rate.clear();
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
                                Icons.swap_horiz_rounded,
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
                                    'Currency Exchange',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                  Text(
                                    'Exchange between currencies',
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

                        // From/To Currencies
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _from,
                                decoration: InputDecoration(
                                  labelText: 'From',
                                  prefixIcon: Icon(Icons.arrow_downward_rounded,
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
                                    borderSide: BorderSide(
                                        color: primaryColor, width: 2),
                                  ),
                                ),
                                items: AppConstants.currencies
                                    .map((c) => DropdownMenuItem(
                                        value: c, child: Text(c)))
                                    .toList(),
                                onChanged: (v) {
                                  setState(() {
                                    _from = v ?? _from;
                                    _updateBaseRate();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _swapCurrencies,
                              icon: Icon(Icons.swap_horiz_rounded,
                                  color: primaryColor),
                              style: IconButton.styleFrom(
                                backgroundColor: primaryColor.withOpacity(0.1),
                                padding: const EdgeInsets.all(12),
                              ),
                              tooltip: 'Swap currencies',
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _to,
                                decoration: InputDecoration(
                                  labelText: 'To',
                                  prefixIcon: Icon(Icons.arrow_upward_rounded,
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
                                    borderSide: BorderSide(
                                        color: primaryColor, width: 2),
                                  ),
                                ),
                                items: AppConstants.currencies
                                    .map((c) => DropdownMenuItem(
                                        value: c, child: Text(c)))
                                    .toList(),
                                onChanged: (v) {
                                  setState(() {
                                    _to = v ?? _to;
                                    _updateBaseRate();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Amount (in From currency)
                        TextFormField(
                          key: ValueKey('amount_$_from'),
                          controller: _amount,
                          decoration: InputDecoration(
                            labelText: 'Amount (in $_from)',
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

                        // Rate
                        TextFormField(
                          controller: _rate,
                          decoration: InputDecoration(
                            labelText:
                                'Rate (1 ${_rateBaseFrom ?? _from} = ? ${_rateBaseTo ?? _to})',
                            prefixIcon: Icon(Icons.swap_horiz_rounded,
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
                                  'Confirm Exchange',
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
