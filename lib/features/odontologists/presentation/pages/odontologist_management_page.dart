import 'package:flutter/material.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_mode_button.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../admin_users/domain/entities/managed_user.dart';
import '../../../admin_users/presentation/controllers/user_management_controller.dart';
import '../../domain/entities/odontologist.dart';
import '../../domain/entities/specialty.dart';
import '../controllers/odontologist_controller.dart';

class OdontologistManagementPage extends StatefulWidget {
  const OdontologistManagementPage({super.key});

  @override
  State<OdontologistManagementPage> createState() =>
      _OdontologistManagementPageState();
}

class _OdontologistManagementPageState
    extends State<OdontologistManagementPage> {
  late final OdontologistController _controller;
  late final UserManagementController _usersController;

  @override
  void initState() {
    super.initState();
    _controller = getIt<OdontologistController>();
    _usersController = getIt<UserManagementController>();
  }

  @override
  void dispose() {
    _controller.dispose();
    _usersController.dispose();
    super.dispose();
  }

  // ── Create odontologist ────────────────────────────────────────
  Future<void> _create() async {
    final result = await showModalBottomSheet<_OdontologistFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _OdontologistFormSheet(),
    );

    if (result == null || !mounted) return;

    final success = await _controller.create(
      nombre: result.nombre,
      especialidad: result.especialidad,
      colegiadoActivo: result.colegiadoActivo,
      telefono: result.telefono,
      email: result.email,
      notas: result.notas,
      horaInicio: result.horaInicio,
      horaFin: result.horaFin,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Odontólogo "${result.nombre}" registrado.'
              : (_controller.errorMessage ??
                  'No se pudo registrar al odontólogo.'),
        ),
      ),
    );
  }

  // ── Edit odontologist ──────────────────────────────────────────
  Future<void> _edit(Odontologist odon) async {
    final result = await showModalBottomSheet<_OdontologistFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OdontologistFormSheet(existing: odon),
    );

    if (result == null || !mounted) return;

    final success = await _controller.update(
      id: odon.id,
      nombre: result.nombre,
      especialidad: result.especialidad,
      colegiadoActivo: result.colegiadoActivo,
      telefono: result.telefono,
      email: result.email,
      activo: result.activo,
      notas: result.notas,
      horaInicio: result.horaInicio,
      horaFin: result.horaFin,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Odontólogo actualizado.'
              : (_controller.errorMessage ??
                  'No se pudo actualizar al odontólogo.'),
        ),
      ),
    );
  }

  // ── Link user ──────────────────────────────────────────────────
  Future<void> _linkUser(Odontologist odon) async {
    final availableUsers = _controller.availableUsersForLinking(
      allUsers: _usersController.users,
      currentOdontologistId: odon.id,
    );

    final selected = await showModalBottomSheet<String?>(
      context: context,
      builder: (_) => _LinkUserSheet(
        availableUsers: availableUsers,
        currentUserId: odon.userId,
      ),
    );

    // null means cancelled (didn't tap anything), '' means unlink
    if (selected == null || !mounted) return;

    final userId = selected.isEmpty ? null : selected;

    final success = await _controller.linkUser(
      odontologistId: odon.id,
      userId: userId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (userId == null
                  ? 'Usuario desvinculado.'
                  : 'Usuario vinculado correctamente.')
              : (_controller.errorMessage ?? 'No se pudo vincular.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _usersController]),
      builder: (context, _) {
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _controller.isSaving ? null : _create,
            icon: _controller.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.person_add_rounded),
            label: Text(
              _controller.isSaving ? 'Guardando...' : 'Nuevo odontólogo',
            ),
          ),
          body: CustomScrollView(
            slivers: [
              // ── Header ────────────────────────────────
              SliverToBoxAdapter(
                child: GradientHeader(
                  height: 190,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              Icons.medical_services_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Odontólogos',
                                style:
                                    theme.textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${_controller.odontologists.length} registrado(s)',
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
                              'Registra odontólogos y vincúlalos con usuarios del sistema para control de pacientes y reportes.',
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

              // ── List ──────────────────────────────────
              if (_controller.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_controller.odontologists.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.medical_services_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Sin odontólogos registrados',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Presiona "Nuevo odontólogo" para agregar uno.',
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
                        final odon = _controller.odontologists[index];
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _OdontologistCard(
                            odon: odon,
                            isDark: isDark,
                            isUpdating: _controller.updatingId == odon.id,
                            onEdit: () => _edit(odon),
                            onLink: () => _linkUser(odon),
                          ),
                        );
                      },
                      childCount: _controller.odontologists.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xxxl),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// FORM RESULT
// ═══════════════════════════════════════════════════════════════════

class _OdontologistFormResult {
  const _OdontologistFormResult({
    required this.nombre,
    required this.especialidad,
    required this.colegiadoActivo,
    required this.telefono,
    required this.email,
    required this.activo,
    this.notas,
    required this.horaInicio,
    required this.horaFin,
  });

  final String nombre;
  final Specialty especialidad;
  final String colegiadoActivo;
  final String telefono;
  final String email;
  final bool activo;
  final String? notas;
  final String horaInicio;
  final String horaFin;
}

// ═══════════════════════════════════════════════════════════════════
// CREATE / EDIT SHEET
// ═══════════════════════════════════════════════════════════════════

class _OdontologistFormSheet extends StatefulWidget {
  const _OdontologistFormSheet({this.existing});

  final Odontologist? existing;

  @override
  State<_OdontologistFormSheet> createState() => _OdontologistFormSheetState();
}

class _OdontologistFormSheetState extends State<_OdontologistFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _cedulaCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _notasCtrl;
  late Specialty _specialty;
  late bool _activo;
  late TimeOfDay _horaInicio;
  late TimeOfDay _horaFin;

  bool get _isEditing => widget.existing != null;

  static TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nombreCtrl = TextEditingController(text: e?.nombre ?? '');
    _cedulaCtrl = TextEditingController(text: e?.colegiadoActivo ?? '');
    _telefonoCtrl = TextEditingController(text: e?.telefono ?? '');
    _emailCtrl = TextEditingController(text: e?.email ?? '');
    _notasCtrl = TextEditingController(text: e?.notas ?? '');
    _specialty = e?.especialidad ?? Specialty.general;
    _activo = e?.activo ?? true;
    _horaInicio = _parseTime(e?.horaInicio ?? '08:00');
    _horaFin = _parseTime(e?.horaFin ?? '17:00');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cedulaCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      _OdontologistFormResult(
        nombre: _nombreCtrl.text.trim(),
        especialidad: _specialty,
        colegiadoActivo: _cedulaCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        activo: _activo,
        notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
        horaInicio: _formatTime(_horaInicio),
        horaFin: _formatTime(_horaFin),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.sm,
          AppSpacing.xxl,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxl,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isEditing
                            ? Icons.edit_rounded
                            : Icons.medical_services_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing
                                ? 'Editar odontólogo'
                                : 'Nuevo odontólogo',
                            style: theme.textTheme.titleLarge,
                          ),
                          Text(
                            _isEditing
                                ? 'Modifica los datos profesionales'
                                : 'Registra un profesional dental',
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

                // ── Nombre ──────────────────────────
                TextFormField(
                  controller: _nombreCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) return 'Ingresa el nombre.';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Especialidad ────────────────────
                Text('Especialidad', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<Specialty>(
                  initialValue: _specialty,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: Specialty.values
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.label),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _specialty = v);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Colegiado activo ───────────────
                TextFormField(
                  controller: _cedulaCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Colegiado activo',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) return 'Ingresa el colegiado.';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Teléfono ────────────────────────
                TextFormField(
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) return 'Ingresa el teléfono.';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Email de contacto ───────────────
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email de contacto',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  validator: (v) {
                    final email = v?.trim() ?? '';
                    if (email.isEmpty) return 'Ingresa el email.';
                    if (!email.contains('@')) return 'Email inválido.';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Horario de trabajo ──────────────
                Text('Horario de trabajo', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _horaInicio,
                          );
                          if (picked != null) setState(() => _horaInicio = picked);
                        },
                        borderRadius: AppSpacing.borderRadiusSm,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Inicio',
                            prefixIcon: Icon(Icons.login_rounded),
                          ),
                          child: Text(_formatTime(_horaInicio)),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _horaFin,
                          );
                          if (picked != null) setState(() => _horaFin = picked);
                        },
                        borderRadius: AppSpacing.borderRadiusSm,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fin',
                            prefixIcon: Icon(Icons.logout_rounded),
                          ),
                          child: Text(_formatTime(_horaFin)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Notas ───────────────────────────
                TextFormField(
                  controller: _notasCtrl,
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    prefixIcon: Icon(Icons.notes_rounded),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Active toggle (edit only) ───────
                if (_isEditing) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: _activo
                          ? AppColors.success.withValues(alpha: 0.08)
                          : AppColors.error.withValues(alpha: 0.08),
                      borderRadius: AppSpacing.borderRadiusMd,
                      border: Border.all(
                        color: _activo
                            ? AppColors.success.withValues(alpha: 0.2)
                            : AppColors.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Estado'),
                      subtitle: Text(
                        _activo ? 'Activo' : 'Inactivo',
                        style: TextStyle(
                          color:
                              _activo ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      value: _activo,
                      onChanged: (v) => setState(() => _activo = v),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // ── Actions ─────────────────────────
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
                        child: FilledButton.icon(
                          onPressed: _submit,
                          icon: Icon(
                            _isEditing
                                ? Icons.save_rounded
                                : Icons.person_add_rounded,
                            size: 18,
                          ),
                          label:
                              Text(_isEditing ? 'Guardar' : 'Registrar'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// LINK USER SHEET
// ═══════════════════════════════════════════════════════════════════

class _LinkUserSheet extends StatelessWidget {
  const _LinkUserSheet({
    required this.availableUsers,
    required this.currentUserId,
  });

  final List<ManagedUser> availableUsers;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.link_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vincular usuario',
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        'Usuarios con rol "Odontólogo" disponibles',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // ── Unlink option ───────────────────────
            if (currentUserId != null) ...[
              ListTile(
                leading: Icon(Icons.link_off_rounded, color: AppColors.error),
                title: const Text('Desvincular usuario actual'),
                contentPadding: EdgeInsets.zero,
                onTap: () => Navigator.of(context).pop(''),
              ),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
            ],

            // ── Available users ─────────────────────
            if (availableUsers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_off_rounded,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No hay usuarios con rol "Odontólogo" disponibles.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Crea un usuario con ese rol desde "Gestión de Usuarios".',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...availableUsers.map(
                (user) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(user.displayName),
                  subtitle: Text(user.email),
                  trailing: currentUserId == user.uid
                      ? Chip(
                          label: const Text('Actual'),
                          backgroundColor:
                              AppColors.success.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: currentUserId == user.uid
                      ? null
                      : () => Navigator.of(context).pop(user.uid),
                ),
              ),

            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ODONTOLOGIST CARD
// ═══════════════════════════════════════════════════════════════════

class _OdontologistCard extends StatelessWidget {
  const _OdontologistCard({
    required this.odon,
    required this.isDark,
    required this.isUpdating,
    required this.onEdit,
    required this.onLink,
  });

  final Odontologist odon;
  final bool isDark;
  final bool isUpdating;
  final VoidCallback onEdit;
  final VoidCallback onLink;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: avatar + name + specialty ─────
          Row(
            children: [
              _OdonAvatar(name: odon.nombre, size: 48),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            odon.nombre,
                            style: theme.textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _SpecialtyBadge(specialty: odon.especialidad),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Col. ${odon.colegiadoActivo}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        StatusBadge(
                          label: odon.activo ? 'Activo' : 'Inactivo',
                          active: odon.activo,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          odon.userId != null
                              ? Icons.link_rounded
                              : Icons.link_off_rounded,
                          size: 14,
                          color: odon.userId != null
                              ? AppColors.success
                              : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          odon.userId != null ? 'Vinculado' : 'Sin cuenta',
                          style: TextStyle(
                            fontSize: 11,
                            color: odon.userId != null
                                ? AppColors.success
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isUpdating)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Column(
                  children: [
                    IconButton(
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
                      tooltip: 'Editar',
                    ),
                    const SizedBox(height: 4),
                    IconButton(
                      onPressed: onLink,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            AppColors.info.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(
                        Icons.link_rounded,
                        size: 18,
                        color: AppColors.info,
                      ),
                      tooltip: 'Vincular usuario',
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SPECIALTY BADGE
// ═══════════════════════════════════════════════════════════════════

class _SpecialtyBadge extends StatelessWidget {
  const _SpecialtyBadge({required this.specialty});

  final Specialty specialty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        specialty.label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppColors.info,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// AVATAR
// ═══════════════════════════════════════════════════════════════════

class _OdonAvatar extends StatelessWidget {
  const _OdonAvatar({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00897B), Color(0xFF4DB6AC)],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00897B).withValues(alpha: 0.25),
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
