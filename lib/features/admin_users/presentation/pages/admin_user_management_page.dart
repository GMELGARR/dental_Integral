import 'package:flutter/material.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_mode_button.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/managed_user.dart';
import '../../domain/entities/module_permission.dart';
import '../controllers/user_management_controller.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() =>
      _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  late final UserManagementController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<UserManagementController>();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Edit user bottom sheet ─────────────────────────────────────
  Future<void> _editUser(ManagedUser user) async {
    var active = user.active;
    final selectedModules = {...user.modules};

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.sm,
                  AppSpacing.xxl,
                  AppSpacing.xxl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── User header ──────────────────────────
                    Row(
                      children: [
                        _UserAvatar(
                          name: user.displayName,
                          size: 44,
                          isDark: isDark,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName,
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                user.email,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const Divider(),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Active toggle ────────────────────────
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.success.withValues(alpha: 0.08)
                            : AppColors.error.withValues(alpha: 0.08),
                        borderRadius: AppSpacing.borderRadiusMd,
                        border: Border.all(
                          color: active
                              ? AppColors.success.withValues(alpha: 0.2)
                              : AppColors.error.withValues(alpha: 0.2),
                        ),
                      ),
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Estado del usuario'),
                        subtitle: Text(
                          active ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            color: active ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        value: active,
                        onChanged: (v) => setModalState(() => active = v),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Module permissions ────────────────────
                    Text(
                      'Permisos de módulos',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...ModulePermission.values.map(
                      (p) => CheckboxListTile(
                        value: selectedModules.contains(p),
                        contentPadding: EdgeInsets.zero,
                        title: Text(p.label),
                        secondary: Icon(
                          _moduleIcon(p),
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        onChanged: (checked) {
                          setModalState(() {
                            if (checked == true) {
                              selectedModules.add(p);
                            } else {
                              selectedModules.remove(p);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Action buttons ────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancelar'),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: FilledButton(
                              onPressed: selectedModules.isEmpty
                                  ? null
                                  : () => Navigator.of(ctx).pop(true),
                              child: const Text('Guardar'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final success = await _controller.updateAccess(
      uid: user.uid,
      active: active,
      modules: selectedModules.toList(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Usuario actualizado correctamente.'
              : (_controller.errorMessage ??
                  'No se pudo actualizar el usuario.'),
        ),
      ),
    );
  }

  IconData _moduleIcon(ModulePermission p) {
    switch (p) {
      case ModulePermission.dashboard:
        return Icons.dashboard_rounded;
      case ModulePermission.patients:
        return Icons.groups_rounded;
      case ModulePermission.appointments:
        return Icons.event_available_rounded;
      case ModulePermission.billing:
        return Icons.receipt_long_rounded;
      case ModulePermission.inventory:
        return Icons.inventory_2_rounded;
      case ModulePermission.reports:
        return Icons.bar_chart_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              // ── Gradient header ───────────────────────
              SliverToBoxAdapter(
                child: GradientHeader(
                  height: 190,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top bar
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          const ThemeModeButton(light: true),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gestión de Usuarios',
                                style:
                                    theme.textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${_controller.users.length} usuario(s) registrado(s)',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),

              // ── Info card ─────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    AppSpacing.lg,
                  ),
                  child: Transform.translate(
                    offset: const Offset(0, -12),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? AppColors.cardGradientDark
                            : AppColors.cardGradientLight,
                        borderRadius: AppSpacing.borderRadiusMd,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2A3545)
                              : const Color(0xFFE0ECF0),
                        ),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.info,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'Crear cuentas con: scripts/admin/create_staff_user.js',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── User list ─────────────────────────────
              if (_controller.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_controller.users.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Sin usuarios registrados',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Usa el script de creación para agregar personal.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final user = _controller.users[index];
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _UserCard(
                            user: user,
                            isDark: isDark,
                            isUpdating:
                                _controller.updatingUserUid == user.uid,
                            onEdit: () => _editUser(user),
                          ),
                        );
                      },
                      childCount: _controller.users.length,
                    ),
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xxxl),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── User card widget ───────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.isDark,
    required this.isUpdating,
    required this.onEdit,
  });

  final ManagedUser user;
  final bool isDark;
  final bool isUpdating;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isDark ? const Color(0xFF2A3545) : const Color(0xFFE0ECF0),
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          _UserAvatar(
            name: user.displayName,
            size: 48,
            isDark: isDark,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.displayName,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (user.role == 'admin')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(user.email, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                StatusBadge(
                  label: user.active ? 'Activo' : 'Inactivo',
                  active: user.active,
                ),
              ],
            ),
          ),
          isUpdating
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  onPressed: onEdit,
                  style: IconButton.styleFrom(
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  tooltip: 'Editar acceso',
                ),
        ],
      ),
    );
  }
}

// ── User avatar ────────────────────────────────────────────────────
class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.name,
    required this.size,
    required this.isDark,
  });

  final String name;
  final double size;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}