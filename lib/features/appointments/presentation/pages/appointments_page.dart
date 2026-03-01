import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_mode_button.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../odontologists/domain/entities/odontologist.dart';
import '../../../odontologists/presentation/controllers/odontologist_controller.dart';
import '../../../patients/domain/entities/patient.dart';
import '../../../patients/presentation/controllers/patient_controller.dart';
import '../../domain/entities/appointment.dart';
import '../controllers/appointment_controller.dart';
import '../widgets/time_slot_grid.dart';

// ══════════════════════════════════════════════════════════════════
// MAIN PAGE
// ══════════════════════════════════════════════════════════════════

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  late final AppointmentController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<AppointmentController>();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Date navigation ────────────────────────────────────────────
  void _prevDay() {
    final d = _controller.selectedDate.subtract(const Duration(days: 1));
    _controller.selectDate(d);
  }

  void _nextDay() {
    final d = _controller.selectedDate.add(const Duration(days: 1));
    _controller.selectDate(d);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _controller.selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) _controller.selectDate(picked);
  }

  void _goToday() => _controller.selectDate(DateTime.now());

  // ── Create appointment ─────────────────────────────────────────
  Future<void> _create() async {
    final result = await Navigator.of(context).push<_AppointmentFormResult>(
      MaterialPageRoute(builder: (_) => const _AppointmentFormPage()),
    );
    if (result == null || !mounted) return;

    final success = await _controller.create(
      tipo: result.tipo,
      fecha: result.fecha,
      hora: result.hora,
      odontologoId: result.odontologoId,
      odontologoNombre: result.odontologoNombre,
      pacienteNombre: result.pacienteNombre,
      pacienteTelefono: result.pacienteTelefono,
      pacienteId: result.pacienteId,
      nombreTemporal: result.nombreTemporal,
      telefonoTemporal: result.telefonoTemporal,
      motivo: result.motivo,
      notas: result.notas,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Cita agendada para ${result.pacienteNombre}.'
              : _controller.errorMessage ?? 'Error al agendar.',
        ),
      ),
    );
  }

  // ── Change status ──────────────────────────────────────────────
  Future<void> _showStatusSheet(Appointment appt) async {
    final nextStates = AppointmentStatus.nextStates(appt.estado);
    if (nextStates.isEmpty) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Cambiar estado',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              ...nextStates.map((s) {
                return ListTile(
                  leading: Icon(
                    _statusIcon(s),
                    color: _statusColor(s),
                  ),
                  title: Text(AppointmentStatus.label(s)),
                  onTap: () => Navigator.of(ctx).pop(s),
                );
              }),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );

    if (selected == null || !mounted) return;

    final ok = await _controller.changeStatus(appt.id, selected);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage ?? 'Error al actualizar.'),
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final now = DateTime.now();
        final sel = _controller.selectedDate;
        final isToday = sel.year == now.year &&
            sel.month == now.month &&
            sel.day == now.day;
        final dateLabel = isToday
            ? 'Hoy, ${DateFormat('d MMM', 'es').format(sel)}'
            : DateFormat('EEE d MMM yyyy', 'es').format(sel);

        final appointments = _controller.appointments;

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
                : const Icon(Icons.add_rounded),
            label: Text(
              _controller.isSaving ? 'Guardando...' : 'Nueva cita',
            ),
          ),
          body: CustomScrollView(
            slivers: [
              // ── Gradient header ─────────────────
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
                              Icons.event_available_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Citas',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${appointments.length} cita(s) ${isToday ? "hoy" : "este día"}',
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

              // ── Date navigator ──────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.md,
                  ),
                  child: Transform.translate(
                    offset: const Offset(0, -12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
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
                          IconButton(
                            onPressed: _prevDay,
                            icon: const Icon(Icons.chevron_left_rounded),
                            iconSize: 28,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickDate,
                              child: Text(
                                dateLabel,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _nextDay,
                            icon: const Icon(Icons.chevron_right_rounded),
                            iconSize: 28,
                          ),
                          if (!isToday)
                            TextButton(
                              onPressed: _goToday,
                              child: const Text('Hoy'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Content ─────────────────────────
              if (_controller.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (appointments.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 56,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Sin citas para este día.',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Toca + para agendar una nueva.',
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
                        if (index == appointments.length) {
                          return const SizedBox(height: 88);
                        }
                        final appt = appointments[index];
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _AppointmentCard(
                            appointment: appt,
                            isDark: isDark,
                            isUpdating:
                                _controller.updatingId == appt.id,
                            onChangeStatus: () => _showStatusSheet(appt),
                          ),
                        );
                      },
                      childCount: appointments.length + 1,
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
// STATUS HELPERS
// ══════════════════════════════════════════════════════════════════

Color _statusColor(String status) {
  switch (status) {
    case AppointmentStatus.programada:
      return AppColors.info;
    case AppointmentStatus.confirmada:
      return AppColors.primary;
    case AppointmentStatus.enSala:
      return AppColors.warning;
    case AppointmentStatus.enAtencion:
      return const Color(0xFF7C4DFF);
    case AppointmentStatus.completada:
      return AppColors.success;
    case AppointmentStatus.cancelada:
      return AppColors.error;
    case AppointmentStatus.noAsistio:
      return const Color(0xFF78909C);
    default:
      return AppColors.info;
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case AppointmentStatus.programada:
      return Icons.schedule_rounded;
    case AppointmentStatus.confirmada:
      return Icons.check_circle_outline_rounded;
    case AppointmentStatus.enSala:
      return Icons.airline_seat_recline_normal_rounded;
    case AppointmentStatus.enAtencion:
      return Icons.medical_services_rounded;
    case AppointmentStatus.completada:
      return Icons.task_alt_rounded;
    case AppointmentStatus.cancelada:
      return Icons.cancel_rounded;
    case AppointmentStatus.noAsistio:
      return Icons.person_off_rounded;
    default:
      return Icons.circle_outlined;
  }
}

// ══════════════════════════════════════════════════════════════════
// APPOINTMENT CARD
// ══════════════════════════════════════════════════════════════════

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.isDark,
    required this.isUpdating,
    required this.onChangeStatus,
  });

  final Appointment appointment;
  final bool isDark;
  final bool isUpdating;
  final VoidCallback onChangeStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(appointment.estado);
    final isTerminal = appointment.isTerminal;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isTerminal ? 0.6 : 1.0,
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
            onTap: isUpdating ? null : onChangeStatus,
            borderRadius: AppSpacing.borderRadiusMd,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: isUpdating
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Row(
                      children: [
                        // ── Time column ──────────────────
                        SizedBox(
                          width: 56,
                          child: Column(
                            children: [
                              Text(
                                appointment.hora,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Icon(
                                _statusIcon(appointment.estado),
                                color: color,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // ── Vertical divider ─────────────
                        Container(
                          width: 3,
                          height: 52,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // ── Info ─────────────────────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      appointment.pacienteNombre,
                                      style: theme
                                          .textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow:
                                          TextOverflow.ellipsis,
                                    ),
                                  ),
                                  _StatusChip(
                                    label: AppointmentStatus.label(
                                      appointment.estado,
                                    ),
                                    color: color,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Odontólogo
                              Row(
                                children: [
                                  Icon(
                                    Icons.medical_services_rounded,
                                    size: 14,
                                    color: theme
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      appointment.odontologoNombre,
                                      style: theme
                                          .textTheme.bodySmall
                                          ?.copyWith(
                                        color: theme.colorScheme
                                            .onSurfaceVariant,
                                      ),
                                      overflow:
                                          TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              // Phone + Type
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_rounded,
                                    size: 14,
                                    color: theme
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    appointment.pacienteTelefono,
                                    style: theme
                                        .textTheme.bodySmall
                                        ?.copyWith(
                                      color: theme.colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  if (appointment.esPrimeraConsulta)
                                    Container(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning
                                            .withValues(
                                                alpha: 0.12),
                                        borderRadius:
                                            BorderRadius
                                                .circular(4),
                                      ),
                                      child: Text(
                                        '1ª consulta',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight:
                                              FontWeight.w600,
                                          color:
                                              AppColors.warning,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (appointment.motivo != null &&
                                  appointment.motivo!
                                      .trim()
                                      .isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  appointment.motivo!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme
                                      .textTheme.bodySmall
                                      ?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: theme.colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!isTerminal)
                          Icon(
                            Icons.chevron_right_rounded,
                            color: theme
                                .colorScheme.onSurfaceVariant
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

// ── Status chip ──────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// APPOINTMENT FORM PAGE
// ══════════════════════════════════════════════════════════════════

class _AppointmentFormResult {
  const _AppointmentFormResult({
    required this.tipo,
    required this.fecha,
    required this.hora,
    required this.odontologoId,
    required this.odontologoNombre,
    required this.pacienteNombre,
    required this.pacienteTelefono,
    this.pacienteId,
    this.nombreTemporal,
    this.telefonoTemporal,
    this.motivo,
    this.notas,
  });

  final String tipo;
  final DateTime fecha;
  final String hora;
  final String odontologoId;
  final String odontologoNombre;
  final String pacienteNombre;
  final String pacienteTelefono;
  final String? pacienteId;
  final String? nombreTemporal;
  final String? telefonoTemporal;
  final String? motivo;
  final String? notas;
}

class _AppointmentFormPage extends StatefulWidget {
  const _AppointmentFormPage();

  @override
  State<_AppointmentFormPage> createState() => _AppointmentFormPageState();
}

class _AppointmentFormPageState extends State<_AppointmentFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for fetching dropdown data
  late final OdontologistController _odontCtrl;
  late final PatientController _patientCtrl;
  late final AppointmentController _apptCtrl;

  // Form state
  String _tipo = AppointmentType.primeraConsulta;
  DateTime _fecha = DateTime.now();
  String? _selectedHora; // from TimeSlotGrid

  // Odontólogo
  String? _odontologoId;
  String _odontologoNombre = '';
  Odontologist? _selectedOdontologist;

  // Time slots
  List<TimeSlot> _slots = [];
  bool _loadingSlots = false;

  // Patient (reconsulta)
  Patient? _selectedPatient;

  // Temporary patient (primera consulta)
  final _nombreTempCtrl = TextEditingController();
  final _telTempCtrl = TextEditingController();

  // Motivo & notas
  final _motivoCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _odontCtrl = getIt<OdontologistController>();
    _patientCtrl = getIt<PatientController>();
    _apptCtrl = getIt<AppointmentController>();
  }

  @override
  void dispose() {
    _nombreTempCtrl.dispose();
    _telTempCtrl.dispose();
    _motivoCtrl.dispose();
    _notasCtrl.dispose();
    _odontCtrl.dispose();
    _patientCtrl.dispose();
    _apptCtrl.dispose();
    super.dispose();
  }

  bool get _isPrimeraConsulta => _tipo == AppointmentType.primeraConsulta;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() => _fecha = picked);
      _loadTimeSlots();
    }
  }

  /// Fetches existing appointments and builds the slot grid.
  Future<void> _loadTimeSlots() async {
    if (_selectedOdontologist == null) return;

    setState(() {
      _loadingSlots = true;
      _selectedHora = null;
      _slots = [];
    });

    try {
      final existing = await _apptCtrl.getByOdontologoAndDate(
        _selectedOdontologist!.id,
        _fecha,
      );

      if (!mounted) return;
      setState(() {
        _slots = TimeSlotGrid.buildSlots(
          horaInicio: _selectedOdontologist!.horaInicio,
          horaFin: _selectedOdontologist!.horaFin,
          fecha: _fecha,
          existingAppointments: existing,
        );
        _loadingSlots = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSlots = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Validate odontologist selected
    if (_odontologoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un odontólogo.')),
      );
      return;
    }

    // Validate time slot selected
    if (_selectedHora == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un horario disponible.')),
      );
      return;
    }

    // Validate patient for reconsulta
    if (!_isPrimeraConsulta && _selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un paciente.')),
      );
      return;
    }

    final pacienteNombre = _isPrimeraConsulta
        ? _nombreTempCtrl.text.trim()
        : _selectedPatient!.nombre;
    final pacienteTelefono = _isPrimeraConsulta
        ? _telTempCtrl.text.trim()
        : _selectedPatient!.telefono;

    Navigator.of(context).pop(
      _AppointmentFormResult(
        tipo: _tipo,
        fecha: _fecha,
        hora: _selectedHora!,
        odontologoId: _odontologoId!,
        odontologoNombre: _odontologoNombre,
        pacienteNombre: pacienteNombre,
        pacienteTelefono: pacienteTelefono,
        pacienteId:
            _isPrimeraConsulta ? null : _selectedPatient!.id,
        nombreTemporal: _isPrimeraConsulta
            ? _nombreTempCtrl.text.trim()
            : null,
        telefonoTemporal: _isPrimeraConsulta
            ? _telTempCtrl.text.trim()
            : null,
        motivo: _motivoCtrl.text.trim().isEmpty
            ? null
            : _motivoCtrl.text.trim(),
        notas: _notasCtrl.text.trim().isEmpty
            ? null
            : _notasCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateText = DateFormat('EEE d MMM yyyy', 'es').format(_fecha);

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva cita')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            // ════════════════════════════════════
            // TIPO DE CONSULTA
            // ════════════════════════════════════
            Text(
              'Tipo de consulta',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: AppointmentType.primeraConsulta,
                  label: Text('1ª consulta'),
                  icon: Icon(Icons.person_add_rounded),
                ),
                ButtonSegment(
                  value: AppointmentType.reconsulta,
                  label: Text('Reconsulta'),
                  icon: Icon(Icons.person_search_rounded),
                ),
              ],
              selected: {_tipo},
              onSelectionChanged: (v) {
                setState(() {
                  _tipo = v.first;
                  _selectedPatient = null;
                });
              },
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ════════════════════════════════════
            // PACIENTE
            // ════════════════════════════════════
            Text(
              'Paciente',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),

            if (_isPrimeraConsulta) ...[
              // Nombre temporal
              TextFormField(
                controller: _nombreTempCtrl,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nombre del paciente',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingresa el nombre.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              // Teléfono temporal
              TextFormField(
                controller: _telTempCtrl,
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
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Ingresa el teléfono.';
                  if (t.length != 8) return 'Debe tener 8 dígitos.';
                  return null;
                },
              ),
            ] else ...[
              // Patient selector (reconsulta)
              AnimatedBuilder(
                animation: _patientCtrl,
                builder: (context, _) {
                  final patients = _patientCtrl.patients
                      .where((p) => p.activo)
                      .toList();

                  if (_patientCtrl.isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (patients.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.warning
                            .withValues(alpha: 0.08),
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: const Text(
                        'No hay pacientes registrados. Registra el paciente primero en el módulo de Pacientes.',
                      ),
                    );
                  }

                  return Autocomplete<Patient>(
                    displayStringForOption: (p) =>
                        '${p.nombre} — DPI: ${p.dpi}',
                    optionsBuilder: (textEditingValue) {
                      final q =
                          textEditingValue.text.trim().toLowerCase();
                      if (q.isEmpty) return patients;
                      return patients.where((p) =>
                          p.nombre.toLowerCase().contains(q) ||
                          p.dpi.contains(q));
                    },
                    onSelected: (p) =>
                        setState(() => _selectedPatient = p),
                    fieldViewBuilder: (context, ctrl, focusNode,
                        onSubmit) {
                      return TextFormField(
                        controller: ctrl,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Buscar paciente',
                          prefixIcon:
                              const Icon(Icons.search_rounded),
                          suffixIcon: _selectedPatient != null
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.success,
                                )
                              : null,
                          hintText: 'Nombre o DPI',
                        ),
                      );
                    },
                  );
                },
              ),
              if (_selectedPatient != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person_rounded,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '${_selectedPatient!.nombre}  •  ${_selectedPatient!.telefono}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            setState(() => _selectedPatient = null),
                        icon: const Icon(Icons.close_rounded,
                            size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.xxl),

            // ════════════════════════════════════
            // ODONTÓLOGO
            // ════════════════════════════════════
            Text(
              'Odontólogo',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),

            AnimatedBuilder(
              animation: _odontCtrl,
              builder: (context, _) {
                final odonts = _odontCtrl.odontologists
                    .where((o) => o.activo)
                    .toList();

                if (_odontCtrl.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                return DropdownButtonFormField<String>(
                  initialValue: _odontologoId,
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar odontólogo',
                    prefixIcon: Icon(Icons.medical_services_rounded),
                  ),
                  items: odonts.map((o) {
                    return DropdownMenuItem(
                      value: o.id,
                      child: Text(o.nombre),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      final o = odonts.firstWhere((o) => o.id == v);
                      setState(() {
                        _odontologoId = v;
                        _odontologoNombre = o.nombre;
                        _selectedOdontologist = o;
                      });
                      _loadTimeSlots();
                    }
                  },
                  validator: (v) =>
                      v == null ? 'Selecciona un odontólogo.' : null,
                );
              },
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ════════════════════════════════════
            // FECHA Y DISPONIBILIDAD
            // ════════════════════════════════════
            Text(
              'Fecha y disponibilidad',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),

            // Date picker
            InkWell(
              onTap: _pickDate,
              borderRadius: AppSpacing.borderRadiusSm,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                ),
                child: Text(dateText),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Time slot grid or placeholder
            if (_selectedOdontologist == null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.06),
                  borderRadius: AppSpacing.borderRadiusSm,
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: AppColors.info),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Selecciona un odontólogo para ver los horarios disponibles.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_loadingSlots)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              TimeSlotGrid(
                slots: _slots,
                selectedSlot: _selectedHora,
                onSlotSelected: (hora) =>
                    setState(() => _selectedHora = hora),
                odontologoNombre: _odontologoNombre,
                fechaLabel: dateText,
              ),
              if (_selectedHora != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: AppSpacing.borderRadiusSm,
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 20, color: AppColors.success),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Horario seleccionado: $_selectedHora',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.xxl),

            // ════════════════════════════════════
            // MOTIVO Y NOTAS
            // ════════════════════════════════════
            Text(
              'Motivo y notas',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _motivoCtrl,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Motivo de consulta (opcional)',
                prefixIcon: Icon(Icons.description_rounded),
                hintText: 'Ej: Limpieza, dolor muela, etc.',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            TextFormField(
              controller: _notasCtrl,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                prefixIcon: Icon(Icons.notes_rounded),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Submit ─────────────────────────
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.event_available_rounded),
              label: const Text('Agendar cita'),
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
