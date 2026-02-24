import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import 'di/service_locator.dart';
import 'router/app_router.dart';

class DentalIntegralApp extends StatelessWidget {
  const DentalIntegralApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = getIt<AppRouter>().router;
    final themeController = getIt<ThemeController>();

    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'Dental Integral',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeController.themeMode,
          routerConfig: router,
        );
      },
    );
  }
}