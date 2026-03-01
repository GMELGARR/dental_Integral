import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_mode_button.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../clinical_records/presentation/pages/patient_history_page.dart';
import '../../domain/entities/patient.dart';
import '../controllers/patient_controller.dart';

// ══════════════════════════════════════════════════════════════════
// MAIN PAGE
// ══════════════════════════════════════════════════════════════════

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  late final PatientController _controller;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _controller = getIt<PatientController>();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  List<Patient> get _filteredPatients {
    var list = _controller.patients;
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((p) =>
              p.nombre.toLowerCase().contains(_searchQuery) ||
              p.dpi.contains(_searchQuery))
          .toList();
    }
    return list;
  }

  // ── Create ─────────────────────────────────────────────────────
  Future<void> _create() async {
    final result = await Navigator.of(context).push<_PatientFormResult>(
      MaterialPageRoute(
        builder: (_) => const _PatientFormPage(),
      ),
    );
    if (result == null || !mounted) return;

    final success = await _controller.create(
      nombre: result.nombre,
      dpi: result.dpi,
      fechaNacimiento: result.fechaNacimiento,
      genero: result.genero,
      telefono: result.telefono,
      telefonoEmergencia: result.telefonoEmergencia,
      contactoEmergencia: result.contactoEmergencia,
      direccion: result.direccion,
      email: result.email,
      alergias: result.alergias,
      enfermedadesSistemicas: result.enfermedadesSistemicas,
      medicamentosActuales: result.medicamentosActuales,
      notasClinicas: result.notasClinicas,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Paciente "${result.nombre}" registrado.'
              : _controller.errorMessage ?? 'Error al registrar.',
        ),
      ),
    );
  }

  // ── Edit ───────────────────────────────────────────────────────
  Future<void> _edit(Patient patient) async {
    final result = await Navigator.of(context).push<_PatientFormResult>(
      MaterialPageRoute(
        builder: (_) => _PatientFormPage(existing: patient),
      ),
    );
    if (result == null || !mounted) return;

    final success = await _controller.update(
      id: patient.id,
      nombre: result.nombre,
      dpi: result.dpi,
      fechaNacimiento: result.fechaNacimiento,
      genero: result.genero,
      telefono: result.telefono,
      activo: result.activo,
      telefonoEmergencia: result.telefonoEmergencia,
      contactoEmergencia: result.contactoEmergencia,
      direccion: result.direccion,
      email: result.email,
      alergias: result.alergias,
      enfermedadesSistemicas: result.enfermedadesSistemicas,
      medicamentosActuales: result.medicamentosActuales,
      notasClinicas: result.notasClinicas,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Paciente "${result.nombre}" actualizado.'
              : _controller.errorMessage ?? 'Error al actualizar.',
        ),
      ),
    );
  }

  // ── Detail ─────────────────────────────────────────────────────
  void _viewDetail(Patient patient) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PatientDetailPage(
          patient: patient,
          onEdit: () => _edit(patient),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final filtered = _filteredPatients;

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
              _controller.isSaving ? 'Guardando...' : 'Nuevo paciente',
            ),
          ),

          body: CustomScrollView(
            slivers: [
              // ── Gradient header ────────────────
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
                              Icons.groups_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pacientes',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${_controller.patients.length} registrado(s)',
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.7),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),

              // ── Search ─────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md,
                  ),
                  child: Transform.translate(
                    offset: const Offset(0, -12),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o DPI...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () => _searchCtrl.clear(),
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Content ────────────────────────
              if (_controller.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_off_rounded,
                          size: 56,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Sin resultados para "${_searchCtrl.text.trim()}".'
                              : 'Sin pacientes registrados.',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Toca el botón + para agregar.',
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
                        if (index == filtered.length) {
                          return const SizedBox(height: 88);
                        }
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _PatientCard(
                            patient: filtered[index],
                            isDark: isDark,
                            isUpdating: _controller.updatingId ==
                                filtered[index].id,
                            onTap: () => _viewDetail(filtered[index]),
                          ),
                        );
                      },
                      childCount: filtered.length + 1,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// PATIENT CARD
// ══════════════════════════════════════════════════════════════════

