import 'package:flutter/material.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administrar usuarios (sin costo)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestión de usuarios sin Blaze',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 12),
                Text(
                  'Para mantener costo 0, la creación de usuarios se realiza con script local de administrador (no desde la app).',
                ),
                SizedBox(height: 12),
                Text('Pasos:'),
                SizedBox(height: 8),
                Text('1) Configura una cuenta de servicio de Firebase Admin.'),
                Text('2) Ejecuta el script en scripts/admin/create_staff_user.js.'),
                Text('3) Asigna módulos en el parámetro modules.'),
                SizedBox(height: 16),
                Text(
                  'La app seguirá aplicando permisos por claims y módulos almacenados en Firestore.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}