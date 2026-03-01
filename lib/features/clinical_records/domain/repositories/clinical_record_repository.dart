import '../entities/clinical_record.dart';
import '../entities/tratamiento_realizado.dart';

abstract class ClinicalRecordRepository {
  /// Real-time stream of clinical records for a specific patient.
  Stream<List<ClinicalRecord>> observeByPatient(String pacienteId);

  /// One-shot fetch of the clinical record linked to a specific appointment.
  Future<ClinicalRecord?> getByAppointment(String citaId);

  /// Create a new clinical record.
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
  });
}
