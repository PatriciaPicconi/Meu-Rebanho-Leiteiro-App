import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'nova_senha.dart';

class RecuperarSenha extends StatelessWidget {
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
            SizedBox(height: 40),
            Text(
              "Enviaremos um código de acesso para o seu E-mail",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 30),
            Container(
              width: 200,
              child: TextField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 24, letterSpacing: 10),
                decoration: InputDecoration(
                  labelText: "Código",
                  hintText: "000000",
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(6),
                  FilteringTextInputFormatter.digitsOnly,
                ],
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
                  child: Text("ALTERAR", style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NovaSenha()),
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