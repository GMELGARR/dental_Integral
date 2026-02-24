import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Dental Integral branded logo widget.
/// Used in login, splash and header areas.
class DentalLogo extends StatelessWidget {
  const DentalLogo({
    super.key,
    this.size = 72,
    this.showText = true,
    this.light = false,
  });

  final double size;
  final bool showText;

  /// When true, text is white (for dark/gradient backgrounds).
  final bool light;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: light
                ? null
                : AppColors.primaryGradient,
            color: light ? Colors.white.withValues(alpha: 0.15) : null,
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: light
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Icon(
            Icons.medical_services_rounded,
            size: size * 0.5,
            color: Colors.white,
          ),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.22),
          Text(
            'Dental Integral',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: light ? Colors.white : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}
