import 'package:flutter/material.dart';
import 'telavaca.dart';
import 'telainseminar.dart';
import 'telatoque.dart';
import 'telaprenhez.dart';
import 'telaperfil.dart';
import 'loja.dart';
import 'tela_historico.dart';
import 'tela_baixas.dart';

class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "MEU REBANHO LEITEIRO",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaPerfil()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            _itemMenu(context, "VACA", Icons.agriculture, Colors.green, const TelaVaca()),
            _itemMenu(context, "INSEMINAÇÃO", Icons.vaccines, Colors.blue, const TelaInseminar()),
            _itemMenu(context, "EXAME DE TOQUE", Icons.front_hand, Colors.orange, const TelaToque()),
            _itemMenu(context, "PRENHEZ", Icons.favorite, Colors.red, const TelaPrenhez()),
            _itemMenu(context, "LOJA", Icons.shopping_cart, Colors.purple, const Loja()),
            _itemMenu(context, "HISTÓRICO", Icons.history, Colors.teal, const TelaHistorico()),
            _itemMenu(context, "BAIXAS", Icons.trending_down, Colors.brown, const TelaBaixas()),
          ],
        ),
      ),
    );
  }

  Widget _itemMenu(BuildContext context, String titulo, IconData icone, Color cor, Widget tela) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => tela));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
          ],
          border: Border.all(color: cor.withValues(alpha: 0.5), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, size: 50, color: cor),
            const SizedBox(height: 10),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}