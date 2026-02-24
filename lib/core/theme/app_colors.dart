import 'package:flutter/material.dart';

/// Dental Integral brand color palette.
///
/// Primary: Professional teal-cyan gradient evoking clinical trust.
/// Accent: Warm amber for CTAs and highlights.
class AppColors {
  AppColors._();

  // ── Brand primaries ──────────────────────────────────────────────
  static const Color primary = Color(0xFF0D7377);
  static const Color primaryLight = Color(0xFF14919B);
  static const Color primaryDark = Color(0xFF0A5C5F);

  // ── Accent ───────────────────────────────────────────────────────
  static const Color accent = Color(0xFF0D7377);
  static const Color accentLight = Color(0xFF45B7AA);

  // ── Semantic ─────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFC62828);
  static const Color info = Color(0xFF1565C0);

  // ── Gradients ────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D7377), Color(0xFF14919B)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A1628), Color(0xFF132742)],
  );

  static const LinearGradient cardGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8FDFD), Color(0xFFEFF9FA)],
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A2332), Color(0xFF1E2A3A)],
  );

  // ── Surfaces (light) ────────────────────────────────────────────
  static const Color surfaceLight = Color(0xFFF5F9FA);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE0E8EC);

  // ── Surfaces (dark) ─────────────────────────────────────────────
  static const Color surfaceDark = Color(0xFF0F1923);
  static const Color cardDark = Color(0xFF182030);
  static const Color dividerDark = Color(0xFF2A3545);

  // ── Text (light) ────────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF1A2B3D);
  static const Color textSecondaryLight = Color(0xFF5A6D7E);
  static const Color textTertiaryLight = Color(0xFF8E9EAE);

  // ── Text (dark) ─────────────────────────────────────────────────
  static const Color textPrimaryDark = Color(0xFFF0F4F8);
  static const Color textSecondaryDark = Color(0xFFB0BEC5);
  static const Color textTertiaryDark = Color(0xFF78909C);
}
