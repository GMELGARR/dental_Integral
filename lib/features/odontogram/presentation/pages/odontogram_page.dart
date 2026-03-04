import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../auth/presentation/controllers/auth_session_controller.dart';
import '../../domain/entities/odontogram.dart';
import '../controllers/odontogram_controller.dart';
import '../widgets/condition_palette.dart';
import '../widgets/tooth_widget.dart';

class OdontogramPage extends StatefulWidget {
  const OdontogramPage({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  final String patientId;
  final String patientName;

  @override
  State<OdontogramPage> createState() => _OdontogramPageState();
}

class _OdontogramPageState extends State<OdontogramPage> {
  late final OdontogramController _controller;
  late final String _currentUserName;

  @override
  void initState() {
    super.initState();
    _controller = getIt<OdontogramController>();
    _controller.startObserving(widget.patientId);
    _controller.addListener(_onChanged);

    final session = getIt<AuthSessionController>();
    _currentUserName = session.currentUser?.email ?? 'desconocido';
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onFaceTap(String toothNumber, ToothFace face) {
    final condition = _controller.selectedCondition;
    if (condition.appliesToWholeTooth) {
      _controller.applyToWholeTooth(
        toothNumber: toothNumber,
        modifiedBy: _currentUserName,
      );
    } else {
      _controller.applyToFace(
        toothNumber: toothNumber,
        face: face,
        modifiedBy: _currentUserName,
      );
    }
  }

  void _onToothLongPress(String toothNumber) {
    _controller.applyToWholeTooth(
      toothNumber: toothNumber,
      modifiedBy: _currentUserName,
    );
  }

  void _showHistory() {
    final odontogram = _controller.odontogram;
    if (odontogram == null) return;

    final dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'es');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) => SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (ctx, scrollCtrl) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.3),
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const Icon(Icons.history_rounded,
                        color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Historial de cambios',
                        style: theme.textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: odontogram.historial.isEmpty
                      ? Center(
                          child: Text(
                            'Sin cambios registrados aún.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        )
                      : ListView.builder(
                          controller: scrollCtrl,
                          itemCount: odontogram.historial.length,
                          itemBuilder: (_, i) {
                            final change = odontogram.historial[i];
                            return Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm),
                              child: Container(
                                padding:
                                    const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.cardDark
                                      : AppColors.cardLight,
                                  borderRadius: AppSpacing.borderRadiusMd,
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            AppSpacing.borderRadiusSm,
                                      ),
                                      child: Center(
                                        child: Text(
                                          change.diente,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            change.descripcion,
                                            style: theme
                                                .textTheme.bodySmall
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w600),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${dateFmt.format(change.fecha)} • ${change.modificadoPor}',
                                            style: theme
                                                .textTheme.bodySmall
                                                ?.copyWith(fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLegend() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.3),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Leyenda de colores',
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              ...ToothCondition.values.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: conditionColor(c),
                            borderRadius: AppSpacing.borderRadiusSm,
                            border: Border.all(
                              color:
                                  isDark ? Colors.white24 : Colors.black12,
                            ),
                          ),
                          child: c == ToothCondition.extraccion
                              ? const Icon(Icons.close,
                                  size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          c.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          c.appliesToWholeTooth
                              ? 'Pieza completa'
                              : 'Por cara',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: AppSpacing.borderRadiusMd,
                  border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: AppColors.info),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Toca una cara del diente para marcarla.\n'
                        'Mantén presionado para aplicar al diente completo.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── BUILD ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // ── Header ──────────────────────────────────
          GradientHeader(
            height: 140,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Odontograma',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.patientName,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _showLegend,
                  tooltip: 'Leyenda',
                  icon: const Icon(Icons.help_outline_rounded,
                      color: Colors.white),
                ),
                IconButton(
                  onPressed: _showHistory,
                  tooltip: 'Historial',
                  icon: const Icon(Icons.history_rounded,
                      color: Colors.white),
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────
          Expanded(
            child: _controller.loading
                ? const Center(child: CircularProgressIndicator())
                : _controller.error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: AppColors.error),
                              const SizedBox(height: AppSpacing.md),
                              Text(_controller.error!,
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      )
                    : _buildDiagram(theme, isDark),
          ),

          // ── Condition palette ───────────────────────
          ConditionPalette(
            selected: _controller.selectedCondition,
            onSelected: _controller.selectCondition,
          ),
        ],
      ),
    );
  }

  Widget _buildDiagram(ThemeData theme, bool isDark) {
    final odontogram = _controller.odontogram;
    if (odontogram == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        children: [
          // ── Upper arch label ─────────────────────
          Text(
            'Arcada Superior',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Upper Right (18-11) + Upper Left (21-28) ──
          _buildDentalRow(
            odontogram,
            [...Odontogram.upperRight, ...Odontogram.upperLeft],
            isDark,
          ),

          const SizedBox(height: AppSpacing.sm),

          // Divider line
          Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppSpacing.borderRadiusSm,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Lower Right (48-41) + Lower Left (31-38) ──
          _buildDentalRow(
            odontogram,
            [...Odontogram.lowerRight, ...Odontogram.lowerLeft],
            isDark,
          ),

          const SizedBox(height: AppSpacing.sm),
          Text(
            'Arcada Inferior',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Stats summary ───────────────────────
          _buildStatsSummary(odontogram, theme, isDark),
        ],
      ),
    );
  }

  Widget _buildDentalRow(
      Odontogram odontogram, List<String> teeth, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: teeth.asMap().entries.map((entry) {
          final idx = entry.key;
          final number = entry.value;
          final toothState = odontogram.toothState(number);

          return Row(
            children: [
              ToothWidget(
                toothNumber: number,
                state: toothState,
                onFaceTap: (face) => _onFaceTap(number, face),
                onLongPress: () => _onToothLongPress(number),
                size: 42,
              ),
              // Add separator between quadrants (after 8th tooth)
              if (idx == 7)
                Container(
                  width: 2,
                  height: 54,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsSummary(
      Odontogram odontogram, ThemeData theme, bool isDark) {
    int sanos = 0;
    int conCaries = 0;
    int obturados = 0;
    int extraidos = 0;
    int ausentes = 0;
    int otros = 0;

    for (final number in Odontogram.allTeeth) {
      final tooth = odontogram.toothState(number);
      if (tooth.wholeTooth != null) {
        switch (tooth.wholeTooth!) {
          case ToothCondition.extraccion:
            extraidos++;
            break;
          case ToothCondition.ausente:
            ausentes++;
            break;
          case ToothCondition.corona:
          case ToothCondition.endodoncia:
          case ToothCondition.protesisFija:
            otros++;
            break;
          default:
            break;
        }
      } else if (tooth.faces.isEmpty) {
        sanos++;
      } else {
        for (final c in tooth.faces.values) {
          if (c == ToothCondition.caries) {
            conCaries++;
            break;
          } else if (c == ToothCondition.obturacion ||
              c == ToothCondition.sellante) {
            obturados++;
            break;
          }
        }
      }
    }

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen dental',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _StatBadge(
                  label: 'Sanos',
                  count: sanos,
                  color: Colors.white,
                  isDark: isDark),
              _StatBadge(
                  label: 'Caries',
                  count: conCaries,
                  color: conditionColor(ToothCondition.caries),
                  isDark: isDark),
              _StatBadge(
                  label: 'Obturados',
                  count: obturados,
                  color: conditionColor(ToothCondition.obturacion),
                  isDark: isDark),
              _StatBadge(
                  label: 'Extraídos',
                  count: extraidos,
                  color: conditionColor(ToothCondition.extraccion),
                  isDark: isDark),
              _StatBadge(
                  label: 'Ausentes',
                  count: ausentes,
                  color: conditionColor(ToothCondition.ausente),
                  isDark: isDark),
              _StatBadge(
                  label: 'Otros',
                  count: otros,
                  color: conditionColor(ToothCondition.corona),
                  isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.label,
    required this.count,
    required this.color,
    required this.isDark,
  });

  final String label;
  final int count;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.black12,
              ),
            ),
            child: Center(
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color == Colors.white ? Colors.black87 : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 9),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
