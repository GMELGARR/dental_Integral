import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_mode_button.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/treatment.dart';
import '../controllers/treatment_controller.dart';

class TreatmentManagementPage extends StatefulWidget {
  const TreatmentManagementPage({super.key});

  @override
  State<TreatmentManagementPage> createState() =>
      _TreatmentManagementPageState();
}

class _TreatmentManagementPageState extends State<TreatmentManagementPage> {
  late final TreatmentController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<TreatmentController>();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Create treatment ───────────────────────────────────────────
  Future<void> _create() async {
    final result = await showModalBottomSheet<_TreatmentFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _TreatmentFormSheet(),
    );

    if (result == null || !mounted) return;

    final success = await _controller.create(
      nombre: result.nombre,
      monto: result.monto,
      descripcion: result.descripcion,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Tratamiento "${result.nombre}" registrado.'
              : (_controller.errorMessage ??
                  'No se pudo registrar el tratamiento.'),
        ),
      ),
    );
  }

  // ── Edit treatment ─────────────────────────────────────────────
  Future<void> _edit(Treatment item) async {
    final result = await showModalBottomSheet<_TreatmentFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TreatmentFormSheet(existing: item),
    );

    if (result == null || !mounted) return;

    final success = await _controller.update(
      id: item.id,
      nombre: result.nombre,
      monto: result.monto,
      activo: result.activo,
      descripcion: result.descripcion,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Tratamiento "${result.nombre}" actualizado.'
              : (_controller.errorMessage ??
                  'No se pudo actualizar el tratamiento.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          // ── FAB ────────────────────────────────────────────
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
              _controller.isSaving ? 'Guardando...' : 'Nuevo tratamiento',
            ),
          ),
          body: CustomScrollView(
            slivers: [
              // ── Gradient header ────────────────────────
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
                              Icons.healing_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Servicios / Tratamientos',
                                style:
                                    theme.textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${_controller.treatments.length} tratamiento(s)',
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

              // ── Info card ──────────────────────────────
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
                              'Catálogo de servicios y tratamientos con sus montos.',
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

              // ── Treatment list ─────────────────────────
              if (_controller.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_controller.treatments.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.healing_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Sin tratamientos registrados',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Presiona "Nuevo tratamiento" para agregar uno.',
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
                        final item = _controller.treatments[index];
                        final isUpdating = _controller.updatingId == item.id;

                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _TreatmentCard(
                            treatment: item,
                            isDark: isDark,
                            isUpdating: isUpdating,
                            onEdit: () => _edit(item),
                          ),
                        );
                      },
                      childCount: _controller.treatments.length,
                    ),
                  ),
                ),

              // Bottom padding
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

class _TreatmentFormResult {
  const _TreatmentFormResult({
    required this.nombre,
    required this.monto,
    required this.activo,
    this.descripcion,
  });

  final String nombre;
  final double monto;
  final bool activo;
  final String? descripcion;
}

// ═══════════════════════════════════════════════════════════════════
// CREATE / EDIT SHEET
// ═══════════════════════════════════════════════════════════════════

class _TreatmentFormSheet extends StatefulWidget {
  const _TreatmentFormSheet({this.existing});

  final Treatment? existing;

  @override
  State<_TreatmentFormSheet> createState() => _TreatmentFormSheetState();
}

class _TreatmentFormSheetState extends State<_TreatmentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _montoCtrl;
  late final TextEditingController _descripcionCtrl;
  late bool _activo;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nombreCtrl = TextEditingController(text: e?.nombre ?? '');
    _montoCtrl = TextEditingController(
      text: e != null ? e.monto.toStringAsFixed(2) : '',
    );
    _descripcionCtrl = TextEditingController(text: e?.descripcion ?? '');
    _activo = e?.activo ?? true;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _montoCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final monto = double.tryParse(_montoCtrl.text.trim()) ?? 0;

    Navigator.of(context).pop(
      _TreatmentFormResult(
        nombre: _nombreCtrl.text.trim(),
        monto: monto,
        activo: _activo,
        descripcion: _descripcionCtrl.text.trim().isEmpty
            ? null
            : _descripcionCtrl.text.trim(),
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
                            : Icons.healing_rounded,
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
                                ? 'Editar tratamiento'
                                : 'Nuevo tratamiento',
                            style: theme.textTheme.titleLarge,
                          ),
                          Text(
                            _isEditing
                                ? 'Modifica los datos del servicio'
                                : 'Registra un servicio o tratamiento',
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
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del tratamiento',
                    prefixIcon: Icon(Icons.healing_outlined),
                  ),
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) {
                      return 'Ingresa el nombre.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Monto ───────────────────────────
                TextFormField(
                  controller: _montoCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Monto (Q)',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                    prefixText: 'Q ',
                    hintText: '0.00',
                  ),
                  validator: (v) {
                    final text = v?.trim() ?? '';
                    if (text.isEmpty) return 'Ingresa el monto.';
                    final parsed = double.tryParse(text);
                    if (parsed == null || parsed < 0) {
                      return 'Monto inválido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Descripción ─────────────────────
                TextFormField(
                  controller: _descripcionCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    prefixIcon: Icon(Icons.notes_rounded),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Active toggle (solo edición) ────
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
                  const SizedBox(height: AppSpacing.lg),
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
                                : Icons.add_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _isEditing ? 'Guardar' : 'Registrar',
                          ),
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
// TREATMENT CARD
// ═══════════════════════════════════════════════════════════════════

class _TreatmentCard extends StatelessWidget {
  const _TreatmentCard({
    required this.treatment,
    required this.isDark,
    required this.isUpdating,
    required this.onEdit,
  });

  final Treatment treatment;
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
          // ── Icon ─────────────────────────────────
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: treatment.activo
                  ? const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
                    )
                  : LinearGradient(
                      colors: [Colors.grey.shade400, Colors.grey.shade300],
                    ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.healing_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),

          // ── Details ──────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  treatment.nombre,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Q ${treatment.monto.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (treatment.descripcion != null &&
                    treatment.descripcion!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    treatment.descripcion!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                StatusBadge(
                  label: treatment.activo ? 'Activo' : 'Inactivo',
                  active: treatment.activo,
                ),
              ],
            ),
          ),

          // ── Edit button ──────────────────────────
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
                  tooltip: 'Editar tratamiento',
                ),
        ],
      ),
    );
  }
}
