enum Specialty {
  general,
  ortodoncia,
  endodoncia,
  periodoncia,
  cirugia,
  protesis,
  odontopediatria,
  estetica,
}

extension SpecialtyX on Specialty {
  String get key {
    switch (this) {
      case Specialty.general:
        return 'general';
      case Specialty.ortodoncia:
        return 'ortodoncia';
      case Specialty.endodoncia:
        return 'endodoncia';
      case Specialty.periodoncia:
        return 'periodoncia';
      case Specialty.cirugia:
        return 'cirugia';
      case Specialty.protesis:
        return 'protesis';
      case Specialty.odontopediatria:
        return 'odontopediatria';
      case Specialty.estetica:
        return 'estetica';
    }
  }

  String get label {
    switch (this) {
      case Specialty.general:
        return 'General';
      case Specialty.ortodoncia:
        return 'Ortodoncia';
      case Specialty.endodoncia:
        return 'Endodoncia';
      case Specialty.periodoncia:
        return 'Periodoncia';
      case Specialty.cirugia:
        return 'Cirugía oral';
      case Specialty.protesis:
        return 'Prótesis dental';
      case Specialty.odontopediatria:
        return 'Odontopediatría';
      case Specialty.estetica:
        return 'Estética dental';
    }
  }
}

Specialty? specialtyFromKey(String key) {
  for (final s in Specialty.values) {
    if (s.key == key) return s;
  }
  return null;
}
