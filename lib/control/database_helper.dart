import 'package:flutter/material.dart';

class TelaAdicionarGado extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Adicionar Gado"),
        backgroundColor: Colors.green,
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                labelText: "Nome/Brinco do Animal",
                hintText: "Ex: Mimosa ou 102",
              ),
            ),
            TextField(
              decoration: InputDecoration(
                labelText: "Raça",
              ),
            ),
            TextField(
              decoration: InputDecoration(
                labelText: "Data de Nascimento",
                hintText: "DD/MM/AAAA",
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  child: Text("Cancelar"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text("Salvar Animal"),
                  onPressed: () {
                    print("Salvando dados...");
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