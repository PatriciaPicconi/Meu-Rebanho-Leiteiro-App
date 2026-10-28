import 'package:flutter/material.dart';
import 'telavaca.dart';
import 'telainseminar.dart';
import 'telatoque.dart';
import 'telaprenhez.dart';
import 'telaperfil.dart';
import 'tela_historico.dart';
import 'tela_baixas.dart';

class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        /*
        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Image.asset(
            'assets/img/logo-landscape-white.png',
            height: 40,
            fit: BoxFit.contain,
          ),
        ),
        */
        titleSpacing: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.account_circle,
              size: 30,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TelaPerfil(),
                ),
              );
            },
          ),
        ],
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Image.asset(
                'assets/img/logo-landscape.png',
                height: 65,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              const Text(
                'O que deseja fazer hoje?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _itemMenu(
                    context,
                    "ANIMAL",
                    null,
                    Colors.green,
                    const TelaVaca(),
                  ),
                  _itemMenu(
                    context,
                    "INSEMINAÇÃO",
                    Icons.vaccines,
                    Colors.blue,
                    const TelaInseminar(),
                  ),
                  _itemMenu(
                    context,
                    "EXAME DE TOQUE",
                    null,
                    Colors.orange,
                    const TelaToque(),
                  ),
                  _itemMenu(
                    context,
                    "PRENHEZ",
                    Icons.favorite,
                    Colors.red,
                    const TelaPrenhez(),
                  ),
                  _itemMenu(
                    context,
                    "HISTÓRICO",
                    Icons.history,
                    Colors.purple,
                    const TelaHistorico(),
                  ),
                  _itemMenu(
                    context,
                    "BAIXAS",
                    Icons.trending_down,
                    Colors.brown,
                    const TelaBaixas(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemMenu(
    BuildContext context,
    String titulo,
    IconData? icone,
    Color cor,
    Widget tela,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => tela),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: cor.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icone != null
            ? Icon(icone, size: 50, color: cor)
            : Image.asset(
                titulo == "ANIMAL"
                    ? 'assets/img/animal.png'
                    : 'assets/img/toque.png',
                width: 50,
                height: 50,
                fit: BoxFit.contain,
              ),
            const SizedBox(height: 10),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}