import 'package:flutter/foundation.dart';

import '../models/transaction_model.dart';
import '../services/firestore_service.dart';

enum PeriodFilter { today, week, month, year }

class TransactionController extends ChangeNotifier {
  final FirestoreService _firestore;

  String? _uid;
  PeriodFilter period = PeriodFilter.month;
  String filter = 'ALL';

  TransactionController(this._firestore);

  void setUid(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    notifyListeners();
  }

  void setPeriod(PeriodFilter p) {
    period = p;
    notifyListeners();
  }

  void setFilter(String f) {
    filter = f;
    notifyListeners();
  }

  DateTime get _startDate {
    final now = DateTime.now();
    switch (period) {
      case PeriodFilter.today:
        return DateTime(now.year, now.month, now.day);
      case PeriodFilter.week:
        return now.subtract(const Duration(days: 7));
      case PeriodFilter.month:
        return DateTime(now.year, now.month, 1);
      case PeriodFilter.year:
        return DateTime(now.year, 1, 1);
    }
  }

  Stream<List<TransactionModel>> stream() {
    final uid = _uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return _firestore.watchTransactions(uid, from: _startDate, filter: filter);
  }
}
