import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_mode_button.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../clinical_records/domain/entities/clinical_record.dart';
import '../../../clinical_records/domain/usecases/observe_all_clinical_records.dart';
import '../../../patients/domain/entities/patient.dart';
import '../../../patients/presentation/controllers/patient_controller.dart';
import '../../domain/entities/payment.dart';
import '../controllers/billing_controller.dart';

// ═══════════════════════════════════════════════════════════════════
//  BILLING PAGE  (Pagos + Cuentas tabs)
// ═══════════════════════════════════════════════════════════════════

class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  late final BillingController _billingCtrl;
  late final PatientController _patientCtrl;

  // Clinical records stream for accounts tab
  StreamSubscription<List<ClinicalRecord>>? _recordsSub;
  List<ClinicalRecord> _allRecords = [];

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filterMethod = 'todos';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _billingCtrl = getIt<BillingController>();
    _patientCtrl = getIt<PatientController>();
    _billingCtrl.startObservingAll();
    _billingCtrl.addListener(_onChanged);
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });

    // Start observing clinical records for accounts tab
    final observeAllRecords = getIt<ObserveAllClinicalRecords>();
    _recordsSub = observeAllRecords().listen((records) {
      _allRecords = records;
      if (mounted) setState(() {});
    });
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _billingCtrl.removeListener(_onChanged);
    _searchCtrl.dispose();
    _recordsSub?.cancel();
    super.dispose();
  }

  // ── Filtered payments ────────────────────────────────────────
  List<Payment> get _filteredPayments {
    var list = _billingCtrl.payments;
    if (_filterMethod != 'todos') {
      list = list.where((p) => p.metodoPago == _filterMethod).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((p) =>
              p.pacienteNombre.toLowerCase().contains(_searchQuery) ||
              (p.notas ?? '').toLowerCase().contains(_searchQuery))
          .toList();
    }
    return list;
  }

  // ── Summary helpers ──────────────────────────────────────────
  double get _todayTotal {
    final now = DateTime.now();
    return _billingCtrl.payments
        .where((p) =>
            p.fecha.year == now.year &&
            p.fecha.month == now.month &&
            p.fecha.day == now.day)
        .fold(0.0, (s, p) => s + p.monto);
  }

  double get _monthTotal {
    final now = DateTime.now();
    return _billingCtrl.payments
        .where((p) => p.fecha.year == now.year && p.fecha.month == now.month)
        .fold(0.0, (s, p) => s + p.monto);
  }

  int get _todayCount {
    final now = DateTime.now();
    return _billingCtrl.payments
        .where((p) =>
            p.fecha.year == now.year &&
            p.fecha.month == now.month &&
            p.fecha.day == now.day)
        .length;
  }

  // ── Patient account data ─────────────────────────────────────
  List<_PatientAccount> get _patientAccounts {
    final map = <String, _PatientAccount>{};

    for (final r in _allRecords) {
      final acc = map.putIfAbsent(
        r.pacienteId,
        () => _PatientAccount(
          pacienteId: r.pacienteId,
          pacienteNombre: r.pacienteNombre,
        ),
      );
      acc.totalCargado += r.costoTotal;
    }

    for (final p in _billingCtrl.payments) {
      final acc = map.putIfAbsent(
        p.pacienteId,
        () => _PatientAccount(
          pacienteId: p.pacienteId,
          pacienteNombre: p.pacienteNombre,
        ),
      );
      acc.totalPagado += p.monto;
    }

    var accounts = map.values.toList()
      ..sort((a, b) => b.saldoPendiente.compareTo(a.saldoPendiente));

    if (_searchQuery.isNotEmpty) {
      accounts = accounts
          .where(
              (a) => a.pacienteNombre.toLowerCase().contains(_searchQuery))
          .toList();
    }

    return accounts;
  }

  // ── Register new payment ────────────────────────────────────
  Future<void> _registerPayment({String? preselectedPatientId}) async {
    final result = await showModalBottomSheet<_PaymentFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) => _PaymentFormSheet(
        patients: _patientCtrl.patients,
        preselectedPatientId: preselectedPatientId,
      ),
    );

    if (result == null || !mounted) return;

    final ok = await _billingCtrl.addPayment(
      pacienteId: result.pacienteId,
      pacienteNombre: result.pacienteNombre,
      monto: result.monto,
      metodoPago: result.metodoPago,
      notas: result.notas,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            ok ? 'Pago registrado correctamente.' : 'Error al registrar pago.'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  // ── Delete payment ──────────────────────────────────────────
  Future<void> _deletePayment(Payment payment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar pago'),
        content: Text(
          '¿Eliminar pago de Q ${payment.monto.toStringAsFixed(2)} '
          'de ${payment.pacienteNombre}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final ok = await _billingCtrl.removePayment(payment.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Pago eliminado.' : 'Error al eliminar.'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  // ── Show patient account detail ─────────────────────────────
  void _showAccountDetail(_PatientAccount account) {
    final records = _allRecords
        .where((r) => r.pacienteId == account.pacienteId)
        .toList();
    final payments = _billingCtrl.payments
        .where((p) => p.pacienteId == account.pacienteId)
        .toList();

    final fmt = NumberFormat('#,##0.00', 'en');
    final dateFmt = DateFormat('dd/MM/yyyy', 'es');
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
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          expand: false,
          builder: (ctx, scrollCtrl) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: ListView(
              controller: scrollCtrl,
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

                // Patient name header
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        account.pacienteNombre.isNotEmpty
                            ? account.pacienteNombre[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        account.pacienteNombre,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Balance summary row
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'Cargado',
                        value: 'Q ${fmt.format(account.totalCargado)}',
                        color: AppColors.info,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _MiniStat(
                        label: 'Pagado',
                        value: 'Q ${fmt.format(account.totalPagado)}',
                        color: AppColors.success,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _MiniStat(
                        label: 'Pendiente',
                        value: 'Q ${fmt.format(account.saldoPendiente)}',
                        color: account.saldoPendiente > 0
                            ? AppColors.error
                            : AppColors.success,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Treatments list
                if (records.isNotEmpty) ...[
                  Text('Tratamientos realizados',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  ...records.map((r) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.cardDark
                                : AppColors.cardLight,
                            borderRadius: AppSpacing.borderRadiusMd,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.medical_services_outlined,
                                  size: 18,
                                  color: AppColors.info
                                      .withValues(alpha: 0.7)),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.tratamientos
                                          .map((t) => t.nombre)
                                          .join(', '),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      dateFmt.format(r.fecha),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Q ${fmt.format(r.costoTotal)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.info,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Payments list
                if (payments.isNotEmpty) ...[
                  Text('Pagos realizados',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  ...payments.map((p) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.cardDark
                                : AppColors.cardLight,
                            borderRadius: AppSpacing.borderRadiusMd,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.payments_rounded,
                                  size: 18,
                                  color: AppColors.success
                                      .withValues(alpha: 0.7)),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      Payment.metodoPagoLabel(
                                          p.metodoPago),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      dateFmt.format(p.fecha),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Q ${fmt.format(p.monto)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],

                // Quick pay button
                const SizedBox(height: AppSpacing.lg),
                if (account.saldoPendiente > 0)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _registerPayment(
                            preselectedPatientId: account.pacienteId);
                      },
                      icon: const Icon(Icons.payments_rounded, size: 18),
                      label: const Text('Registrar abono'),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
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
    final fmt = NumberFormat('#,##0.00', 'en');

    return Scaffold(
      body: Column(
        children: [
          // ── Header ──────────────────────────────────
          GradientHeader(
            height: 175,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Facturación',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_billingCtrl.payments.length} pagos registrados',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const ThemeModeButton(),
                  ],
                ),
                const Spacer(),
                // Search bar
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar por paciente…',
                    hintStyle:
                        TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.15),
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusLg,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ],
            ),
          ),

          // ── Tab bar ─────────────────────────────────
          Container(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            child: TabBar(
              controller: _tabCtrl,
              labelColor: AppColors.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(icon: Icon(Icons.payments_rounded), text: 'Pagos'),
                Tab(
                    icon: Icon(Icons.account_balance_wallet_rounded),
                    text: 'Cuentas'),
              ],
            ),
          ),

          // ── Tab content ─────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildPaymentsTab(theme, isDark, fmt),
                _buildAccountsTab(theme, isDark, fmt),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'newPayment',
        onPressed: () => _registerPayment(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Registrar pago'),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  PAYMENTS TAB
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPaymentsTab(ThemeData theme, bool isDark, NumberFormat fmt) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'es');
    final payments = _filteredPayments;

    return CustomScrollView(
      slivers: [
        // Summary cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.today_rounded,
                    label: 'Hoy',
                    amount: 'Q ${fmt.format(_todayTotal)}',
                    subtitle: '$_todayCount pagos',
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.calendar_month_rounded,
                    label: 'Este mes',
                    amount: 'Q ${fmt.format(_monthTotal)}',
                    subtitle:
                        DateFormat('MMMM yyyy', 'es').format(DateTime.now()),
                    color: AppColors.success,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Filter chips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Todos',
                    selected: _filterMethod == 'todos',
                    onTap: () => setState(() => _filterMethod = 'todos'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'Efectivo',
                    selected: _filterMethod == 'efectivo',
                    onTap: () => setState(() => _filterMethod = 'efectivo'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'Tarjeta',
                    selected: _filterMethod == 'tarjeta',
                    onTap: () => setState(() => _filterMethod = 'tarjeta'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'Transferencia',
                    selected: _filterMethod == 'transferencia',
                    onTap: () =>
                        setState(() => _filterMethod = 'transferencia'),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

        // States
        if (_billingCtrl.loading)
          const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()))
        else if (_billingCtrl.error != null)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Text(_billingCtrl.error!,
                        textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
          )
        else if (payments.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_rounded,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.3)),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _searchQuery.isEmpty && _filterMethod == 'todos'
                        ? 'Sin pagos registrados'
                        : 'Sin resultados',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Registra el primer pago con el botón +',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final p = payments[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _PaymentCard(
                      payment: p,
                      isDark: isDark,
                      dateFmt: dateFmt,
                      fmt: fmt,
                      onDelete: () => _deletePayment(p),
                    ),
                  );
                },
                childCount: payments.length,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ACCOUNTS TAB
  // ═══════════════════════════════════════════════════════════════
  Widget _buildAccountsTab(ThemeData theme, bool isDark, NumberFormat fmt) {
    final accounts = _patientAccounts;

    final totalDeuda = accounts.fold(
        0.0, (s, a) => s + (a.saldoPendiente > 0 ? a.saldoPendiente : 0));
    final conDeuda = accounts.where((a) => a.saldoPendiente > 0).length;

    return CustomScrollView(
      slivers: [
        // Top summary
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.warning_amber_rounded,
                    label: 'Deuda total',
                    amount: 'Q ${fmt.format(totalDeuda)}',
                    subtitle: '$conDeuda pacientes',
                    color: totalDeuda > 0 ? AppColors.error : AppColors.success,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.people_rounded,
                    label: 'Cuentas',
                    amount: '${accounts.length}',
                    subtitle: 'pacientes activos',
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Legend
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
            child: Text(
              'Ordenado por saldo pendiente',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ),

        if (accounts.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.3)),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _searchQuery.isEmpty
                        ? 'Sin cuentas por mostrar'
                        : 'Sin resultados',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Las cuentas aparecen cuando se crean registros clínicos.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final acc = accounts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _AccountCard(
                      account: acc,
                      isDark: isDark,
                      fmt: fmt,
                      onTap: () => _showAccountDetail(acc),
                      onPay: acc.saldoPendiente > 0
                          ? () => _registerPayment(
                              preselectedPatientId: acc.pacienteId)
                          : null,
                    ),
                  );
                },
                childCount: accounts.length,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DATA MODEL
// ═══════════════════════════════════════════════════════════════════

class _PatientAccount {
  _PatientAccount({
    required this.pacienteId,
    required this.pacienteNombre,
  });

  final String pacienteId;
  final String pacienteNombre;
  double totalCargado = 0;
  double totalPagado = 0;

  double get saldoPendiente => totalCargado - totalPagado;
  bool get alDia => saldoPendiente <= 0;
}

// ═══════════════════════════════════════════════════════════════════
//  SUMMARY CARD
// ═══════════════════════════════════════════════════════════════════

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.amount,
    required this.subtitle,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String amount;
  final String subtitle;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            amount,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MINI STAT (used in detail sheet)
// ═══════════════════════════════════════════════════════════════════

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  FILTER CHIP
// ═══════════════════════════════════════════════════════════════════

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: AppSpacing.borderRadiusXl,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PAYMENT CARD
// ═══════════════════════════════════════════════════════════════════

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.payment,
    required this.isDark,
    required this.dateFmt,
    required this.fmt,
    required this.onDelete,
  });

  final Payment payment;
  final bool isDark;
  final DateFormat dateFmt;
  final NumberFormat fmt;
  final VoidCallback onDelete;

  IconData _methodIcon() {
    switch (payment.metodoPago) {
      case 'tarjeta':
        return Icons.credit_card_rounded;
      case 'transferencia':
        return Icons.account_balance_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  Color _methodColor() {
    switch (payment.metodoPago) {
      case 'tarjeta':
        return AppColors.info;
      case 'transferencia':
        return const Color(0xFF7C4DFF);
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final methodColor = _methodColor();

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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: methodColor.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                child: Icon(_methodIcon(), color: methodColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.pacienteNombre,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(dateFmt.format(payment.fecha),
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Text(
                'Q ${fmt.format(payment.monto)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: methodColor.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Text(
                  Payment.metodoPagoLabel(payment.metodoPago),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: methodColor,
                  ),
                ),
              ),
              if (payment.notas != null && payment.notas!.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(payment.notas!,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ] else
                const Spacer(),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline_rounded,
                      color: AppColors.error.withValues(alpha: 0.6)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ACCOUNT CARD  (Cuentas tab)
// ═══════════════════════════════════════════════════════════════════

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.isDark,
    required this.fmt,
    required this.onTap,
    this.onPay,
  });

  final _PatientAccount account;
  final bool isDark;
  final NumberFormat fmt;
  final VoidCallback onTap;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDebt = account.saldoPendiente > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow: AppTheme.cardShadow,
          border: hasDebt
              ? Border.all(color: AppColors.error.withValues(alpha: 0.2))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      (hasDebt ? AppColors.error : AppColors.success)
                          .withValues(alpha: 0.12),
                  child: Text(
                    account.pacienteNombre.isNotEmpty
                        ? account.pacienteNombre[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: hasDebt ? AppColors.error : AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.pacienteNombre,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cargado: Q ${fmt.format(account.totalCargado)} · '
                        'Pagado: Q ${fmt.format(account.totalPagado)}',
                        style:
                            theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: (hasDebt ? AppColors.error : AppColors.success)
                        .withValues(alpha: 0.1),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Text(
                    hasDebt
                        ? 'Pendiente: Q ${fmt.format(account.saldoPendiente)}'
                        : 'Al día ✓',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: hasDebt ? AppColors.error : AppColors.success,
                    ),
                  ),
                ),
                const Spacer(),
                if (onPay != null)
                  SizedBox(
                    height: 30,
                    child: TextButton.icon(
                      onPressed: onPay,
                      icon: const Icon(Icons.payments_rounded, size: 14),
                      label:
                          const Text('Abonar', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PAYMENT FORM SHEET
// ═══════════════════════════════════════════════════════════════════

class _PaymentFormResult {
  const _PaymentFormResult({
    required this.pacienteId,
    required this.pacienteNombre,
    required this.monto,
    required this.metodoPago,
    this.notas,
  });

  final String pacienteId;
  final String pacienteNombre;
  final double monto;
  final String metodoPago;
  final String? notas;
}

class _PaymentFormSheet extends StatefulWidget {
  const _PaymentFormSheet({
    required this.patients,
    this.preselectedPatientId,
  });

  final List<Patient> patients;
  final String? preselectedPatientId;

  @override
  State<_PaymentFormSheet> createState() => _PaymentFormSheetState();
}

class _PaymentFormSheetState extends State<_PaymentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  late final TextEditingController _patientSearchCtrl;

  Patient? _selectedPatient;
  String _metodoPago = 'efectivo';

  static const _metodos = {
    'efectivo': 'Efectivo',
    'tarjeta': 'Tarjeta',
    'transferencia': 'Transferencia',
  };

  @override
  void initState() {
    super.initState();
    _patientSearchCtrl = TextEditingController();
    if (widget.preselectedPatientId != null) {
      final match = widget.patients
          .where((p) => p.id == widget.preselectedPatientId)
          .toList();
      if (match.isNotEmpty) {
        _selectedPatient = match.first;
        _patientSearchCtrl.text = match.first.nombre;
      }
    }
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _notasCtrl.dispose();
    _patientSearchCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatient == null) return;

    final monto = double.tryParse(_montoCtrl.text.replaceAll(',', '.'));
    if (monto == null || monto <= 0) return;

    Navigator.of(context).pop(
      _PaymentFormResult(
        pacienteId: _selectedPatient!.id,
        pacienteNombre: _selectedPatient!.nombre,
        monto: monto,
        metodoPago: _metodoPago,
        notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
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
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.3),
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                  ),
                ),
                // Title
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.payments_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Registrar pago',
                              style: theme.textTheme.titleLarge),
                          Text('Ingresá los datos del cobro',
                              style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const Divider(),
                const SizedBox(height: AppSpacing.lg),

                // Patient picker
                Text('Paciente', style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Autocomplete<Patient>(
                  initialValue: _patientSearchCtrl.value,
                  displayStringForOption: (p) => p.nombre,
                  optionsBuilder: (textEditingValue) {
                    final q = textEditingValue.text.trim().toLowerCase();
                    if (q.isEmpty) return widget.patients;
                    return widget.patients
                        .where((p) => p.nombre.toLowerCase().contains(q));
                  },
                  onSelected: (p) => setState(() => _selectedPatient = p),
                  fieldViewBuilder:
                      (ctx, controller, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Buscar paciente…',
                        prefixIcon: Icon(Icons.person_search_rounded),
                      ),
                      validator: (_) {
                        if (_selectedPatient == null) {
                          return 'Selecciona un paciente.';
                        }
                        return null;
                      },
                    );
                  },
                  optionsViewBuilder: (ctx, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: AppSpacing.borderRadiusMd,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (_, i) {
                              final p = options.elementAt(i);
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.15),
                                  child: Text(
                                    p.nombre.isNotEmpty
                                        ? p.nombre[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(p.nombre),
                                dense: true,
                                onTap: () => onSelected(p),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Amount
                TextFormField(
                  controller: _montoCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Monto (Q)',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                  ),
                  validator: (v) {
                    final val =
                        double.tryParse((v ?? '').replaceAll(',', '.'));
                    if (val == null || val <= 0) {
                      return 'Ingresa un monto válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Payment method
                Text('Método de pago', style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<String>(
                  segments: _metodos.entries
                      .map((e) => ButtonSegment(
                            value: e.key,
                            label: Text(e.value),
                            icon: Icon(_methodIcon(e.key), size: 16),
                          ))
                      .toList(),
                  selected: {_metodoPago},
                  onSelectionChanged: (s) =>
                      setState(() => _metodoPago = s.first),
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStatePropertyAll(
                      theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Notes
                TextFormField(
                  controller: _notasCtrl,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Actions
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
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Cobrar'),
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

  IconData _methodIcon(String key) {
    switch (key) {
      case 'tarjeta':
        return Icons.credit_card_rounded;
      case 'transferencia':
        return Icons.account_balance_rounded;
      default:
        return Icons.payments_rounded;
    }
  }
}
