import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_mode_button.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/inventory_item.dart';
import '../controllers/inventory_controller.dart';

class InventoryManagementPage extends StatefulWidget {
  const InventoryManagementPage({super.key});

  @override
  State<InventoryManagementPage> createState() =>
      _InventoryManagementPageState();
}

class _InventoryManagementPageState extends State<InventoryManagementPage> {
  late final InventoryController _controller;
  final _searchCtrl = TextEditingController();
  String? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _controller = getIt<InventoryController>();
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

  List<InventoryItem> get _filteredItems {
    var list = _controller.items;
    if (_selectedCategory != null) {
      list = list.where((i) => i.categoria == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((i) => i.nombre.toLowerCase().contains(_searchQuery))
          .toList();
    }
    return list;
  }

  // ── Create ─────────────────────────────────────────────────────
  Future<void> _create() async {
    final result = await showModalBottomSheet<_InventoryFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _InventoryFormSheet(),
    );

    if (result == null || !mounted) return;

    final success = await _controller.create(
      nombre: result.nombre,
      categoria: result.categoria,
      unidad: result.unidad,
      stockActual: result.stockActual,
      stockMinimo: result.stockMinimo,
      costoUnitario: result.costoUnitario,
      descripcion: result.descripcion,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Producto "${result.nombre}" registrado.'
              : _controller.errorMessage ?? 'Error al registrar.',
        ),
      ),
    );
  }

  // ── Edit ───────────────────────────────────────────────────────
  Future<void> _edit(InventoryItem item) async {
    final result = await showModalBottomSheet<_InventoryFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _InventoryFormSheet(existing: item),
    );

    if (result == null || !mounted) return;

    final success = await _controller.update(
      id: item.id,
      nombre: result.nombre,
      categoria: result.categoria,
      unidad: result.unidad,
      stockActual: result.stockActual,
      stockMinimo: result.stockMinimo,
      costoUnitario: result.costoUnitario,
      activo: result.activo,
      descripcion: result.descripcion,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Producto "${result.nombre}" actualizado.'
              : _controller.errorMessage ?? 'Error al actualizar.',
        ),
      ),
    );
  }

  // ── Adjust stock ───────────────────────────────────────────────
  Future<void> _adjustStock(InventoryItem item) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _StockAdjustSheet(item: item),
    );

    if (result == null || result == 0 || !mounted) return;

    final success = await _controller.adjust(id: item.id, delta: result);

    if (!mounted) return;
    final label = result > 0 ? 'Entrada +$result' : 'Salida $result';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '$label aplicado a "${item.nombre}".'
              : _controller.errorMessage ?? 'Error al ajustar stock.',
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
        final filtered = _filteredItems;

        return Scaffold(
          // ── FAB ────────────────────────────────────
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
              _controller.isSaving ? 'Guardando...' : 'Nuevo producto',
            ),
          ),

          body: CustomScrollView(
            slivers: [
              // ── Gradient header ────────────────────
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
                              Icons.inventory_2_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Inventario',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${_controller.items.length} producto(s)'
                                  '${_controller.lowStockCount > 0 ? '  ·  ${_controller.lowStockCount} con bajo stock' : ''}',
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

              // ── Category chips ─────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md,
                  ),
                  child: Transform.translate(
                    offset: const Offset(0, -12),
                    child: _CategoryChips(
                      selected: _selectedCategory,
                      categories: _distinctCategories(),
                      onSelected: (cat) {
                        setState(() {
                          _selectedCategory =
                              _selectedCategory == cat ? null : cat;
                        });
                      },
                    ),
                  ),
                ),
              ),

              // ── Search bar ─────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar producto...',
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
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.md),
              ),

              // ── Content ────────────────────────────
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
                          Icons.inventory_2_outlined,
                          size: 56,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Sin resultados para "${_searchCtrl.text.trim()}".'
                              : _selectedCategory != null
                                  ? 'Sin productos en esta categoría.'
                                  : 'Sin productos registrados.',
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
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.md,
                          ),
                          child: _InventoryCard(
                            item: filtered[index],
                            isDark: isDark,
                            isUpdating:
                                _controller.updatingId == filtered[index].id,
                            onTap: () => _edit(filtered[index]),
                            onAdjust: () => _adjustStock(filtered[index]),
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

  /// Returns the distinct categories present in the current items.
  List<String> _distinctCategories() {
    final cats = <String>{};
    for (final item in _controller.items) {
      if (item.categoria.isNotEmpty) cats.add(item.categoria);
    }
    return cats.toList()..sort();
  }
}

