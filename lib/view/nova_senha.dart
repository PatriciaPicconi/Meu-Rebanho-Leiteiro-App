import 'package:flutter/material.dart';
import 'menuprincipal.dart';

class NovaSenha extends StatelessWidget {
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Meu Rebanho Leiteiro"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: 30),
            Text(
              "Defina sua nova senha de acesso",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            TextField(
              controller: _senhaController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Nova Senha",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _confirmarController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Confirmar Senha",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text("CANCELAR", style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: Text("ENTRAR", style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MenuPrincipal()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}