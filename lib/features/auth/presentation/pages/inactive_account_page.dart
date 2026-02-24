import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../controllers/auth_session_controller.dart';

class InactiveAccountPage extends StatelessWidget {
  const InactiveAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = getIt<AuthSessionController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background gradient ───────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppColors.darkGradient
                    : AppColors.primaryGradient,
              ),
            ),
          ),
          Positioned(top: -30, right: -40, child: _circle(140, 0.05)),
          Positioned(bottom: 50, left: -20, child: _circle(90, 0.04)),

          // ── Content ───────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: AppSpacing.pagePadding,
                child: GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Warning icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.lock_person_rounded,
                          size: 36,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Cuenta Inactiva',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Tu cuenta ha sido desactivada por un administrador. '
                        'Contacta al equipo administrativo para restaurar el acceso.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Contact info box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.06),
                          borderRadius: AppSpacing.borderRadiusMd,
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.support_agent_rounded,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'Solicita reactivación al administrador del sistema.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await session.signOut();
                            if (context.mounted) context.go('/login');
                          },
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('Cerrar sesión'),
                        ),
                      ),
                    ],
                  ),
                ),
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