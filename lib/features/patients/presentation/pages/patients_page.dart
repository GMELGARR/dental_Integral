import 'package:flutter/material.dart';

class PatientsPage extends StatelessWidget {
  const PatientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pacientes')),
      body: const Center(
        child: Text('Módulo de pacientes listo para Sprint 4.'),
      ),
    );
  }
}