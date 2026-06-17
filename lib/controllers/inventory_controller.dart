import 'package:flutter/foundation.dart';

import '../models/inventory_model.dart';
import '../services/firestore_service.dart';

class InventoryController extends ChangeNotifier {
  final FirestoreService _firestore;
  String? _uid;

  InventoryController(this._firestore);

  void setUid(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    notifyListeners();
  }

  Stream<InventoryModel> stream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _firestore.watchInventory(uid);
  }
}
