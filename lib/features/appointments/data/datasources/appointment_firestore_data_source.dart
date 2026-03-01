import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/appointment.dart';

class AppointmentFirestoreDataSource {
  AppointmentFirestoreDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('citas');

  /// Stream of appointments whose [fecha] falls within [start] .. [end].
  Stream<List<Appointment>> observeByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return _col
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('fecha')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => Appointment.fromFirestore(d.id, d.data()))
          .toList();
      list.sort((a, b) {
        final cmp = a.fecha.compareTo(b.fecha);
        return cmp != 0 ? cmp : a.hora.compareTo(b.hora);
      });
      return list;
    });
  }

  /// One-shot fetch of appointments for a specific odontólogo on a date.
  Future<List<Appointment>> getByOdontologoAndDate(
    String odontologoId,
    DateTime date,
  ) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    // Query only by fecha range to avoid needing a composite index.
    // Filter by odontologoId locally.
    final snap = await _col
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(dayEnd))
        .get();

    final list = snap.docs
        .map((d) => Appointment.fromFirestore(d.id, d.data()))
        .where((a) => a.odontologoId == odontologoId)
        .toList();
    list.sort((a, b) => a.hora.compareTo(b.hora));
    return list;
  }

  Future<void> create({
    required String tipo,
    required DateTime fecha,
    required String hora,
    required String odontologoId,
    required String odontologoNombre,
    required String pacienteNombre,
    required String pacienteTelefono,
    int duracionMinutos = 30,
    String? pacienteId,
    String? nombreTemporal,
    String? telefonoTemporal,
    String? motivo,
    String? tratamientoId,
    String? notas,
  }) async {
    await _col.add({
      'tipo': tipo,
      'fecha': Timestamp.fromDate(
        DateTime(fecha.year, fecha.month, fecha.day),
      ),
      'hora': hora,
      'duracionMinutos': duracionMinutos,
      'estado': AppointmentStatus.programada,
      'odontologoId': odontologoId,
      'odontologoNombre': odontologoNombre,
      'pacienteNombre': pacienteNombre,
      'pacienteTelefono': pacienteTelefono,
      if (pacienteId != null) 'pacienteId': pacienteId,
      if (nombreTemporal != null) 'nombreTemporal': nombreTemporal,
      if (telefonoTemporal != null) 'telefonoTemporal': telefonoTemporal,
      if (motivo != null) 'motivo': motivo,
      if (tratamientoId != null) 'tratamientoId': tratamientoId,
      if (notas != null) 'notas': notas,
      'creadoEn': FieldValue.serverTimestamp(),
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  Future<void> update({
    required String id,
    String? estado,
    String? hora,
    String? motivo,
    String? notas,
    String? pacienteId,
    String? pacienteNombre,
    String? pacienteTelefono,
  }) async {
    final data = <String, dynamic>{
      'actualizadoEn': FieldValue.serverTimestamp(),
    };
    if (estado != null) data['estado'] = estado;
    if (hora != null) data['hora'] = hora;
    if (motivo != null) data['motivo'] = motivo;
    if (notas != null) data['notas'] = notas;
    if (pacienteId != null) data['pacienteId'] = pacienteId;
    if (pacienteNombre != null) data['pacienteNombre'] = pacienteNombre;
    if (pacienteTelefono != null) data['pacienteTelefono'] = pacienteTelefono;

    await _col.doc(id).update(data);
  }
}
