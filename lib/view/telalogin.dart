import 'package:flutter/material.dart';
import 'menuprincipal.dart';
import 'recuperar_senha.dart';

class TelaLogin extends StatelessWidget {
  const TelaLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meu Rebanho Leiteiro"),
        backgroundColor: Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const TextField(
              decoration: InputDecoration(
                labelText: "E-mail",
              ),
            ),
            const SizedBox(height: 20),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Senha",
              ),
            ),
            TextButton(
              child: const Text(
                "Esqueci minha senha",
                style: TextStyle(color: Colors.green),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RecuperarSenha()),
                );
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MenuPrincipal()),
                );
              },
              child: const Text("ENTRAR"),
            ),
          ],
        ),
      ),
    );
  }
}