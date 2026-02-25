/// Categories used to classify inventory items.
class InventoryCategories {
  InventoryCategories._();

  static const materiales = 'Materiales Dentales';
  static const desechables = 'Desechables';
  static const instrumental = 'Instrumental';
  static const medicamentos = 'Medicamentos';
  static const generales = 'Insumos Generales';

  static const all = [
    materiales,
    desechables,
    instrumental,
    medicamentos,
    generales,
  ];
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.unidad,
    required this.stockActual,
    required this.stockMinimo,
    required this.costoUnitario,
    required this.activo,
    this.descripcion,
  });

  final String id;
  final String nombre;
  final String categoria;
  final String unidad;
  final int stockActual;
  final int stockMinimo;
  final double costoUnitario;
  final bool activo;
  final String? descripcion;

  /// True when stock is at or below the minimum threshold.
  bool get stockBajo => stockActual <= stockMinimo;

  /// True when stock has reached zero.
  bool get agotado => stockActual <= 0;
}
