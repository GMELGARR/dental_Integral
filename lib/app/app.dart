import 'package:flutter/material.dart';

import 'di/service_locator.dart';
import 'router/app_router.dart';

class DentalIntegralApp extends StatelessWidget {
  const DentalIntegralApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = getIt<AppRouter>().router;

    return MaterialApp.router(
      title: 'Dental Integral',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
      ),
      routerConfig: router,
    );
  }
}