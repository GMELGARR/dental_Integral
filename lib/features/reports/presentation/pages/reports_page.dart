import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../billing/domain/entities/payment.dart';
import '../../domain/entities/report_data.dart';
import '../controllers/reports_controller.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  late final ReportsController _ctrl;
  late final TabController _tabCtrl;

  static final _currFmt = NumberFormat('#,##0.00', 'en');

  @override
  void initState() {
    super.initState();
    _ctrl = getIt<ReportsController>();
    _ctrl.addListener(_onChanged);
    _ctrl.refresh();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onChanged);
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // ── Header ──
          GradientHeader(
            height: 170,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BackButton(color: Colors.white),
                    const Spacer(),
                    IconButton(
                      onPressed: _ctrl.refresh,
                      tooltip: 'Actualizar',
                      icon:
                          const Icon(Icons.refresh_rounded, color: Colors.white),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'Reportes y Estadísticas',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Análisis de la clínica',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),

          // ── Period selector ──
          _PeriodSelector(ctrl: _ctrl),

          // ── Tabs ──
          Container(
            color: isDark ? AppColors.cardDark : Colors.white,
            child: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: AppColors.primary,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Ingresos'),
                Tab(text: 'Citas'),
                Tab(text: 'Tratamientos'),
                Tab(text: 'Productividad'),
              ],
            ),
          ),

          // ── Body ──
          Expanded(
            child: _ctrl.loading
                ? const Center(child: CircularProgressIndicator())
                : _ctrl.error != null
                    ? Center(
                        child: Padding(
                          padding: AppSpacing.cardPaddingLarge,
                          child: Text(_ctrl.error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: theme.colorScheme.error)),
                        ),
                      )
                    : _ctrl.data == null
                        ? const Center(child: Text('Sin datos'))
                        : TabBarView(
                            controller: _tabCtrl,
                            children: [
                              _IncomeTab(
                                  data: _ctrl.data!,
                                  isDark: isDark,
                                  theme: theme,
                                  fmt: _currFmt),
                              _AppointmentsTab(
                                  data: _ctrl.data!,
                                  isDark: isDark,
                                  theme: theme),
                              _TreatmentsTab(
                                  data: _ctrl.data!,
                                  isDark: isDark,
                                  theme: theme),
                              _ProductivityTab(
                                  data: _ctrl.data!,
                                  isDark: isDark,
                                  theme: theme,
                                  fmt: _currFmt),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Period selector
// ══════════════════════════════════════════════════════════════════

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.ctrl});
  final ReportsController ctrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      color: isDark ? AppColors.cardDark : Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ReportPeriod.values.map((p) {
            final sel = ctrl.period == p;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(p.label),
                selected: sel,
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                  color: sel ? AppColors.primary : null,
                ),
                onSelected: (_) {
                  if (p == ReportPeriod.personalizado) {
                    _pickRange(context);
                  } else {
                    ctrl.selectPeriod(p);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: ctrl.customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
    );
    if (picked != null) {
      ctrl.setCustomRange(picked);
    }
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 1 — Ingresos
// ══════════════════════════════════════════════════════════════════

class _IncomeTab extends StatelessWidget {
  const _IncomeTab({
    required this.data,
    required this.isDark,
    required this.theme,
    required this.fmt,
  });

  final ReportData data;
  final bool isDark;
  final ThemeData theme;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.cardPaddingLarge,
      children: [
        // Summary cards
        _SummaryRow(children: [
          _StatCard(
            label: 'Ingresos totales',
            value: 'Q ${fmt.format(data.totalIngresos)}',
            icon: Icons.attach_money_rounded,
            color: const Color(0xFF43A047),
            isDark: isDark,
          ),
          _StatCard(
            label: 'Total pagos',
            value: data.ingresosPorDia.values
                .fold<int>(0, (s, _) => s + 1)
                .toString(),
            icon: Icons.receipt_rounded,
            color: const Color(0xFF1E88E5),
            isDark: isDark,
          ),
        ]),
        const SizedBox(height: AppSpacing.xl),

        // Bar chart — ingresos por día
        if (data.ingresosPorDia.isNotEmpty) ...[
          Text('Ingresos por día',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          _ChartCard(
            isDark: isDark,
            height: 220,
            child: _IncomeDailyChart(
              data: data.ingresosPorDia,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        // Pie chart — ingresos por método
        if (data.ingresosPorMetodo.isNotEmpty) ...[
          Text('Por método de pago',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          _ChartCard(
            isDark: isDark,
            height: 200,
            child: _PaymentMethodPie(
              data: data.ingresosPorMetodo,
              total: data.totalIngresos,
              fmt: fmt,
            ),
          ),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 2 — Citas
// ══════════════════════════════════════════════════════════════════

class _AppointmentsTab extends StatelessWidget {
  const _AppointmentsTab({
    required this.data,
    required this.isDark,
    required this.theme,
  });

  final ReportData data;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final completadas = data.citasPorEstado['completada'] ?? 0;
    final canceladas = data.citasPorEstado['cancelada'] ?? 0;
    final noAsistio = data.citasPorEstado['no_asistio'] ?? 0;

    return ListView(
      padding: AppSpacing.cardPaddingLarge,
      children: [
        _SummaryRow(children: [
          _StatCard(
            label: 'Total citas',
            value: '${data.totalCitas}',
            icon: Icons.event_note_rounded,
            color: const Color(0xFF7C4DFF),
            isDark: isDark,
          ),
          _StatCard(
            label: 'Completadas',
            value: '$completadas',
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF43A047),
            isDark: isDark,
          ),
        ]),
        const SizedBox(height: AppSpacing.sm),
        _SummaryRow(children: [
          _StatCard(
            label: 'Canceladas',
            value: '$canceladas',
            icon: Icons.cancel_rounded,
            color: const Color(0xFFE53935),
            isDark: isDark,
          ),
          _StatCard(
            label: 'No asistió',
            value: '$noAsistio',
            icon: Icons.person_off_rounded,
            color: const Color(0xFFFF9800),
            isDark: isDark,
          ),
        ]),
        const SizedBox(height: AppSpacing.xl),

        // Pie chart — estados
        if (data.citasPorEstado.isNotEmpty) ...[
          Text('Distribución por estado',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          _ChartCard(
            isDark: isDark,
            height: 200,
            child: _AppointmentStatusPie(data: data.citasPorEstado),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        // Bar chart — citas por día
        if (data.citasPorDia.isNotEmpty) ...[
          Text('Citas por día',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          _ChartCard(
            isDark: isDark,
            height: 220,
            child: _AppointmentDailyChart(
              data: data.citasPorDia,
              isDark: isDark,
            ),
          ),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 3 — Tratamientos
// ══════════════════════════════════════════════════════════════════

class _TreatmentsTab extends StatelessWidget {
  const _TreatmentsTab({
    required this.data,
    required this.isDark,
    required this.theme,
  });

  final ReportData data;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final top10 = data.tratamientosFrecuentes.entries.take(10).toList();

    return ListView(
      padding: AppSpacing.cardPaddingLarge,
      children: [
        _SummaryRow(children: [
          _StatCard(
            label: 'Registros clínicos',
            value: '${data.totalRegistrosClinicos}',
            icon: Icons.description_rounded,
            color: const Color(0xFF1E88E5),
            isDark: isDark,
          ),
          _StatCard(
            label: 'Total pacientes',
            value: '${data.totalPacientes}',
            icon: Icons.groups_rounded,
            color: const Color(0xFF00897B),
            isDark: isDark,
          ),
        ]),
        const SizedBox(height: AppSpacing.xl),

        if (top10.isNotEmpty) ...[
          Text('Tratamientos más frecuentes',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          _ChartCard(
            isDark: isDark,
            height: top10.length * 38.0 + 40,
            child: _TreatmentsBarChart(
              entries: top10,
              isDark: isDark,
            ),
          ),
        ],

        if (top10.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Text('Sin registros clínicos en este período',
                  style:
                      TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 4 — Productividad
// ══════════════════════════════════════════════════════════════════

class _ProductivityTab extends StatelessWidget {
  const _ProductivityTab({
    required this.data,
    required this.isDark,
    required this.theme,
    required this.fmt,
  });

  final ReportData data;
  final bool isDark;
  final ThemeData theme;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final entries = data.productividadPorOdontologo.entries.toList();

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Text('Sin datos de productividad en este período',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        ),
      );
    }

    return ListView(
      padding: AppSpacing.cardPaddingLarge,
      children: [
        Text('Productividad por odontólogo',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.md),

        ...entries.map((e) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: AppSpacing.cardPaddingLarge,
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: AppSpacing.borderRadiusLg,
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        e.key[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        e.key,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _MiniStat(
                      icon: Icons.event_available_rounded,
                      label: 'Consultas',
                      value: '${e.value.citas}',
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    _MiniStat(
                      icon: Icons.attach_money_rounded,
                      label: 'Generado',
                      value: 'Q ${fmt.format(e.value.ingresos)}',
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Chart widgets
// ══════════════════════════════════════════════════════════════════

class _IncomeDailyChart extends StatelessWidget {
  const _IncomeDailyChart({required this.data, required this.isDark});
  final Map<String, double> data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final sortedKeys = data.keys.toList()..sort();
    // Show last 14 days max
    final keys =
        sortedKeys.length > 14 ? sortedKeys.sublist(sortedKeys.length - 14) : sortedKeys;
    final maxY = keys.fold<double>(
        0.0, (m, k) => (data[k] ?? 0) > m ? data[k]! : m);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final day = keys[group.x.toInt()];
              return BarTooltipItem(
                '$day\nQ ${rod.toY.toStringAsFixed(0)}',
                TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= keys.length) return const SizedBox();
                final day = keys[idx].substring(8); // dd
                return Text(day,
                    style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white54 : Colors.black45));
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: keys.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: data[e.value] ?? 0,
                width: keys.length > 10 ? 8 : 14,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4)),
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xFF0D7377), Color(0xFF14B8A6)],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _PaymentMethodPie extends StatelessWidget {
  const _PaymentMethodPie({
    required this.data,
    required this.total,
    required this.fmt,
  });
  final Map<String, double> data;
  final double total;
  final NumberFormat fmt;

  static const _colors = {
    'efectivo': Color(0xFF43A047),
    'tarjeta': Color(0xFF1E88E5),
    'transferencia': Color(0xFFFF9800),
  };

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: entries.map((e) {
                final pct =
                    total > 0 ? (e.value / total * 100).toStringAsFixed(0) : '0';
                return PieChartSectionData(
                  value: e.value,
                  color: _colors[e.key] ?? Colors.grey,
                  title: '$pct%',
                  titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                  radius: 40,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _colors[e.key] ?? Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${Payment.metodoPagoLabel(e.key)}: Q ${fmt.format(e.value)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _AppointmentStatusPie extends StatelessWidget {
  const _AppointmentStatusPie({required this.data});
  final Map<String, int> data;

  static const _colors = {
    'programada': Color(0xFF42A5F5),
    'confirmada': Color(0xFF66BB6A),
    'en_sala': Color(0xFFFFA726),
    'en_atencion': Color(0xFF7C4DFF),
    'completada': Color(0xFF43A047),
    'cancelada': Color(0xFFE53935),
    'no_asistio': Color(0xFF78909C),
  };

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final total = entries.fold<int>(0, (s, e) => s + e.value);

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: entries.map((e) {
                final pct =
                    total > 0 ? (e.value / total * 100).toStringAsFixed(0) : '0';
                return PieChartSectionData(
                  value: e.value.toDouble(),
                  color: _colors[e.key] ?? Colors.grey,
                  title: '$pct%',
                  titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                  radius: 38,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: _colors[e.key] ?? Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        '${AppointmentStatus.label(e.key)} (${e.value})',
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _AppointmentDailyChart extends StatelessWidget {
  const _AppointmentDailyChart({required this.data, required this.isDark});
  final Map<String, int> data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final sortedKeys = data.keys.toList()..sort();
    final keys =
        sortedKeys.length > 14 ? sortedKeys.sublist(sortedKeys.length - 14) : sortedKeys;
    final maxY =
        keys.fold<double>(0, (m, k) => (data[k] ?? 0) > m ? data[k]!.toDouble() : m);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.3 + 1,
        titlesData: FlTitlesData(
          show: true,
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= keys.length) return const SizedBox();
                final day = keys[idx].substring(8);
                return Text(day,
                    style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white54 : Colors.black45));
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final day = keys[group.x.toInt()];
              return BarTooltipItem(
                '$day\n${rod.toY.toInt()} citas',
                const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
        barGroups: keys.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: (data[e.value] ?? 0).toDouble(),
                width: keys.length > 10 ? 8 : 14,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _TreatmentsBarChart extends StatelessWidget {
  const _TreatmentsBarChart({required this.entries, required this.isDark});
  final List<MapEntry<String, int>> entries;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final maxVal =
        entries.fold<double>(0, (m, e) => e.value > m ? e.value.toDouble() : m);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.2 + 1,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final name = entries[group.x.toInt()].key;
              return BarTooltipItem(
                '$name\n${rod.toY.toInt()} veces',
                const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 110,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= entries.length) return const SizedBox();
                final name = entries[idx].key;
                final truncated =
                    name.length > 16 ? '${name.substring(0, 14)}…' : name;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    truncated,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: entries.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value.toDouble(),
                width: 14,
                borderRadius:
                    const BorderRadius.horizontal(right: Radius.circular(4)),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7043), Color(0xFFFFAB91)],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Shared helper widgets
// ══════════════════════════════════════════════════════════════════

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.isDark,
    required this.height,
    required this.child,
  });
  final bool isDark;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppTheme.cardShadow,
      ),
      child: child,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: children
          .map<Widget>((c) => Expanded(child: c))
          .toList()
        ..insert(1, const SizedBox(width: AppSpacing.sm)),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}
