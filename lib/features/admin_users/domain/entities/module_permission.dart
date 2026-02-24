enum ModulePermission {
  dashboard,
  patients,
  appointments,
  billing,
  inventory,
  reports,
}

extension ModulePermissionX on ModulePermission {
  String get key {
    switch (this) {
      case ModulePermission.dashboard:
        return 'dashboard';
      case ModulePermission.patients:
        return 'patients';
      case ModulePermission.appointments:
        return 'appointments';
      case ModulePermission.billing:
        return 'billing';
      case ModulePermission.inventory:
        return 'inventory';
      case ModulePermission.reports:
        return 'reports';
    }
  }

  String get label {
    switch (this) {
      case ModulePermission.dashboard:
        return 'Dashboard';
      case ModulePermission.patients:
        return 'Pacientes';
      case ModulePermission.appointments:
        return 'Citas';
      case ModulePermission.billing:
        return 'Facturación';
      case ModulePermission.inventory:
        return 'Inventario';
      case ModulePermission.reports:
        return 'Reportes';
    }
  }
}

ModulePermission? modulePermissionFromKey(String key) {
  for (final permission in ModulePermission.values) {
    if (permission.key == key) {
      return permission;
    }
  }
  return null;
}