// ══════════════════════════════════════════════════════════════════
// CATEGORY CHIPS
// ══════════════════════════════════════════════════════════════════

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.selected,
    required this.categories,
    required this.onSelected,
  });

  final String? selected;
  final List<String> categories;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final cat in categories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(cat),
                selected: selected == cat,
                onSelected: (_) => onSelected(cat),
                showCheckmark: false,
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// INVENTORY CARD
// ══════════════════════════════════════════════════════════════════

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.item,
    required this.isDark,
    required this.isUpdating,
    required this.onTap,
    required this.onAdjust,
  });

  final InventoryItem item;
  final bool isDark;
  final bool isUpdating;
  final VoidCallback onTap;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Stock color logic
    Color stockColor;
    IconData stockIcon;
    if (item.agotado) {
      stockColor = AppColors.error;
      stockIcon = Icons.error_rounded;
    } else if (item.stockBajo) {
      stockColor = AppColors.warning;
      stockIcon = Icons.warning_amber_rounded;
    } else {
      stockColor = AppColors.success;
      stockIcon = Icons.check_circle_rounded;
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: item.activo ? 1.0 : 0.55,
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
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Top row: name + badges ──────────
                        Row(
                          children: [
                            // Stock indicator dot
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: stockColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.nombre,
                                style:
                                    theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!item.activo)
                              const StatusBadge(
                                label: 'Inactivo',
                                active: false,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // ── Category badge ────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.categoria,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // ── Stock row ─────────────────────
                        Row(
                          children: [
                            Icon(stockIcon, size: 18, color: stockColor),
                            const SizedBox(width: 6),
                            Text(
                              '${item.stockActual}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: stockColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              ' ${item.unidad}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '(mín. ${item.stockMinimo})',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            const Spacer(),
                            // Quick adjust button
                            SizedBox(
                              height: 32,
                              child: OutlinedButton.icon(
                                onPressed: onAdjust,
                                icon: const Icon(
                                  Icons.swap_vert_rounded,
                                  size: 16,
                                ),
                                label: const Text('Ajustar'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  textStyle: const TextStyle(fontSize: 12),
                                  side: BorderSide(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // ── Cost ──────────────────────────
                        if (item.costoUnitario > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Q ${item.costoUnitario.toStringAsFixed(2)} / ${item.unidad}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],

                        // ── Description ───────────────────
                        if (item.descripcion != null &&
                            item.descripcion!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            item.descripcion!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
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
// INVENTORY FORM SHEET (create / edit)
// ══════════════════════════════════════════════════════════════════

class _InventoryFormResult {
  const _InventoryFormResult({
    required this.nombre,
    required this.categoria,
    required this.unidad,
    required this.stockActual,
    required this.stockMinimo,
    required this.costoUnitario,
    required this.activo,
    this.descripcion,
  });

  final String nombre;
  final String categoria;
  final String unidad;
  final int stockActual;
  final int stockMinimo;
  final double costoUnitario;
  final bool activo;
  final String? descripcion;
}

class _InventoryFormSheet extends StatefulWidget {
  const _InventoryFormSheet({this.existing});
  final InventoryItem? existing;

  @override
  State<_InventoryFormSheet> createState() => _InventoryFormSheetState();
}

class _InventoryFormSheetState extends State<_InventoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _unidadCtrl;
  late final TextEditingController _stockActualCtrl;
  late final TextEditingController _stockMinimoCtrl;
  late final TextEditingController _costoCtrl;
  late final TextEditingController _descripcionCtrl;
  late String _categoria;
  late bool _activo;

  static const _defaultCategories = [
    'Materiales Dentales',
    'Desechables',
    'Instrumental',
    'Medicamentos',
    'Insumos Generales',
  ];

  static const _defaultUnits = [
    'unidades',
    'cajas',
    'pares',
    'rollos',
    'frascos',
    'tubos',
    'sobres',
    'ml',
    'g',
  ];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nombreCtrl = TextEditingController(text: e?.nombre ?? '');
    _unidadCtrl = TextEditingController(text: e?.unidad ?? 'unidades');
    _stockActualCtrl =
        TextEditingController(text: e != null ? '${e.stockActual}' : '');
    _stockMinimoCtrl =
        TextEditingController(text: e != null ? '${e.stockMinimo}' : '');
    _costoCtrl = TextEditingController(
      text: e != null ? e.costoUnitario.toStringAsFixed(2) : '',
    );
    _descripcionCtrl =
        TextEditingController(text: e?.descripcion ?? '');
    _categoria = e?.categoria ?? _defaultCategories.first;
    _activo = e?.activo ?? true;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _unidadCtrl.dispose();
    _stockActualCtrl.dispose();
    _stockMinimoCtrl.dispose();
    _costoCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      _InventoryFormResult(
        nombre: _nombreCtrl.text.trim(),
        categoria: _categoria,
        unidad: _unidadCtrl.text.trim(),
        stockActual: int.tryParse(_stockActualCtrl.text.trim()) ?? 0,
        stockMinimo: int.tryParse(_stockMinimoCtrl.text.trim()) ?? 0,
        costoUnitario: double.tryParse(_costoCtrl.text.trim()) ?? 0,
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xxxl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Handle ─────────────────────────
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin:
                        const EdgeInsets.only(bottom: AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Text(
                  _isEditing ? 'Editar producto' : 'Nuevo producto',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Nombre ─────────────────────────
                TextFormField(
                  controller: _nombreCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del producto',
                    prefixIcon: Icon(Icons.inventory_2_rounded),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa el nombre.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Categoría ──────────────────────
                DropdownButtonFormField<String>(
                  initialValue: _categoria,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    prefixIcon: Icon(Icons.category_rounded),
                  ),
                  items: _defaultCategories
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _categoria = v);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Unidad ─────────────────────────
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: _unidadCtrl.text),
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return _defaultUnits;
                    }
                    return _defaultUnits.where((u) => u
                        .toLowerCase()
                        .contains(
                            textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (value) => _unidadCtrl.text = value,
                  fieldViewBuilder: (context, controller, focusNode,
                      onEditingComplete) {
                    // Sync with our controller
                    controller.addListener(
                        () => _unidadCtrl.text = controller.text);
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Unidad de medida',
                        prefixIcon: Icon(Icons.straighten_rounded),
                        hintText: 'ej. unidades, cajas, pares',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Ingresa la unidad.'
                              : null,
                      onEditingComplete: onEditingComplete,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Stock actual & mínimo ──────────
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockActualCtrl,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Stock actual',
                          prefixIcon:
                              Icon(Icons.add_box_rounded),
                        ),
                        validator: (v) {
                          final text = v?.trim() ?? '';
                          if (text.isEmpty) {
                            return 'Requerido.';
                          }
                          if (int.tryParse(text) == null) {
                            return 'Inválido.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _stockMinimoCtrl,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Stock mínimo',
                          prefixIcon:
                              Icon(Icons.safety_check_rounded),
                        ),
                        validator: (v) {
                          final text = v?.trim() ?? '';
                          if (text.isEmpty) {
                            return 'Requerido.';
                          }
                          if (int.tryParse(text) == null) {
                            return 'Inválido.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Costo unitario ─────────────────
                TextFormField(
                  controller: _costoCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Costo unitario (Q)',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                    prefixText: 'Q ',
                    hintText: '0.00',
                  ),
                  validator: (v) {
                    final text = v?.trim() ?? '';
                    if (text.isEmpty) return 'Ingresa el costo.';
                    final parsed = double.tryParse(text);
                    if (parsed == null || parsed < 0) {
                      return 'Costo inválido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Descripción ────────────────────
                TextFormField(
                  controller: _descripcionCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    prefixIcon: Icon(Icons.notes_rounded),
                    hintText: 'Detalles adicionales del producto',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Active toggle (only edit) ──────
                if (_isEditing) ...[
                  SwitchListTile(
                    value: _activo,
                    onChanged: (v) => setState(() => _activo = v),
                    title: const Text('Producto activo'),
                    subtitle: Text(
                      _activo ? 'Visible en inventario' : 'Oculto',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // ── Submit ─────────────────────────
                FilledButton.icon(
                  onPressed: _submit,
                  icon: Icon(
                    _isEditing ? Icons.save_rounded : Icons.add_rounded,
                  ),
                  label: Text(
                    _isEditing ? 'Guardar cambios' : 'Registrar producto',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// STOCK ADJUST SHEET
// ══════════════════════════════════════════════════════════════════

class _StockAdjustSheet extends StatefulWidget {
  const _StockAdjustSheet({required this.item});
  final InventoryItem item;

  @override
  State<_StockAdjustSheet> createState() => _StockAdjustSheetState();
}

class _StockAdjustSheetState extends State<_StockAdjustSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadCtrl = TextEditingController();
  bool _isEntrada = true; // true = add, false = remove

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final qty = int.tryParse(_cantidadCtrl.text.trim()) ?? 0;
    if (qty <= 0) return;
    Navigator.of(context).pop(_isEntrada ? qty : -qty);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xxxl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Text(
                  'Ajustar stock',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item.nombre,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stock actual: ${widget.item.stockActual} ${widget.item.unidad}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Tipo: entrada / salida ──────────
                Row(
                  children: [
                    Expanded(
                      child: _TypeChip(
                        icon: Icons.arrow_downward_rounded,
                        label: 'Entrada',
                        color: AppColors.success,
                        selected: _isEntrada,
                        onTap: () =>
                            setState(() => _isEntrada = true),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _TypeChip(
                        icon: Icons.arrow_upward_rounded,
                        label: 'Salida',
                        color: AppColors.error,
                        selected: !_isEntrada,
                        onTap: () =>
                            setState(() => _isEntrada = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Cantidad ────────────────────────
                TextFormField(
                  controller: _cantidadCtrl,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Cantidad',
                    prefixIcon: Icon(
                      _isEntrada
                          ? Icons.add_circle_rounded
                          : Icons.remove_circle_rounded,
                      color: _isEntrada
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    suffixText: widget.item.unidad,
                  ),
                  validator: (v) {
                    final text = v?.trim() ?? '';
                    if (text.isEmpty) return 'Ingresa la cantidad.';
                    final qty = int.tryParse(text);
                    if (qty == null || qty <= 0) {
                      return 'Debe ser mayor a 0.';
                    }
                    if (!_isEntrada && qty > widget.item.stockActual) {
                      return 'Excede el stock actual (${widget.item.stockActual}).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Submit ──────────────────────────
                FilledButton.icon(
                  onPressed: _submit,
                  icon: Icon(
                    _isEntrada
                        ? Icons.add_rounded
                        : Icons.remove_rounded,
                  ),
                  label: Text(
                    _isEntrada
                        ? 'Registrar entrada'
                        : 'Registrar salida',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: _isEntrada
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Type chip for entrada/salida ─────────────────────────────────

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? color
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? color : null, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : null,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
