import 'package:flutter/material.dart';

class TelaCadastroUsuario extends StatelessWidget {
  const TelaCadastroUsuario({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cadastro de Usuário"),
        backgroundColor: Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            const TextField(
              decoration: InputDecoration(labelText: "Nome Completo"),
            ),
            const TextField(
              decoration: InputDecoration(labelText: "E-mail"),
            ),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: "Senha"),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                print("Usuário cadastrado com sucesso!");
              },
              child: const Text("CADASTRAR", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}