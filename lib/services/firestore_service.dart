import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/constants.dart';
import '../models/inventory_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';

class InsufficientBalanceException implements Exception {
  final String message;
  InsufficientBalanceException(this.message);
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
}

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _shopRef(String uid) =>
      _db.collection('shops').doc(uid);

  DocumentReference<Map<String, dynamic>> inventoryRef(String uid) =>
      _shopRef(uid).collection('state').doc(AppConstants.inventoryDocId);

  CollectionReference<Map<String, dynamic>> txRef(String uid) =>
      _shopRef(uid).collection('transactions');

  Stream<UserModel?> watchUser(String uid) {
    return _shopRef(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(uid, doc.data() ?? <String, dynamic>{});
    });
  }

  Future<void> updateProfile({
    required String uid,
    required String shopName,
    required String shopAddress,
  }) async {
    await _shopRef(uid).update({
      'shopName': shopName,
      'shopAddress': shopAddress,
    });
  }

  Stream<InventoryModel> watchInventory(String uid) {
    return inventoryRef(uid).snapshots().map((doc) {
      if (!doc.exists) return InventoryModel.empty();
      return InventoryModel.fromMap(doc.data() ?? <String, dynamic>{});
    });
  }

  Stream<List<TransactionModel>> watchTransactions(
    String uid, {
    DateTime? from,
    String? filter,
  }) {
    Query<Map<String, dynamic>> q =
        txRef(uid).orderBy('createdAt', descending: true);
    if (from != null) {
      q = q.where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }

    return q.snapshots().map((snap) {
      final allTxs = snap.docs.map(TransactionModel.fromDoc).toList();

      if (filter == null || filter == 'ALL') {
        return allTxs;
      }

      if (filter == 'Gold') {
        // Filter for gold transactions: gold_sale, gold_purchase, or adjustment with Gold item
        return allTxs.where((tx) {
          if (tx.type == AppConstants.txGoldSale ||
              tx.type == AppConstants.txGoldPurchase) {
            return true;
          }
          if (tx.type == AppConstants.txAdjustment) {
            final item = tx.details['item'] as String?;
            return item == 'Gold';
          }
          return false;
        }).toList();
      }

      // Filter by currency (existing logic)
      if (AppConstants.currencies.contains(filter)) {
        return allTxs
            .where((tx) => tx.currenciesInvolved.contains(filter))
            .toList();
      }

      return allTxs;
    });
  }

  Future<void> goldSale({
    required String uid,
    required String receivedCurrency,
    required double goldGrams,
    required double gramPrice,
    required String operationDescription,
  }) async {
    _requireCurrency(receivedCurrency);
    _requirePositive(goldGrams, 'Gold grams');
    _requirePositive(gramPrice, 'Gram price');

    final total = goldGrams * gramPrice;
    final inv = inventoryRef(uid);
    final txDoc = txRef(uid).doc();

    await _db.runTransaction((txn) async {
      final invSnap = await txn.get(inv);
      final invData =
          InventoryModel.fromMap(invSnap.data() ?? <String, dynamic>{});

      if (invData.goldGrams < goldGrams) {
        throw InsufficientBalanceException('Insufficient gold inventory');
      }

      final newGold = invData.goldGrams - goldGrams;
      final newCur = invData.balanceOf(receivedCurrency) + total;

      txn.update(inv, {
        'goldGrams': newGold,
        'balances.$receivedCurrency': newCur,
      });

      txn.set(txDoc, {
        'type': AppConstants.txGoldSale,
        'description': operationDescription,
        'details': {
          'receivedCurrency': receivedCurrency,
          'goldGrams': goldGrams,
          'gramPrice': gramPrice,
          'total': total,
        },
        'currenciesInvolved': [receivedCurrency],
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> goldPurchase({
    required String uid,
    required String paidCurrency,
    required double goldGrams,
    required double gramPrice,
    required String operationDescription,
  }) async {
    _requireCurrency(paidCurrency);
    _requirePositive(goldGrams, 'Gold grams');
    _requirePositive(gramPrice, 'Gram price');

    final total = goldGrams * gramPrice;
    final inv = inventoryRef(uid);
    final txDoc = txRef(uid).doc();

    await _db.runTransaction((txn) async {
      final invSnap = await txn.get(inv);
      final invData =
          InventoryModel.fromMap(invSnap.data() ?? <String, dynamic>{});

      final curBal = invData.balanceOf(paidCurrency);
      if (curBal < total) {
        throw InsufficientBalanceException(
            'Insufficient $paidCurrency balance');
      }

      final newCur = curBal - total;
      final newGold = invData.goldGrams + goldGrams;

      txn.update(inv, {
        'goldGrams': newGold,
        'balances.$paidCurrency': newCur,
      });

      txn.set(txDoc, {
        'type': AppConstants.txGoldPurchase,
        'description': operationDescription,
        'details': {
          'paidCurrency': paidCurrency,
          'goldGrams': goldGrams,
          'gramPrice': gramPrice,
          'total': total,
        },
        'currenciesInvolved': [paidCurrency],
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> currencyExchange({
    required String uid,
    required String fromCurrency, // DECREASE
    required String toCurrency, // INCREASE
    required double amountFrom, // deducted from From
    required double amountTo, // received in To
    required double rateUsed, // 1 From = rateUsed To
    required String operationDescription,
  }) async {
    _requireCurrency(fromCurrency);
    _requireCurrency(toCurrency);

    if (fromCurrency == toCurrency) {
      throw ValidationException('From and To currencies must be different');
    }

    _requirePositive(amountFrom, 'Amount to deduct');
    _requirePositive(amountTo, 'Amount received');
    _requirePositive(rateUsed, 'Rate');

    final inv = inventoryRef(uid);
    final txDoc = txRef(uid).doc();

    await _db.runTransaction((txn) async {
      final invSnap = await txn.get(inv);
      final invData =
          InventoryModel.fromMap(invSnap.data() ?? <String, dynamic>{});

      final fromBal = invData.balanceOf(fromCurrency);
      if (fromBal < amountFrom) {
        throw InsufficientBalanceException(
            'Insufficient $fromCurrency balance');
      }

      final newFrom = fromBal - amountFrom;
      final newTo = invData.balanceOf(toCurrency) + amountTo;

      txn.update(inv, {
        'balances.$fromCurrency': newFrom,
        'balances.$toCurrency': newTo,
      });

      txn.set(txDoc, {
        'type': AppConstants.txCurrencyExchange,
        'description': operationDescription,
        'details': {
          'fromCurrency': fromCurrency,
          'toCurrency': toCurrency,
          'amountFrom': amountFrom,
          'amountTo': amountTo,
          'rateUsed': rateUsed,
        },
        'currenciesInvolved': [fromCurrency, toCurrency],
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> adjustInventory({
    required String uid,
    required String item, // 'Gold' or currency code
    required bool increase,
    required double amount,
  }) async {
    if (item != 'Gold') {
      _requireCurrency(item);
    }
    _requirePositive(amount, 'Amount');

    final inv = inventoryRef(uid);
    final txDoc = txRef(uid).doc();

    await _db.runTransaction((txn) async {
      final invSnap = await txn.get(inv);
      final invData =
          InventoryModel.fromMap(invSnap.data() ?? <String, dynamic>{});

      if (item == 'Gold') {
        final newGold = increase
            ? (invData.goldGrams + amount)
            : (invData.goldGrams - amount);
        if (newGold < 0) {
          throw InsufficientBalanceException('Insufficient Gold balance');
        }

        txn.update(inv, {'goldGrams': newGold});
      } else {
        final current = invData.balanceOf(item);
        final newBal = increase ? (current + amount) : (current - amount);
        if (newBal < 0) {
          throw InsufficientBalanceException('Insufficient $item balance');
        }

        txn.update(inv, {'balances.$item': newBal});
      }

      final fixedDesc = 'Edit Inventory ${item == 'Gold' ? 'Gold' : item}';

      txn.set(txDoc, {
        'type': AppConstants.txAdjustment,
        'description': fixedDesc,
        'details': {
          'item': item,
          'increase': increase,
          'amount': amount,
        },
        'currenciesInvolved': item == 'Gold' ? [] : [item],
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  void _requireCurrency(String currency) {
    if (!AppConstants.currencies.contains(currency)) {
      throw ValidationException('Invalid currency: $currency');
    }
  }

  void _requirePositive(double value, String label) {
    if (value <= 0) {
      throw ValidationException('$label must be > 0');
    }
  }
}
