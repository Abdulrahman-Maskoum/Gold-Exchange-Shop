import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config/routes.dart';
import 'config/themes.dart';
import 'controllers/auth_controller.dart';

class GoldExchangeApp extends StatelessWidget {
  const GoldExchangeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final router = createRouter(auth);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme(),
      routerConfig: router,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
