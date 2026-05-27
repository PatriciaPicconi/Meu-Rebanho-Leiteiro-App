import 'package:flutter/material.dart';

class TelaConsulta extends StatelessWidget {
  const TelaConsulta({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Consulta"),
      ),
      body: const Center(
        child: Text("Tela de Consulta"),
      ),
    );
  }
}