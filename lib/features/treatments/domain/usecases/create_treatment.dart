import '../repositories/treatment_repository.dart';

class CreateTreatment {
  CreateTreatment(this._repository);

  final TreatmentRepository _repository;

  Future<void> call({
    required String nombre,
    required double monto,
    String? descripcion,
  }) {
    return _repository.create(
      nombre: nombre,
      monto: monto,
      descripcion: descripcion,
    );
  }
}
