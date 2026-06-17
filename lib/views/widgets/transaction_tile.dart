import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  const TransactionTile({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    final dt = tx.createdAt?.toDate();
    final dateText = dt == null ? '-' : DateFormat('yyyy-MM-dd HH:mm').format(dt);

    return Card(
      child: ListTile(
        title: Text(tx.description.isEmpty ? tx.type : tx.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${tx.type}'),
            const SizedBox(height: 4),
            Text(_detailsToText(tx.details)),
            const SizedBox(height: 4),
            Text(dateText),
          ],
        ),
      ),
    );
  }

  String _detailsToText(Map<String, dynamic> details) {
    if (details.isEmpty) return '';
    final parts = <String>[];
    details.forEach((k, v) {
      String formattedValue;
      if (v is num) {
        formattedValue = v.toStringAsFixed(3);
      } else {
        formattedValue = v.toString();
      }
      parts.add('$k: $formattedValue');
    });
    return parts.join(' | ');
  }
}
