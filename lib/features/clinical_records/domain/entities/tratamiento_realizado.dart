/// A single treatment line item within a clinical record (cart item).
class TratamientoRealizado {
  const TratamientoRealizado({
    required this.tratamientoId,
    required this.nombre,
    required this.precioUnitario,
    this.cantidad = 1,
  });

  /// Reference to the treatment catalogue document.
  final String tratamientoId;

  /// Denormalized treatment name for fast display.
  final String nombre;

  /// Unit price (pre-filled from catalogue, editable).
  final double precioUnitario;

  /// Quantity of this treatment applied.
  final int cantidad;

  double get subtotal => precioUnitario * cantidad;

  TratamientoRealizado copyWith({
    String? tratamientoId,
    String? nombre,
    double? precioUnitario,
    int? cantidad,
  }) {
    return TratamientoRealizado(
      tratamientoId: tratamientoId ?? this.tratamientoId,
      nombre: nombre ?? this.nombre,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      cantidad: cantidad ?? this.cantidad,
    );
  }

  Map<String, dynamic> toMap() => {
        'tratamientoId': tratamientoId,
        'nombre': nombre,
        'precioUnitario': precioUnitario,
        'cantidad': cantidad,
        'subtotal': subtotal,
      };

  factory TratamientoRealizado.fromMap(Map<String, dynamic> m) {
    return TratamientoRealizado(
      tratamientoId: m['tratamientoId'] as String? ?? '',
      nombre: m['nombre'] as String? ?? '',
      precioUnitario: (m['precioUnitario'] as num?)?.toDouble() ?? 0,
      cantidad: (m['cantidad'] as int?) ?? 1,
    );
  }
}
