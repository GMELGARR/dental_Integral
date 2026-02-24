import 'package:flutter/material.dart';

import '../../domain/entities/module_permission.dart';

IconData moduleIcon(ModulePermission p) {
  switch (p) {
    case ModulePermission.dashboard:
      return Icons.dashboard_rounded;
    case ModulePermission.patients:
      return Icons.groups_rounded;
    case ModulePermission.odontologists:
      return Icons.medical_services_rounded;
    case ModulePermission.appointments:
      return Icons.event_available_rounded;
    case ModulePermission.billing:
      return Icons.receipt_long_rounded;
    case ModulePermission.inventory:
      return Icons.inventory_2_rounded;
    case ModulePermission.reports:
      return Icons.bar_chart_rounded;
  }
}
