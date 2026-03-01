import '../entities/tratamiento_realizado.dart';
import '../repositories/clinical_record_repository.dart';

class CreateClinicalRecord {
  CreateClinicalRecord(this._repo);
  final ClinicalRecordRepository _repo;

  Future<void> call({
    required String citaId,
    required String pacienteId,
    required String pacienteNombre,
    required String odontologoId,
    required String odontologoNombre,
    required DateTime fecha,
    required List<TratamientoRealizado> tratamientos,
    required double subtotal,
    required double descuentoMonto,
    required double cargoExtra,
    required double costoTotal,
    String? diagnostico,
    String? piezasDentales,
    String? notasClinicas,
    String? indicaciones,
    String? proximaCitaSugerida,
    String? notaCargoExtra,
  }) =>
      _repo.create(
        citaId: citaId,
        pacienteId: pacienteId,
        pacienteNombre: pacienteNombre,
        odontologoId: odontologoId,
        odontologoNombre: odontologoNombre,
        fecha: fecha,
        tratamientos: tratamientos,
        subtotal: subtotal,
        descuentoMonto: descuentoMonto,
        cargoExtra: cargoExtra,
        costoTotal: costoTotal,
        diagnostico: diagnostico,
        piezasDentales: piezasDentales,
        notasClinicas: notasClinicas,
        indicaciones: indicaciones,
        proximaCitaSugerida: proximaCitaSugerida,
        notaCargoExtra: notaCargoExtra,
      );
}
