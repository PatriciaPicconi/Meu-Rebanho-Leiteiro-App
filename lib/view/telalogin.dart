import 'package:flutter/material.dart';
import 'menuprincipal.dart';
import 'recuperar_senha.dart';

class TelaLogin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Meu Rebanho Leiteiro"),
        backgroundColor: Colors.white,
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                labelText: "E-mail",
              ),
            ),
            SizedBox(height: 20),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Senha",
              ),
            ),
            TextButton(
              child: Text(
                "Esqueci minha senha",
                style: TextStyle(color: Colors.green),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RecuperarSenha()),
                );
              },
            ),
            SizedBox(height: 30),
            ElevatedButton(
              child: Text("ENTRAR"),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MenuPrincipal())
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}