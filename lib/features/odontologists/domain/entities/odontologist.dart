import 'specialty.dart';

class Odontologist {
  const Odontologist({
    required this.id,
    required this.nombre,
    required this.especialidad,
    required this.colegiadoActivo,
    required this.telefono,
    required this.email,
    required this.activo,
    this.userId,
    this.notas,
  });

  final String id;
  final String nombre;
  final Specialty especialidad;
  final String colegiadoActivo;
  final String telefono;
  final String email;
  final bool activo;

  /// Firebase Auth UID — `null` if the odontologist has no system account.
  final String? userId;
  final String? notas;
}
