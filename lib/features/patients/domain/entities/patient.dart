import 'package:cloud_firestore/cloud_firestore.dart';

class Patient {
  const Patient({
    required this.id,
    required this.nombre,
    required this.dpi,
    required this.fechaNacimiento,
    required this.genero,
    required this.telefono,
    required this.activo,
    this.telefonoEmergencia,
    this.contactoEmergencia,
    this.direccion,
    this.email,
    this.alergias,
    this.enfermedadesSistemicas,
    this.medicamentosActuales,
    this.notasClinicas,
  });

  final String id;
  final String nombre;
  final String dpi;
  final DateTime? fechaNacimiento;
  final String genero;
  final String telefono;
  final bool activo;

  // Opcionales
  final String? telefonoEmergencia;
  final String? contactoEmergencia;
  final String? direccion;
  final String? email;
  final String? alergias;
  final String? enfermedadesSistemicas;
  final String? medicamentosActuales;
  final String? notasClinicas;

  /// Edad calculada a partir de la fecha de nacimiento.
  int? get edad {
    final dob = fechaNacimiento;
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  /// True si el paciente tiene alergias registradas.
  bool get tieneAlergias =>
      alergias != null && alergias!.trim().isNotEmpty;

  /// Factory para crear desde Firestore document data.
  factory Patient.fromFirestore(String id, Map<String, dynamic> d) {
    DateTime? dob;
    final raw = d['fechaNacimiento'];
    if (raw is Timestamp) {
      dob = raw.toDate();
    }

    return Patient(
      id: id,
      nombre: (d['nombre'] as String?) ?? '',
      dpi: (d['dpi'] as String?) ?? '',
      fechaNacimiento: dob,
      genero: (d['genero'] as String?) ?? '',
      telefono: (d['telefono'] as String?) ?? '',
      activo: (d['activo'] as bool?) ?? true,
      telefonoEmergencia: d['telefonoEmergencia'] as String?,
      contactoEmergencia: d['contactoEmergencia'] as String?,
      direccion: d['direccion'] as String?,
      email: d['email'] as String?,
      alergias: d['alergias'] as String?,
      enfermedadesSistemicas: d['enfermedadesSistemicas'] as String?,
      medicamentosActuales: d['medicamentosActuales'] as String?,
      notasClinicas: d['notasClinicas'] as String?,
    );
  }
}
