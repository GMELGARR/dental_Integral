import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../treatments/domain/entities/treatment.dart';
import '../../../treatments/presentation/controllers/treatment_controller.dart';
import '../../domain/entities/tratamiento_realizado.dart';
import '../controllers/clinical_record_controller.dart';

/// Full-page form to create a clinical record when completing an appointment.
class ClinicalRecordFormPage extends StatefulWidget {
  const ClinicalRecordFormPage({super.key, required this.appointment});

  final Appointment appointment;

  @override
  State<ClinicalRecordFormPage> createState() => _ClinicalRecordFormPageState();
}

class _ClinicalRecordFormPageState extends State<ClinicalRecordFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final ClinicalRecordController _controller;
  late final TreatmentController _treatmentController;

  // ── Text controllers ────────────────────────────────────────
  final _diagnosticoCtrl = TextEditingController();
  final _piezasCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  final _indicacionesCtrl = TextEditingController();
  final _proximaCitaCtrl = TextEditingController();
  final _descuentoCtrl = TextEditingController(text: '0');
  final _cargoExtraCtrl = TextEditingController(text: '0');
  final _notaCargoExtraCtrl = TextEditingController();

  // ── Cart state ──────────────────────────────────────────────
  final List<TratamientoRealizado> _cart = [];

  // ── Autocomplete references ────────────────────────────────
  FocusNode? _autocompleteFocusNode;
  TextEditingController? _autocompleteTextCtrl;

  double get _subtotal =>
      _cart.fold(0.0, (sum, item) => sum + item.subtotal);

  double get _descuentoMonto {
    final v = double.tryParse(_descuentoCtrl.text) ?? 0;
    return v.clamp(0, double.infinity);
  }

  double get _cargoExtra =>
      (double.tryParse(_cargoExtraCtrl.text) ?? 0).clamp(0, double.infinity);

  double get _total {
    final afterDiscount = _subtotal - _descuentoMonto;
    return (afterDiscount < 0 ? 0 : afterDiscount) + _cargoExtra;
  }

  @override
  void initState() {
    super.initState();
    _controller = getIt<ClinicalRecordController>();
    _treatmentController = getIt<TreatmentController>();
  }

  @override
  void dispose() {
    _diagnosticoCtrl.dispose();
    _piezasCtrl.dispose();
    _notasCtrl.dispose();
    _indicacionesCtrl.dispose();
    _proximaCitaCtrl.dispose();
    _descuentoCtrl.dispose();
    _cargoExtraCtrl.dispose();
    _notaCargoExtraCtrl.dispose();
    _controller.dispose();
    _treatmentController.dispose();
    super.dispose();
  }

  // ── Add treatment from catalogue ──────────────────────────────
  void _addTreatment(Treatment t) {
    // If already in cart, increment quantity.
    final idx = _cart.indexWhere((c) => c.tratamientoId == t.id);
    if (idx >= 0) {
      setState(() {
        _cart[idx] = _cart[idx].copyWith(cantidad: _cart[idx].cantidad + 1);
      });
    } else {
      setState(() {
        _cart.add(TratamientoRealizado(
          tratamientoId: t.id,
          nombre: t.nombre,
          precioUnitario: t.monto,
        ));
      });
    }
    // Clear search field and dismiss keyboard/dropdown.
    _autocompleteTextCtrl?.clear();
    _autocompleteFocusNode?.unfocus();
  }

  void _removeItem(int index) {
    setState(() => _cart.removeAt(index));
  }

  void _updateQuantity(int index, int delta) {
    final current = _cart[index].cantidad + delta;
    if (current < 1) return;
    setState(() {
      _cart[index] = _cart[index].copyWith(cantidad: current);
    });
  }

  void _updatePrice(int index, double newPrice) {
    setState(() {
      _cart[index] = _cart[index].copyWith(precioUnitario: newPrice);
    });
  }

  // ── Submit ─────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agregue al menos un tratamiento realizado.'),
        ),
      );
      return;
    }

    final appt = widget.appointment;
    final ok = await _controller.create(
      citaId: appt.id,
      pacienteId: appt.pacienteId ?? '',
      pacienteNombre: appt.pacienteNombre,
      odontologoId: appt.odontologoId,
      odontologoNombre: appt.odontologoNombre,
      fecha: appt.fecha,
      tratamientos: _cart,
      subtotal: _subtotal,
      descuentoMonto: _descuentoMonto,
      cargoExtra: _cargoExtra,
      costoTotal: _total,
      diagnostico: _diagnosticoCtrl.text.trim().isEmpty
          ? null
          : _diagnosticoCtrl.text.trim(),
      piezasDentales:
          _piezasCtrl.text.trim().isEmpty ? null : _piezasCtrl.text.trim(),
      notasClinicas:
          _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      indicaciones: _indicacionesCtrl.text.trim().isEmpty
          ? null
          : _indicacionesCtrl.text.trim(),
      proximaCitaSugerida: _proximaCitaCtrl.text.trim().isEmpty
          ? null
          : _proximaCitaCtrl.text.trim(),
      notaCargoExtra: _notaCargoExtraCtrl.text.trim().isEmpty
          ? null
          : _notaCargoExtraCtrl.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true); // signal success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.errorMessage ?? 'Error al guardar.',
          ),
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────
          GradientHeader(
            height: 140,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Registro Clínico',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.appointment.pacienteNombre,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Form body ───────────────────────────────────────
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  behavior: HitTestBehavior.translucent,
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: AppSpacing.pagePadding,
                      children: [
                        // ── Diagnóstico ───────────────────────
                      _SectionLabel('Diagnóstico'),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _diagnosticoCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Diagnóstico del paciente...',
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Piezas dentales ───────────────────
                      _SectionLabel('Piezas dentales tratadas'),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _piezasCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Ej: 14, 15, 36...',
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Tratamientos (cart) ───────────────
                      _SectionLabel('Tratamientos realizados'),
                      const SizedBox(height: AppSpacing.sm),
                      _buildTreatmentPicker(isDark),
                      const SizedBox(height: AppSpacing.sm),
                      ..._buildCartItems(isDark),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Resumen financiero ─────────────────
                      _buildFinancialSummary(theme, isDark),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Notas clínicas ─────────────────────
                      _SectionLabel('Notas clínicas'),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _notasCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Observaciones durante la consulta...',
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Indicaciones ───────────────────────
                      _SectionLabel('Indicaciones al paciente'),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _indicacionesCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText:
                              'Cuidados post-tratamiento, medicamentos...',
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Próxima cita ───────────────────────
                      _SectionLabel('Próxima cita sugerida'),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _proximaCitaCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Ej: En 2 semanas, 1 mes...',
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxxl),

                      // ── Save button ────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _controller.isSaving ? null : _save,
                          icon: _controller.isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(
                            _controller.isSaving
                                ? 'Guardando...'
                                : 'Guardar y completar cita',
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Treatment picker (autocomplete dropdown) ──────────────────
  Widget _buildTreatmentPicker(bool isDark) {
    return AnimatedBuilder(
      animation: _treatmentController,
      builder: (context, _) {
        final available = _treatmentController.treatments
            .where((t) => t.activo)
            .toList();

        if (_treatmentController.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(
                child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }

        return Autocomplete<Treatment>(
          displayStringForOption: (t) => t.nombre,
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) return available;
            final q = textEditingValue.text.toLowerCase();
            return available
                .where((t) => t.nombre.toLowerCase().contains(q));
          },
          onSelected: (t) => _addTreatment(t),
          fieldViewBuilder:
              (ctx, textCtrl, focusNode, onFieldSubmitted) {
            // Store references to clear/dismiss from outside.
            _autocompleteFocusNode = focusNode;
            _autocompleteTextCtrl = textCtrl;

            return TextFormField(
              controller: textCtrl,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'Buscar tratamiento...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: () {
                    // find exact match
                    final match = available
                        .where((t) =>
                            t.nombre.toLowerCase() ==
                            textCtrl.text.toLowerCase())
                        .firstOrNull;
                    if (match != null) {
                      _addTreatment(match);
                      textCtrl.clear();
                    }
                  },
                ),
              ),
            );
          },
          optionsViewBuilder: (ctx, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: AppSpacing.borderRadiusMd,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (_, i) {
                      final t = options.elementAt(i);
                      return ListTile(
                        dense: true,
                        title: Text(t.nombre),
                        trailing: Text(
                          'Q${t.monto.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () => onSelected(t),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Cart list items ───────────────────────────────────────────
  List<Widget> _buildCartItems(bool isDark) {
    if (_cart.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.cardDark.withValues(alpha: 0.5)
                : AppColors.surfaceLight,
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(
              color: isDark
                  ? AppColors.dividerDark
                  : AppColors.dividerLight,
            ),
          ),
          child: Center(
            child: Text(
              'No se han agregado tratamientos',
              style: TextStyle(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
          ),
        ),
      ];
    }

    return List.generate(_cart.length, (i) {
      final item = _cart[i];
      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color:
                isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + delete
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                InkWell(
                  onTap: () => _removeItem(i),
                  borderRadius: AppSpacing.borderRadiusSm,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close,
                        size: 18, color: AppColors.error),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Price + quantity + subtotal
            Row(
              children: [
                // Editable price
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    initialValue: item.precioUnitario.toStringAsFixed(2),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      prefixText: 'Q',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (v) {
                      final p = double.tryParse(v);
                      if (p != null) _updatePrice(i, p);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Quantity controls
                _QtyControl(
                  value: item.cantidad,
                  onMinus: () => _updateQuantity(i, -1),
                  onPlus: () => _updateQuantity(i, 1),
                ),
                const Spacer(),
                // Subtotal
                Text(
                  'Q${item.subtotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // ── Financial summary ─────────────────────────────────────────
  Widget _buildFinancialSummary(ThemeData theme, bool isDark) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.cardGradientDark
            : AppColors.cardGradientLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Column(
        children: [
          // Subtotal row
          _SummaryRow(
            label: 'Subtotal',
            value: 'Q${_subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: AppSpacing.md),

          // Descuento (monto fijo)
          Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text('Descuento'),
              ),
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: _descuentoCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    prefixText: 'Q',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Cargo extra
          Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text('Cargo extra'),
              ),
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: _cargoExtraCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    prefixText: 'Q',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),

          // Nota cargo extra (only if cargo extra > 0)
          if (_cargoExtra > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _notaCargoExtraCtrl,
              decoration: const InputDecoration(
                hintText: 'Nota del cargo extra...',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],

          const Divider(height: AppSpacing.xxl),

          // Total
          _SummaryRow(
            label: 'TOTAL',
            value: 'Q${_total.toStringAsFixed(2)}',
            isBold: true,
            valueColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SMALL HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            fontSize: isBold ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            fontSize: isBold ? 18 : 14,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _QtyControl extends StatelessWidget {
  const _QtyControl({
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _qtyButton(Icons.remove, onMinus),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '$value',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        _qtyButton(Icons.add, onPlus),
      ],
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }
}
