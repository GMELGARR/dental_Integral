import '../entities/treatment.dart';

abstract class TreatmentRepository {
  Stream<List<Treatment>> observeAll();

  Future<void> create({
    required String nombre,
    required double monto,
    String? descripcion,
  });

  Future<void> update({
    required String id,
    required String nombre,
    required double monto,
    required bool activo,
    String? descripcion,
  });
}
