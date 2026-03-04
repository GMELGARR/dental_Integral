import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the condition applied to a single face or the whole tooth.
enum ToothCondition {
  sano, // healthy (default)
  caries,
  obturacion, // filling
  corona,
  extraccion,
  ausente,
  endodoncia,
  protesisFija,
  sellante,
}

/// Maps each condition to a display label.
extension ToothConditionLabel on ToothCondition {
  String get label {
    switch (this) {
      case ToothCondition.sano:
        return 'Sano';
      case ToothCondition.caries:
        return 'Caries';
      case ToothCondition.obturacion:
        return 'Obturación';
      case ToothCondition.corona:
        return 'Corona';
      case ToothCondition.extraccion:
        return 'Extracción';
      case ToothCondition.ausente:
        return 'Ausente';
      case ToothCondition.endodoncia:
        return 'Endodoncia';
      case ToothCondition.protesisFija:
        return 'Prótesis fija';
      case ToothCondition.sellante:
        return 'Sellante';
    }
  }

  /// Whether this condition applies to individual faces or the whole tooth.
  bool get appliesToWholeTooth {
    switch (this) {
      case ToothCondition.corona:
      case ToothCondition.extraccion:
      case ToothCondition.ausente:
      case ToothCondition.endodoncia:
      case ToothCondition.protesisFija:
        return true;
      default:
        return false;
    }
  }
}

/// The 5 faces of a tooth.
enum ToothFace { oclusal, mesial, distal, vestibular, lingual }

/// State of a single tooth (32 total in adult dentition).
class ToothState {
  ToothState({
    Map<ToothFace, ToothCondition>? faces,
    this.wholeTooth,
  }) : faces = faces ?? {};

  /// Conditions per face.
  final Map<ToothFace, ToothCondition> faces;

  /// Condition that applies to the whole tooth (overrides faces).
  ToothCondition? wholeTooth;

  bool get isHealthy =>
      wholeTooth == null &&
      faces.values.every((c) => c == ToothCondition.sano);

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (wholeTooth != null) {
      map['wholeTooth'] = wholeTooth!.name;
    }
    if (faces.isNotEmpty) {
      map['faces'] = {
        for (final e in faces.entries) e.key.name: e.value.name,
      };
    }
    return map;
  }

  factory ToothState.fromMap(Map<String, dynamic> map) {
    ToothCondition? whole;
    if (map['wholeTooth'] != null) {
      whole = ToothCondition.values.firstWhere(
        (c) => c.name == map['wholeTooth'],
        orElse: () => ToothCondition.sano,
      );
    }

    final facesMap = <ToothFace, ToothCondition>{};
    if (map['faces'] is Map) {
      final raw = map['faces'] as Map;
      for (final e in raw.entries) {
        final face = ToothFace.values.firstWhere(
          (f) => f.name == e.key,
          orElse: () => ToothFace.oclusal,
        );
        final cond = ToothCondition.values.firstWhere(
          (c) => c.name == e.value,
          orElse: () => ToothCondition.sano,
        );
        facesMap[face] = cond;
      }
    }

    return ToothState(faces: facesMap, wholeTooth: whole);
  }

  ToothState copyWith({
    Map<ToothFace, ToothCondition>? faces,
    ToothCondition? wholeTooth,
    bool clearWholeTooth = false,
  }) {
    return ToothState(
      faces: faces ?? Map.from(this.faces),
      wholeTooth: clearWholeTooth ? null : (wholeTooth ?? this.wholeTooth),
    );
  }
}

/// History entry for a single change.
class OdontogramChange {
  const OdontogramChange({
    required this.fecha,
    required this.modificadoPor,
    required this.diente,
    required this.descripcion,
  });

  final DateTime fecha;
  final String modificadoPor;
  final String diente;
  final String descripcion;

  Map<String, dynamic> toMap() => {
        'fecha': Timestamp.fromDate(fecha),
        'modificadoPor': modificadoPor,
        'diente': diente,
        'descripcion': descripcion,
      };

  factory OdontogramChange.fromMap(Map<String, dynamic> map) {
    return OdontogramChange(
      fecha: (map['fecha'] as Timestamp).toDate(),
      modificadoPor: map['modificadoPor'] ?? '',
      diente: map['diente'] ?? '',
      descripcion: map['descripcion'] ?? '',
    );
  }
}

/// The complete odontogram for one patient.
class Odontogram {
  Odontogram({
    required this.pacienteId,
    Map<String, ToothState>? dientes,
    List<OdontogramChange>? historial,
    this.updatedAt,
  })  : dientes = dientes ?? {},
        historial = historial ?? [];

  final String pacienteId;

  /// Map of tooth number (FDI notation: "11"-"48") → state.
  final Map<String, ToothState> dientes;

  /// Change log.
  final List<OdontogramChange> historial;

  final DateTime? updatedAt;

  /// All 32 adult teeth in FDI notation.
  static const upperRight = ['18', '17', '16', '15', '14', '13', '12', '11'];
  static const upperLeft = ['21', '22', '23', '24', '25', '26', '27', '28'];
  static const lowerLeft = ['31', '32', '33', '34', '35', '36', '37', '38'];
  static const lowerRight = ['48', '47', '46', '45', '44', '43', '42', '41'];
  static const allTeeth = [
    ...upperRight,
    ...upperLeft,
    ...lowerRight,
    ...lowerLeft,
  ];

  ToothState toothState(String number) =>
      dientes[number] ?? ToothState();

  Map<String, dynamic> toMap() => {
        'dientes': {
          for (final e in dientes.entries) e.key: e.value.toMap(),
        },
        'historial': historial.map((h) => h.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory Odontogram.fromFirestore(String pacienteId, Map<String, dynamic> map) {
    final dientesMap = <String, ToothState>{};
    if (map['dientes'] is Map) {
      final raw = map['dientes'] as Map;
      for (final e in raw.entries) {
        if (e.value is Map<String, dynamic>) {
          dientesMap[e.key as String] =
              ToothState.fromMap(e.value as Map<String, dynamic>);
        }
      }
    }

    final historialList = <OdontogramChange>[];
    if (map['historial'] is List) {
      for (final h in map['historial'] as List) {
        if (h is Map<String, dynamic>) {
          historialList.add(OdontogramChange.fromMap(h));
        }
      }
    }

    DateTime? updated;
    if (map['updatedAt'] is Timestamp) {
      updated = (map['updatedAt'] as Timestamp).toDate();
    }

    return Odontogram(
      pacienteId: pacienteId,
      dientes: dientesMap,
      historial: historialList,
      updatedAt: updated,
    );
  }
}
