import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_mode_button.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/module_card.dart';
import '../../../admin_users/domain/entities/module_permission.dart';
import '../../../auth/presentation/controllers/auth_session_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authSession = getIt<AuthSessionController>();
    final user = authSession.currentUser;
    final email = user?.email ?? 'usuario';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Extract display name or first part of email
    final displayName = email.split('@').first;
    final greeting = _greeting();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Gradient header with user info ────────────────
          SliverToBoxAdapter(
            child: GradientHeader(
              height: 240,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            displayName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const ThemeModeButton(light: true),
                      _LogoutButton(authSession: authSession),
                    ],
                  ),
                  const Spacer(),

                  // Welcome text
                  Text(
                    'Dental Integral',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Panel de gestión clínica',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),

          // ── Quick stats row ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Transform.translate(
                offset: const Offset(0, -16),
                child: Row(
                  children: [
                    _StatCard(
                      icon: Icons.people_outline_rounded,
                      label: 'Pacientes',
                      value: '--',
                      gradient: AppColors.primaryGradient,
                      isDark: isDark,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _StatCard(
                      icon: Icons.calendar_today_rounded,
                      label: 'Citas hoy',
                      value: '--',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
                      ),
                      isDark: isDark,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _StatCard(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Activos',
                      value: '--',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00897B), Color(0xFF4DB6AC)],
                      ),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Section title ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md,
              ),
              child: Text(
                'Módulos',
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),

          // ── Module cards ──────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (authSession.isAdmin) ...[
                  ModuleCard(
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Administrar Usuarios',
                    subtitle: 'Gestión de cuentas, roles y permisos',
                    iconGradient: const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFEF5350)],
                    ),
                    onTap: () => context.push('/admin/users'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (authSession.isAdmin ||
                    authSession.hasModule(ModulePermission.patients)) ...[
                  ModuleCard(
                    icon: Icons.groups_rounded,
                    title: 'Pacientes',
                    subtitle: 'Registro, historial y expedientes',
                    iconGradient: const LinearGradient(
                      colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
                    ),
                    onTap: () => context.push('/patients'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (authSession.isAdmin ||
                    authSession.hasModule(ModulePermission.odontologists)) ...[
                  ModuleCard(
                    icon: Icons.medical_services_rounded,
                    title: 'Odontólogos',
                    subtitle: 'Registro profesional y vinculación',
                    iconGradient: const LinearGradient(
                      colors: [Color(0xFF00897B), Color(0xFF4DB6AC)],
                    ),
                    onTap: () => context.push('/odontologists'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (authSession.isAdmin ||
                    authSession.hasModule(ModulePermission.treatments)) ...[
                  ModuleCard(
                    icon: Icons.healing_rounded,
                    title: 'Tratamientos',
                    subtitle: 'Catálogo de servicios y montos',
                    iconGradient: const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
                    ),
                    onTap: () => context.push('/treatments'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (authSession.isAdmin ||
                    authSession.hasModule(ModulePermission.appointments)) ...[
                  ModuleCard(
                    icon: Icons.event_available_rounded,
                    title: 'Citas',
                    subtitle: 'Agenda y programación de consultas',
                    iconGradient: const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
                    ),
                    onTap: () => context.push('/appointments'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (authSession.isAdmin ||
                    authSession.hasModule(ModulePermission.billing)) ...[
                  ModuleCard(
                    icon: Icons.receipt_long_rounded,
                    title: 'Facturación',
                    subtitle: 'Cobros, facturas y reportes financieros',
                    iconGradient: const LinearGradient(
                      colors: [Color(0xFF00897B), Color(0xFF4DB6AC)],
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Módulo en desarrollo.'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (authSession.isAdmin ||
                    authSession.hasModule(ModulePermission.inventory)) ...[
                  ModuleCard(
                    icon: Icons.inventory_2_rounded,
                    title: 'Inventario',
                    subtitle: 'Control de materiales y suministros',
                    iconGradient: const LinearGradient(
                      colors: [Color(0xFFF4511E), Color(0xFFFF8A65)],
                    ),
                    onTap: () => context.push('/inventory'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (authSession.isAdmin ||
                    authSession.hasModule(ModulePermission.reports)) ...[
                  ModuleCard(
                    icon: Icons.bar_chart_rounded,
                    title: 'Reportes',
                    subtitle: 'Estadísticas y análisis de la clínica',
                    iconGradient: const LinearGradient(
                      colors: [Color(0xFFFFB300), Color(0xFFFFD54F)],
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Módulo en desarrollo.'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // No modules message
                if (!authSession.isAdmin &&
                    !authSession.hasModule(ModulePermission.patients) &&
                    !authSession.hasModule(ModulePermission.treatments) &&
                    !authSession.hasModule(ModulePermission.appointments) &&
                    !authSession.hasModule(ModulePermission.billing) &&
                    !authSession.hasModule(ModulePermission.inventory) &&
                    !authSession.hasModule(ModulePermission.reports))
                  Container(
                    padding: AppSpacing.cardPaddingLarge,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: AppSpacing.borderRadiusLg,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2A3545)
                            : const Color(0xFFE0ECF0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Sin módulos asignados',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Contacta al administrador para obtener acceso a los módulos del sistema.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: AppSpacing.xxxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }
}

// ── Logout button (keeps logic intact) ─────────────────────────────
class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.authSession});
  final AuthSessionController authSession;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        final success = await authSession.signOut();
        if (!context.mounted) return;
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo cerrar sesión. Intenta de nuevo.'),
            ),
          );
        }
        context.go('/login');
      },
      tooltip: 'Cerrar sesión',
      icon: Icon(
        Icons.logout_rounded,
        color: Colors.white.withValues(alpha: 0.8),
      ),
    );
  }
}

// ── Small stat card ────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final LinearGradient gradient;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: isDark
                ? const Color(0xFF2A3545)
                : const Color(0xFFE0ECF0),
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 11.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}