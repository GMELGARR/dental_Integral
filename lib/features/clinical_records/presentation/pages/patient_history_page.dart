import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../domain/entities/clinical_record.dart';
import '../controllers/clinical_record_controller.dart';

/// Shows all clinical records for a specific patient (timeline view).
class PatientHistoryPage extends StatefulWidget {
  const PatientHistoryPage({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  final String patientId;
  final String patientName;

  @override
  State<PatientHistoryPage> createState() => _PatientHistoryPageState();
}

class _PatientHistoryPageState extends State<PatientHistoryPage> {
  late final ClinicalRecordController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<ClinicalRecordController>();
    _controller.loadByPatient(widget.patientId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────
          GradientHeader(
            height: 140,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                            'Historial Clínico',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.patientName,
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

          // ── Body ──────────────────────────────────────────
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (_controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_controller.errorMessage != null) {
                  return Center(
                    child: Text(
                      _controller.errorMessage!,
                      style: TextStyle(color: AppColors.error),
                    ),
                  );
                }

                final records = _controller.records;
                if (records.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded,
                            size: 64,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Sin registros clínicos',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Los registros aparecerán al completar citas.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: AppSpacing.pagePadding,
                  itemCount: records.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (_, i) =>
                      _RecordCard(record: records[i], isDark: isDark),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// RECORD CARD
// ═══════════════════════════════════════════════════════════════════

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record, required this.isDark});

  final ClinicalRecord record;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd/MM/yyyy', 'es');

    return Container(
      decoration: BoxDecoration(
        gradient:
            isDark ? AppColors.cardGradientDark : AppColors.cardGradientLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppSpacing.borderRadiusLg,
        child: InkWell(
          borderRadius: AppSpacing.borderRadiusLg,
          onTap: () => _showDetail(context, record),
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Date + odontólogo ──────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.medical_services_rounded,
                          size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateFmt.format(record.fecha),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Dr. ${record.odontologoNombre}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Total badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Q${record.costoTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Diagnóstico preview ──────────────────
                if (record.diagnostico != null &&
                    record.diagnostico!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    record.diagnostico!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],

                // ── Treatment chips ──────────────────────
                if (record.tratamientos.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: record.tratamientos
                        .map((t) => Chip(
                              label: Text(t.nombre,
                                  style: const TextStyle(fontSize: 11)),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.zero,
                              labelPadding: const EdgeInsets.symmetric(
                                  horizontal: 6),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Full detail bottom sheet ──────────────────────────────────
  void _showDetail(BuildContext context, ClinicalRecord r) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd MMM yyyy', 'es');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (_, scrollCtrl) {
            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Title
                Text(
                  dateFmt.format(r.fecha),
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Dr. ${r.odontologoNombre}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Divider(height: AppSpacing.xxl),

                // Diagnóstico
                if (_hasText(r.diagnostico))
                  _DetailSection(
                    icon: Icons.search_rounded,
                    title: 'Diagnóstico',
                    content: r.diagnostico!,
                  ),

                // Piezas
                if (_hasText(r.piezasDentales))
                  _DetailSection(
                    icon: Icons.grid_view_rounded,
                    title: 'Piezas dentales',
                    content: r.piezasDentales!,
                  ),

                // Tratamientos table
                if (r.tratamientos.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.medical_services_rounded,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Tratamientos',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...r.tratamientos.map((t) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${t.nombre} ×${t.cantidad}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              'Q${t.subtotal.toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal'),
                      Text('Q${r.subtotal.toStringAsFixed(2)}'),
                    ],
                  ),
                  if (r.descuentoMonto > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Descuento'),
                        Text(
                          '-Q${r.descuentoMonto.toStringAsFixed(2)}',
                          style: TextStyle(color: AppColors.success),
                        ),
                      ],
                    ),
                  if (r.cargoExtra > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(r.notaCargoExtra != null &&
                                r.notaCargoExtra!.isNotEmpty
                            ? 'Cargo extra (${r.notaCargoExtra})'
                            : 'Cargo extra'),
                        Text('+Q${r.cargoExtra.toStringAsFixed(2)}'),
                      ],
                    ),
                  ],
                  const Divider(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Q${r.costoTotal.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Notas
                if (_hasText(r.notasClinicas))
                  _DetailSection(
                    icon: Icons.notes_rounded,
                    title: 'Notas clínicas',
                    content: r.notasClinicas!,
                  ),

                // Indicaciones
                if (_hasText(r.indicaciones))
                  _DetailSection(
                    icon: Icons.assignment_turned_in_rounded,
                    title: 'Indicaciones al paciente',
                    content: r.indicaciones!,
                  ),

                // Próxima cita
                if (_hasText(r.proximaCitaSugerida))
                  _DetailSection(
                    icon: Icons.event_rounded,
                    title: 'Próxima cita sugerida',
                    content: r.proximaCitaSugerida!,
                  ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            );
          },
        );
      },
    );
  }

  bool _hasText(String? v) => v != null && v.trim().isNotEmpty;
}

// ═══════════════════════════════════════════════════════════════════
// DETAIL SECTION
// ═══════════════════════════════════════════════════════════════════

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.content,
  });

  final IconData icon;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(content, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
