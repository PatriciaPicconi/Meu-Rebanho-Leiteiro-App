import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'telavaca.dart';
import 'telainseminar.dart';
import 'telatoque.dart';
import 'telaprenhez.dart';
import 'loja.dart';
import 'detalhe_historico.dart';

class TelaHistorico extends StatefulWidget {
  const TelaHistorico({super.key});

  @override
  State<TelaHistorico> createState() => _TelaHistoricoState();
}

class _TelaHistoricoState extends State<TelaHistorico> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroNome = "";

  String? get _usuarioId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _searchController.dispose();
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
        title: const Text(
          "Meu Rebanho Leiteiro",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.brown,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _filtroNome = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar no histórico por nome ou brinco...',
                prefixIcon: const Icon(Icons.search, color: Colors.brown),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  borderSide: const BorderSide(color: Colors.brown, width: 2),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vacas')
                  .where('usuarioId', isEqualTo: usuarioId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.brown),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text("Erro ao carregar histórico."),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("Nenhum registro encontrado para este usuário."),
                  );
                }

                final docsFiltrados = snapshot.data!.docs.where((doc) {
                  final dados = doc.data() as Map<String, dynamic>;
                  final nome = (dados['nome'] ?? '').toString().toLowerCase();
                  final brinco = (dados['brinco'] ?? '').toString().toLowerCase();

                  return nome.contains(_filtroNome) || brinco.contains(_filtroNome);
                }).toList();

                if (docsFiltrados.isEmpty) {
                  return const Center(
                    child: Text("Nenhum animal corresponde à busca."),
                  );
                }

                return ListView.builder(
                  itemCount: docsFiltrados.length,
                  itemBuilder: (context, index) {
                    final doc = docsFiltrados[index];
                    final vacaDados = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(
                            vacaDados['foto'] ?? 'https://via.placeholder.com/150',
                          ),
                        ),
                        title: Text(
                          vacaDados['nome'] ?? 'Sem nome',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Brinco: ${vacaDados['brinco'] ?? 'N/A'}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetalheHistorico(vacaId: doc.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.brown,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _botaoMenu(context, Icons.agriculture, "VACAS", Colors.greenAccent, const TelaVaca()),
              _botaoMenu(context, Icons.vaccines, "INSEMINAR", Colors.blueAccent, const TelaInseminar()),
              _botaoMenu(context, Icons.front_hand, "TOQUE", Colors.orange, const TelaToque()),
              _botaoMenu(context, Icons.favorite, "PRENHEZ", Colors.redAccent, const TelaPrenhez()),
              _botaoMenu(context, Icons.shopping_cart, "LOJA", Colors.yellowAccent, const Loja()),
              _botaoMenu(context, Icons.history, "HISTÓRICO", Colors.white, const TelaHistorico()),
            ],
          ),
        ),
      ),
    );
  }
}