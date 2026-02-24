import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Decorative gradient header used at the top of pages.
/// Includes a curved bottom edge and optional child overlay.
class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.child,
    this.height = 220,
    this.showPattern = true,
  });

  final Widget child;
  final double height;
  final bool showPattern;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // ── Gradient background ───────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppColors.darkGradient
                    : AppColors.primaryGradient,
              ),
            ),
          ),

          // ── Decorative circles ────────────────────────────
          if (showPattern) ...[
            Positioned(
              top: -40,
              right: -30,
              child: _circle(120, 0.08),
            ),
            Positioned(
              top: 30,
              right: 50,
              child: _circle(60, 0.06),
            ),
            Positioned(
              bottom: 30,
              left: -20,
              child: _circle(80, 0.05),
            ),
          ],

          // ── Curved bottom ─────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: _CurvedPainter(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              size: const Size(double.infinity, 30),
            ),
          ),

          // ── Content ───────────────────────────────────────
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: AppSpacing.pagePadding,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _CurvedPainter extends CustomPainter {
  _CurvedPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.4)
      ..quadraticBezierTo(
        size.width * 0.5,
        -size.height * 0.5,
        size.width,
        size.height * 0.4,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CurvedPainter old) => old.color != color;
}
