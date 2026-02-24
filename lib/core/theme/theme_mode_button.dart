import 'package:flutter/material.dart';

import '../../app/di/service_locator.dart';
import 'theme_controller.dart';

/// Toggle button for light/dark mode.
///
/// When [light] is true, the icon is white (for gradient backgrounds).
class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key, this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) {
    final themeController = getIt<ThemeController>();

    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        final isDark = themeController.themeMode == ThemeMode.dark;
        final iconColor = light
            ? Colors.white.withValues(alpha: 0.8)
            : null;

        return IconButton(
          onPressed: themeController.toggleLightDark,
          tooltip: isDark ? 'Activar modo claro' : 'Activar modo oscuro',
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: iconColor,
          ),
        );
      },
    );
  }
}
