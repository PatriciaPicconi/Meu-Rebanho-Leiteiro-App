import 'package:flutter/material.dart';
import 'menuprincipal.dart';

class TelaCadastro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Registrar Dados"),
        backgroundColor: Colors.white,
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Text(
              "Preencha as informações do campo:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            TextField(
              decoration: InputDecoration(labelText: "Nome do Animal"),
            ),

            TextField(
              decoration: InputDecoration(labelText: "Raça"),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text("Salvar", style: TextStyle(color: Colors.white)),
              onPressed: () {
                print("Botão salvar clicado");
              },
            ),
          ],
        ),
      ),
    );
  }
}