class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.patient,
    required this.isDark,
    required this.isUpdating,
    required this.onTap,
  });

  final Patient patient;
  final bool isDark;
  final bool isUpdating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: patient.activo ? 1.0 : 0.55,
      child: Container(
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppSpacing.borderRadiusMd,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: isUpdating
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Row(
                      children: [
                        // Avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              patient.nombre.isNotEmpty
                                  ? patient.nombre[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      patient.nombre,
                                      style: theme
                                          .textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow:
                                          TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (patient.tieneAlergias)
                                    Tooltip(
                                      message: 'Tiene alergias',
                                      child: Icon(
                                        Icons
                                            .warning_amber_rounded,
                                        color: AppColors.warning,
                                        size: 20,
                                      ),
                                    ),
                                  if (!patient.activo) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.error
                                            .withValues(
                                                alpha: 0.12),
                                        borderRadius:
                                            BorderRadius
                                                .circular(6),
                                      ),
                                      child: Text(
                                        'Inactivo',
                                        style: TextStyle(
                                          color:
                                              AppColors.error,
                                          fontSize: 10,
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'DPI: ${patient.dpi}',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: theme
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_rounded,
                                    size: 14,
                                    color: theme.colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    patient.telefono,
                                    style: theme
                                        .textTheme.bodySmall
                                        ?.copyWith(
                                      color: theme.colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                  if (patient.edad != null) ...[
                                    const SizedBox(width: 12),
                                    Text(
                                      '${patient.edad} años',
                                      style: theme
                                          .textTheme.bodySmall
                                          ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.4),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// PATIENT DETAIL PAGE
// ══════════════════════════════════════════════════════════════════

class _PatientDetailPage extends StatelessWidget {
  const _PatientDetailPage({
    required this.patient,
    required this.onEdit,
  });

  final Patient patient;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dobFormatted = patient.fechaNacimiento != null
        ? DateFormat('dd/MM/yyyy').format(patient.fechaNacimiento!)
        : '—';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del paciente'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
              onEdit();
            },
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Editar',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          // ── Header card ──────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: isDark
                  ? AppColors.cardGradientDark
                  : AppColors.cardGradientLight,
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2A3545)
                    : const Color(0xFFE0ECF0),
              ),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      patient.nombre.isNotEmpty
                          ? patient.nombre[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.nombre,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'DPI: ${patient.dpi}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (patient.edad != null)
                        Text(
                          '${patient.edad} años  ·  ${patient.genero}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!patient.activo)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Inactivo',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Datos personales ─────────────────
          _SectionHeader(title: 'Datos personales'),
          const SizedBox(height: AppSpacing.md),
          _InfoTile(
            icon: Icons.calendar_today_rounded,
            label: 'Fecha de nacimiento',
            value: dobFormatted,
          ),
          _InfoTile(
            icon: Icons.wc_rounded,
            label: 'Género',
            value: patient.genero.isNotEmpty ? patient.genero : '—',
          ),
          _InfoTile(
            icon: Icons.phone_rounded,
            label: 'Teléfono',
            value: patient.telefono.isNotEmpty ? patient.telefono : '—',
          ),
          if (_hasValue(patient.email))
            _InfoTile(
              icon: Icons.email_rounded,
              label: 'Correo electrónico',
              value: patient.email!,
            ),
          if (_hasValue(patient.direccion))
            _InfoTile(
              icon: Icons.location_on_rounded,
              label: 'Dirección',
              value: patient.direccion!,
            ),
          const SizedBox(height: AppSpacing.lg),

          // ── Contacto de emergencia ───────────
          if (_hasValue(patient.contactoEmergencia) ||
              _hasValue(patient.telefonoEmergencia)) ...[
            _SectionHeader(title: 'Contacto de emergencia'),
            const SizedBox(height: AppSpacing.md),
            if (_hasValue(patient.contactoEmergencia))
              _InfoTile(
                icon: Icons.person_rounded,
                label: 'Nombre',
                value: patient.contactoEmergencia!,
              ),
            if (_hasValue(patient.telefonoEmergencia))
              _InfoTile(
                icon: Icons.phone_callback_rounded,
                label: 'Teléfono',
                value: patient.telefonoEmergencia!,
              ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── Antecedentes médicos ─────────────
          _SectionHeader(title: 'Antecedentes médicos'),
          const SizedBox(height: AppSpacing.md),
          _MedicalTile(
            icon: Icons.warning_amber_rounded,
            label: 'Alergias',
            value: patient.alergias,
            alertColor:
                patient.tieneAlergias ? AppColors.warning : null,
          ),
          _MedicalTile(
            icon: Icons.monitor_heart_rounded,
            label: 'Enfermedades sistémicas',
            value: patient.enfermedadesSistemicas,
          ),
          _MedicalTile(
            icon: Icons.medication_rounded,
            label: 'Medicamentos actuales',
            value: patient.medicamentosActuales,
          ),
          _MedicalTile(
            icon: Icons.notes_rounded,
            label: 'Notas clínicas',
            value: patient.notasClinicas,
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Historial clínico button ─────────
          _SectionHeader(title: 'Historial clínico'),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PatientHistoryPage(
                      patientId: patient.id,
                      patientName: patient.nombre,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.history_rounded),
              label: const Text('Ver historial de consultas'),
            ),
          ),

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  bool _hasValue(String? v) => v != null && v.trim().isNotEmpty;
}

// ── Section header ───────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

// ── Info tile (simple key/value) ─────────────────────────────────

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.6),
                  ),
                ),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Medical tile (with optional alert highlight) ─────────────────

class _MedicalTile extends StatelessWidget {
  const _MedicalTile({
    required this.icon,
    required this.label,
    this.value,
    this.alertColor,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Color? alertColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasContent = value != null && value!.trim().isNotEmpty;
    final displayValue = hasContent ? value! : 'Sin registrar';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: alertColor != null
            ? alertColor!.withValues(alpha: 0.08)
            : theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.3),
        borderRadius: AppSpacing.borderRadiusSm,
        border: alertColor != null
            ? Border.all(color: alertColor!.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: alertColor ?? AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: alertColor ??
                        theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: hasContent
                        ? null
                        : theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                    fontStyle:
                        hasContent ? null : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// PATIENT FORM PAGE (full page, not bottom sheet)
// ══════════════════════════════════════════════════════════════════

class _PatientFormResult {
  const _PatientFormResult({
    required this.nombre,
    required this.dpi,
    required this.fechaNacimiento,
    required this.genero,
    required this.telefono,
    required this.activo,
    this.telefonoEmergencia,
    this.contactoEmergencia,
    this.direccion,
    this.email,
    this.alergias,
    this.enfermedadesSistemicas,
    this.medicamentosActuales,
    this.notasClinicas,
  });

  final String nombre;
  final String dpi;
  final DateTime? fechaNacimiento;
  final String genero;
  final String telefono;
  final bool activo;
  final String? telefonoEmergencia;
  final String? contactoEmergencia;
  final String? direccion;
  final String? email;
  final String? alergias;
  final String? enfermedadesSistemicas;
  final String? medicamentosActuales;
  final String? notasClinicas;
}

class _PatientFormPage extends StatefulWidget {
  const _PatientFormPage({this.existing});
  final Patient? existing;

  @override
  State<_PatientFormPage> createState() => _PatientFormPageState();
}

class _PatientFormPageState extends State<_PatientFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Datos personales
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _dpiCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _direccionCtrl;
  late String _genero;
  DateTime? _fechaNacimiento;
  late bool _activo;

  // Emergencia
  late final TextEditingController _contactoEmergenciaCtrl;
  late final TextEditingController _telEmergenciaCtrl;

  // Antecedentes
  late final TextEditingController _alergiasCtrl;
  late final TextEditingController _enfermedadesCtrl;
  late final TextEditingController _medicamentosCtrl;
  late final TextEditingController _notasCtrl;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nombreCtrl = TextEditingController(text: e?.nombre ?? '');
    _dpiCtrl = TextEditingController(text: e?.dpi ?? '');
    _telefonoCtrl = TextEditingController(text: e?.telefono ?? '');
    _emailCtrl = TextEditingController(text: e?.email ?? '');
    _direccionCtrl = TextEditingController(text: e?.direccion ?? '');
    _genero = e?.genero ?? 'Masculino';
    _fechaNacimiento = e?.fechaNacimiento;
    _activo = e?.activo ?? true;

    _contactoEmergenciaCtrl =
        TextEditingController(text: e?.contactoEmergencia ?? '');
    _telEmergenciaCtrl =
        TextEditingController(text: e?.telefonoEmergencia ?? '');

    _alergiasCtrl = TextEditingController(text: e?.alergias ?? '');
    _enfermedadesCtrl =
        TextEditingController(text: e?.enfermedadesSistemicas ?? '');
    _medicamentosCtrl =
        TextEditingController(text: e?.medicamentosActuales ?? '');
    _notasCtrl = TextEditingController(text: e?.notasClinicas ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _dpiCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _direccionCtrl.dispose();
    _contactoEmergenciaCtrl.dispose();
    _telEmergenciaCtrl.dispose();
    _alergiasCtrl.dispose();
    _enfermedadesCtrl.dispose();
    _medicamentosCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  String? _trimOrNull(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _fechaNacimiento = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      _PatientFormResult(
        nombre: _nombreCtrl.text.trim(),
        dpi: _dpiCtrl.text.trim(),
        fechaNacimiento: _fechaNacimiento,
        genero: _genero,
        telefono: _telefonoCtrl.text.trim(),
        activo: _activo,
        telefonoEmergencia: _trimOrNull(_telEmergenciaCtrl),
        contactoEmergencia: _trimOrNull(_contactoEmergenciaCtrl),
        direccion: _trimOrNull(_direccionCtrl),
        email: _trimOrNull(_emailCtrl),
        alergias: _trimOrNull(_alergiasCtrl),
        enfermedadesSistemicas: _trimOrNull(_enfermedadesCtrl),
        medicamentosActuales: _trimOrNull(_medicamentosCtrl),
        notasClinicas: _trimOrNull(_notasCtrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dobText = _fechaNacimiento != null
        ? DateFormat('dd/MM/yyyy').format(_fechaNacimiento!)
        : 'Seleccionar fecha';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar paciente' : 'Nuevo paciente'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            // ════════════════════════════════════
            // SECCIÓN 1: DATOS PERSONALES
            // ════════════════════════════════════
            _SectionHeader(title: 'Datos personales'),
            const SizedBox(height: AppSpacing.lg),

            // Nombre
            TextFormField(
              controller: _nombreCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ingresa el nombre.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),

            // DPI
            TextFormField(
              controller: _dpiCtrl,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(13),
              ],
              decoration: const InputDecoration(
                labelText: 'DPI',
                prefixIcon: Icon(Icons.badge_rounded),
                hintText: '13 dígitos',
              ),
              validator: (v) {
                final text = v?.trim() ?? '';
                if (text.isEmpty) return 'Ingresa el DPI.';
                if (text.length != 13) return 'El DPI debe tener 13 dígitos.';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Fecha de nacimiento
            InkWell(
              onTap: _pickDate,
              borderRadius: AppSpacing.borderRadiusSm,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de nacimiento',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        dobText,
                        style: _fechaNacimiento == null
                            ? theme.textTheme.bodyMedium?.copyWith(
                                color: theme
                                    .colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                              )
                            : theme.textTheme.bodyMedium,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Género
            DropdownButtonFormField<String>(
              initialValue: _genero,
              decoration: const InputDecoration(
                labelText: 'Género',
                prefixIcon: Icon(Icons.wc_rounded),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Masculino',
                  child: Text('Masculino'),
                ),
                DropdownMenuItem(
                  value: 'Femenino',
                  child: Text('Femenino'),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _genero = v);
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Teléfono
            TextFormField(
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone_rounded),
                hintText: '8 dígitos',
              ),
              validator: (v) {
                final text = v?.trim() ?? '';
                if (text.isEmpty) return 'Ingresa el teléfono.';
                if (text.length != 8) return 'Debe tener 8 dígitos.';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Email (opcional)
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico (opcional)',
                prefixIcon: Icon(Icons.email_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Dirección (opcional)
            TextFormField(
              controller: _direccionCtrl,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Dirección (opcional)',
                prefixIcon: Icon(Icons.location_on_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // ════════════════════════════════════
            // SECCIÓN 2: CONTACTO DE EMERGENCIA
            // ════════════════════════════════════
            _SectionHeader(title: 'Contacto de emergencia'),
            const SizedBox(height: AppSpacing.lg),

            TextFormField(
              controller: _contactoEmergenciaCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nombre del contacto (opcional)',
                prefixIcon: Icon(Icons.person_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            TextFormField(
              controller: _telEmergenciaCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              decoration: const InputDecoration(
                labelText: 'Teléfono de emergencia (opcional)',
                prefixIcon: Icon(Icons.phone_callback_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // ════════════════════════════════════
            // SECCIÓN 3: ANTECEDENTES MÉDICOS
            // ════════════════════════════════════
            _SectionHeader(title: 'Antecedentes médicos'),
            const SizedBox(height: AppSpacing.lg),

            TextFormField(
              controller: _alergiasCtrl,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Alergias (opcional)',
                prefixIcon: Icon(Icons.warning_amber_rounded),
                hintText: 'Ej: Penicilina, Latex, Anestésicos',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            TextFormField(
              controller: _enfermedadesCtrl,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Enfermedades sistémicas (opcional)',
                prefixIcon: Icon(Icons.monitor_heart_rounded),
                hintText: 'Ej: Diabetes, Hipertensión',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            TextFormField(
              controller: _medicamentosCtrl,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Medicamentos actuales (opcional)',
                prefixIcon: Icon(Icons.medication_rounded),
                hintText: 'Ej: Metformina 500mg, Losartan 50mg',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            TextFormField(
              controller: _notasCtrl,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notas clínicas (opcional)',
                prefixIcon: Icon(Icons.notes_rounded),
                hintText: 'Observaciones generales',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Active toggle (only edit) ──────
            if (_isEditing) ...[
              SwitchListTile(
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
                title: const Text('Paciente activo'),
                subtitle: Text(
                  _activo ? 'Visible en la lista' : 'Archivado',
                ),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // ── Submit ─────────────────────────
            FilledButton.icon(
              onPressed: _submit,
              icon: Icon(
                _isEditing ? Icons.save_rounded : Icons.person_add_rounded,
              ),
              label: Text(
                _isEditing ? 'Guardar cambios' : 'Registrar paciente',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}