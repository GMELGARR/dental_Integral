import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/managed_user.dart';
import '../../domain/entities/module_permission.dart';
import '../helpers/module_icon.dart';
import 'user_card.dart';

// ── Edit user result ───────────────────────────────────────────────
class EditUserResult {
  const EditUserResult({
    required this.active,
    required this.role,
    required this.modules,
  });

  final bool active;
  final String role;
  final List<ModulePermission> modules;
}

// ── Edit user sheet ───────────────────────────────────────────────
class EditUserSheet extends StatefulWidget {
  const EditUserSheet({super.key, required this.user});

  final ManagedUser user;

  @override
  State<EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends State<EditUserSheet> {
  late bool _active;
  late String _selectedRole;
  late final Set<ModulePermission> _selectedModules;

  static const _roles = {
    'admin': 'Admin',
    'staff': 'Staff',
    'odontologo': 'Odontólogo',
  };

  @override
  void initState() {
    super.initState();
    _active = widget.user.active;
    _selectedRole = widget.user.role;
    _selectedModules = {...widget.user.modules};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                UserAvatar(
                  name: widget.user.displayName,
                  size: 44,
                  isDark: isDark,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.displayName,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        widget.user.email,
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

            // ── Role selector ────────────────────────
            Text(
              'Rol',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.shield_outlined),
              ),
              items: _roles.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedRole = v);
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Active toggle ────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: _active
                    ? AppColors.success.withValues(alpha: 0.08)
                    : AppColors.error.withValues(alpha: 0.08),
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(
                  color: _active
                      ? AppColors.success.withValues(alpha: 0.2)
                      : AppColors.error.withValues(alpha: 0.2),
                ),
              ),
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Estado del usuario'),
                subtitle: Text(
                  _active ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    color: _active ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
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
                value: _selectedModules.contains(p),
                contentPadding: EdgeInsets.zero,
                title: Text(p.label),
                secondary: Icon(
                  moduleIcon(p),
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedModules.add(p);
                    } else {
                      _selectedModules.remove(p);
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
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _selectedModules.isEmpty
                          ? null
                          : () => Navigator.of(context).pop(
                                EditUserResult(
                                  active: _active,
                                  role: _selectedRole,
                                  modules: _selectedModules.toList(),
                                ),
                              ),
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
  }
}
