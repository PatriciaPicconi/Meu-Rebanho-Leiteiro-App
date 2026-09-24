import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'telavaca.dart';
import 'telainseminar.dart';
import 'telatoque.dart';
import 'telaperfil.dart';
import 'tela_historico.dart';
import 'tela_baixas.dart';

class TelaPrenhez extends StatefulWidget {
  const TelaPrenhez({super.key});

  @override
  State<TelaPrenhez> createState() => _TelaPrenhezState();
}

class _TelaPrenhezState extends State<TelaPrenhez> {
  final TextEditingController _buscaController = TextEditingController();
  String _busca = "";

  String? get _usuarioId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Widget _botaoMenu(
      BuildContext context,
      IconData icone,
      String label,
      Color corIcone,
      Widget tela,
      ) {
    return TextButton(
      onPressed: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => tela),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, color: corIcone, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuarioId = _usuarioId;

    if (usuarioId == null) {
      return const Scaffold(
        body: Center(child: Text("Usuário não autenticado.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Prenhez",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TelaPerfil()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _buscaController,
              onChanged: (value) {
                setState(() {
                  _busca = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Pesquisar vaca prenhe...",
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vacas')
            .where('usuarioId', isEqualTo: usuarioId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Erro ao carregar dados."));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final documentos = snapshot.data!.docs.where((doc) {
            final dados = doc.data() as Map<String, dynamic>;
            final nome = (dados['nome'] ?? "").toString().toLowerCase();
            final brinco = (dados['brinco'] ?? "").toString().toLowerCase();
            final status = (dados['status'] ?? "").toString();

            return status == 'Prenhe' &&
                (nome.contains(_busca) || brinco.contains(_busca));
          }).toList();

          if (documentos.isEmpty) {
            return const Center(child: Text("Nenhuma vaca prenhe encontrada."));
          }

          return ListView.builder(
            itemCount: documentos.length,
            itemBuilder: (context, index) {
              final doc = documentos[index];
              final vaca = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.favorite, color: Colors.white),
                  ),
                  title: Text(
                    "${vaca['nome'] ?? 'Sem nome'} (Brinco: ${vaca['brinco'] ?? 'N/A'})",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Previsão de Parto: ${vaca['ultimoParto'] ?? '--/--/----'}",
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetalhesPrenhez(vaca: vaca),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.red,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _botaoMenu(context, Icons.agriculture, "VACA", Colors.green, const TelaVaca()),
              _botaoMenu(context, Icons.vaccines, "INSEMINAR", Colors.blue, const TelaInseminar()),
              _botaoMenu(context, Icons.front_hand, "TOQUE", Colors.orange, const TelaToque()),
              _botaoMenu(context, Icons.history, "HISTÓRICO", Colors.purpleAccent, const TelaHistorico()),
              _botaoMenu(context, Icons.trending_down, "BAIXAS", Colors.brown, const TelaBaixas()),
            ],
          ),
        ),
      ),
    );
  }
}

class DetalhesPrenhez extends StatelessWidget {
  final Map<String, dynamic> vaca;

  const DetalhesPrenhez({super.key, required this.vaca});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalhes da Prenhez", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.pets, size: 60, color: Colors.white),
                      ),
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: Colors.red,
                          radius: 18,
                          child: Icon(Icons.favorite, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    vaca['nome'] ?? "Sem nome",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Brinco: ${vaca['brinco'] ?? "N/A"}",
                    style: const TextStyle(fontSize: 18, color: Colors.purple),
                  ),
                ],
              ),
            ),
            const Divider(height: 40),
            _cardData(
              "Data da Inseminação",
              vaca['ultimaInseminacao'] ?? "--/--/----",
              Icons.calendar_today,
              Colors.blue,
            ),
            const SizedBox(height: 15),
            _cardData(
              "Data do Exame de Toque",
              vaca['ultimoExameToque'] ?? "--/--/----",
              Icons.front_hand,
              Colors.orange,
            ),
            const SizedBox(height: 15),
            _cardData(
              "Previsão de Parto",
              vaca['ultimoParto'] ?? "--/--/----",
              Icons.child_care,
              Colors.red,
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.red),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Após o parto, o animal poderá retornar para o status 'Vazia'.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardData(String titulo, String data, IconData icone, Color cor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icone, color: cor, size: 30),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontSize: 13, color: Colors.purple)),
              Text(data, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}