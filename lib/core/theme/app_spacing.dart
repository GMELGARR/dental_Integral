import 'package:flutter/material.dart';

/// Consistent spacing scale used throughout the app.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
  static const double massive = 64;

  // ── Padding presets ──────────────────────────────────────────────
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: lg,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(xl);

  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(xxl);

  // ── Border radius ────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusXxl = 24;
  static const double radiusRound = 100;

  static BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static BorderRadius borderRadiusXl = BorderRadius.circular(radiusXl);
  static BorderRadius borderRadiusXxl = BorderRadius.circular(radiusXxl);
}
