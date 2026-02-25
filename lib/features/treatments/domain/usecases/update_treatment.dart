import '../repositories/treatment_repository.dart';

class UpdateTreatment {
  UpdateTreatment(this._repository);

  final TreatmentRepository _repository;

  Future<void> call({
    required String id,
    required String nombre,
    required double monto,
    required bool activo,
    String? descripcion,
  }) {
    return _repository.update(
      id: id,
      nombre: nombre,
      monto: monto,
      activo: activo,
      descripcion: descripcion,
    );
  }
}
