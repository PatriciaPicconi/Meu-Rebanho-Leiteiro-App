import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  String _filtroNome = '';

  Widget _botaoMenu(BuildContext context, IconData icone, String label, Color corIcone, Widget tela) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Meu Rebanho Leiteiro",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.brown,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white, size: 30),
            onPressed: () {},
          ),
        ],
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
                hintText: 'Buscar no histórico por nome ou número...',
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
              stream: FirebaseFirestore.instance.collection('vacas').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.brown));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Nenhum registro encontrado no Firebase."));
                }

                final docsFiltrados = snapshot.data!.docs.where((doc) {
                  final dados = doc.data() as Map<String, dynamic>;
                  final nome = (dados['nome'] ?? '').toString().toLowerCase();
                  final id = (dados['id'] ?? '').toString().toLowerCase();
                  return nome.contains(_filtroNome) || id.contains(_filtroNome);
                }).toList();

                if (docsFiltrados.isEmpty) {
                  return const Center(child: Text("Nenhum gado corresponds à busca."));
                }

                return ListView.builder(
                  itemCount: docsFiltrados.length,
                  itemBuilder: (context, index) {
                    final doc = docsFiltrados[index];
                    final vacaDados = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(vacaDados['foto'] ?? 'https://via.placeholder.com/150'),
                        ),
                        title: Text(
                          vacaDados['nome'] ?? 'Sem nome',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Número: ${vacaDados['id'] ?? 'N/A'}'),
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