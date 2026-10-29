import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'telavaca.dart';
import 'telainseminar.dart';
import 'telatoque.dart';
import 'telaprenhez.dart';
import 'menuprincipal.dart';
import 'tela_historico.dart';
import 'formulario_baixas.dart';
import 'inf_baixas.dart';

class TelaBaixas extends StatefulWidget {
  const TelaBaixas({super.key});

  @override
  State<TelaBaixas> createState() => _TelaBaixasState();
}

class _TelaBaixasState extends State<TelaBaixas> {
  final TextEditingController _searchController = TextEditingController();
  String _busca = '';

  String? get _usuarioId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _botaoMenu(
    BuildContext context,
    IconData? icone,
    String label,
    Color corIcone,
    Widget tela, {
    bool usarImagem = false,
    String? caminhoImagem,
  }) {
    return TextButton(
      onPressed: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => tela),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          (usarImagem || caminhoImagem != null)
              ? Image.asset(
                  caminhoImagem ?? 'assets/img/animal.png',
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                  color: corIcone,
                )
              : Icon(icone, color: corIcone, size: 22),
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
        body: Center(child: Text('Usuário não autenticado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.brown,
      foregroundColor: Colors.white,
      title: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Image.asset(
                'assets/img/logo-landscape-white.png',
                height: 35,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const Center(
            child: Text(
              'Baixas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      centerTitle: true,
    ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.brown,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FormularioBaixas(),
            ),
          );
        },
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (valor) {
                setState(() {
                  _busca = valor.toLowerCase().trim();
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar animal por nome ou brinco...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.brown,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: Colors.brown,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('vacas')
                  .where('usuarioId', isEqualTo: usuarioId)
                  .where('baixado', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.brown,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Erro ao carregar os animais baixados.'),
                  );
                }

                final documentos = snapshot.data?.docs.where((doc) {
                      final dados = doc.data();
                      final nome =
                          (dados['nome'] ?? '').toString().toLowerCase();
                      final brinco =
                          (dados['brinco'] ?? '').toString().toLowerCase();

                      return nome.contains(_busca) ||
                          brinco.contains(_busca);
                    }).toList() ??
                    [];

                if (documentos.isEmpty) {
                  return const Center(
                    child: Text('Nenhum registro de baixa encontrado.'),
                  );
                }

                return ListView.builder(
                  itemCount: documentos.length,
                  itemBuilder: (context, index) {
                    final doc = documentos[index];
                    final dados = doc.data();

                    final vaca = <String, String>{
                      'id': (dados['brinco'] ?? '').toString(),
                      'nome': (dados['nome'] ?? 'Sem nome').toString(),
                      'motivo': (dados['motivoBaixa'] ?? 'Não informado')
                          .toString(),
                      'observacao':
                          (dados['observacaoBaixa'] ?? '').toString(),
                      'foto': (dados['foto'] ?? '').toString(),
                      'tipoAnimal': (dados['tipoAnimal'] ?? dados['tipo'] ?? '').toString(),
                      'vacaId': doc.id,
                    };

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: Image.asset(
                          (vaca['tipoAnimal']!.toLowerCase().contains('touro') ||
                                  vaca['tipoAnimal']!.toLowerCase().contains('macho'))
                              ? 'assets/img/touro.png'
                              : 'assets/img/animal.png',
                          width: 42,
                          height: 42,
                          fit: BoxFit.contain,
                          color: Colors.brown,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.pets, color: Colors.brown, size: 32),
                        ),
                        title: Text(
                          vaca['nome']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Brinco: ${vaca['id']}\n'
                          'Motivo: ${vaca['motivo']}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.brown,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InfBaixas(vaca: vaca),
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
              _botaoMenu(
                context,
                null,
                'ANIMAL',
                Colors.green,
                const TelaVaca(),
                usarImagem: true,
              ),
              _botaoMenu(
                context,
                Icons.vaccines,
                'INSEMINAR',
                Colors.blueAccent,
                const TelaInseminar(),
              ),
              _botaoMenu(
                context,
                null,
                'TOQUE',
                Colors.orange,
                const TelaToque(),
                caminhoImagem: 'assets/img/toque.png',
              ),
              _botaoMenu(
                context,
                Icons.favorite,
                'PRENHEZ',
                Colors.redAccent,
                const TelaPrenhez(),
              ),
              _botaoMenu(
                context,
                Icons.history,
                'HISTÓRICO',
                Colors.purpleAccent,
                const TelaHistorico(),
              ),
              _botaoMenu(
                context,
                Icons.home,
                'HOME',
                Colors.white,
                const MenuPrincipal(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}