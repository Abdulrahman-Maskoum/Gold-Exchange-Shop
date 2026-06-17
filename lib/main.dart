import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'controllers/auth_controller.dart';
import 'controllers/inventory_controller.dart';
import 'controllers/transaction_controller.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authService = AuthService();
  final firestoreService = FirestoreService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => AuthController(authService, firestoreService)),
        Provider.value(value: firestoreService),
        ChangeNotifierProxyProvider<AuthController, InventoryController>(
          create: (_) => InventoryController(firestoreService),
          update: (_, auth, inv) {
            inv!.setUid(auth.firebaseUser?.uid);
            return inv;
          },
        ),
        ChangeNotifierProxyProvider<AuthController, TransactionController>(
          create: (_) => TransactionController(firestoreService),
          update: (_, auth, tx) {
            tx!.setUid(auth.firebaseUser?.uid);
            return tx;
          },
        ),
      ],
      child: const GoldExchangeApp(),
    ),
  );
}
