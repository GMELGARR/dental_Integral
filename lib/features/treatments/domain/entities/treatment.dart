class Treatment {
  const Treatment({
    required this.id,
    required this.nombre,
    required this.monto,
    required this.activo,
    this.descripcion,
  });

  final String id;
  final String nombre;
  final double monto;
  final bool activo;
  final String? descripcion;
}
