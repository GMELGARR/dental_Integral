import '../../domain/entities/clinical_record.dart';
import '../../domain/entities/tratamiento_realizado.dart';
import '../../domain/repositories/clinical_record_repository.dart';
import '../datasources/clinical_record_firestore_data_source.dart';

class ClinicalRecordRepositoryImpl implements ClinicalRecordRepository {
  ClinicalRecordRepositoryImpl(this._ds);
  final ClinicalRecordFirestoreDataSource _ds;

  @override
  Stream<List<ClinicalRecord>> observeByPatient(String pacienteId) =>
      _ds.observeByPatient(pacienteId);

  @override
  Future<ClinicalRecord?> getByAppointment(String citaId) =>
      _ds.getByAppointment(citaId);

  @override
  Future<void> create({
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
      _ds.create(
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
