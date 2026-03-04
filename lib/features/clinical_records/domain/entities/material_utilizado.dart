/// A single material/inventory item consumed during a consultation.
class MaterialUtilizado {
  const MaterialUtilizado({
    required this.materialId,
    required this.nombre,
    required this.unidad,
    this.cantidad = 1,
  });

  /// Reference to the inventory item document.
  final String materialId;

  /// Denormalized name for fast display.
  final String nombre;

  /// Unit of measure (e.g. "unidades", "ml", "pares").
  final String unidad;

  /// Quantity consumed.
  final int cantidad;

  MaterialUtilizado copyWith({
    String? materialId,
    String? nombre,
    String? unidad,
    int? cantidad,
  }) {
    return MaterialUtilizado(
      materialId: materialId ?? this.materialId,
      nombre: nombre ?? this.nombre,
      unidad: unidad ?? this.unidad,
      cantidad: cantidad ?? this.cantidad,
    );
  }

  Map<String, dynamic> toMap() => {
        'materialId': materialId,
        'nombre': nombre,
        'unidad': unidad,
        'cantidad': cantidad,
      };

  factory MaterialUtilizado.fromMap(Map<String, dynamic> map) {
    return MaterialUtilizado(
      materialId: map['materialId'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      unidad: map['unidad'] as String? ?? 'unidades',
      cantidad: (map['cantidad'] as num?)?.toInt() ?? 1,
    );
  }
}
