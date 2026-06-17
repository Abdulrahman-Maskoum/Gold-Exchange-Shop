import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String type;
  final String description;
  final Map<String, dynamic> details;
  final Timestamp? createdAt;
  final List<String> currenciesInvolved;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.description,
    required this.details,
    required this.createdAt,
    required this.currenciesInvolved,
  });

  factory TransactionModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return TransactionModel(
      id: doc.id,
      type: (data['type'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      details: (data['details'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      createdAt: data['createdAt'] as Timestamp?,
      currenciesInvolved: (data['currenciesInvolved'] as List?)?.whereType<String>().toList() ?? const [],
    );
  }
}
