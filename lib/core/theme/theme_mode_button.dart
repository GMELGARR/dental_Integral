import 'package:flutter/material.dart';

import '../../app/di/service_locator.dart';
import 'theme_controller.dart';

class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = getIt<ThemeController>();

    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        final isDark = themeController.themeMode == ThemeMode.dark;
        return IconButton(
          onPressed: themeController.toggleLightDark,
          tooltip: isDark ? 'Activar modo claro' : 'Activar modo oscuro',
          icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
        );
      },
    );
  }
}
