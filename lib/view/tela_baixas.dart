import 'package:flutter/material.dart';
import 'telavaca.dart';
import 'telainseminar.dart';
import 'telatoque.dart';
import 'telaprenhez.dart';
import 'tela_historico.dart';
import 'telaperfil.dart';
import 'formulario_baixas.dart';
import 'inf_baixas.dart';

class TelaBaixas extends StatefulWidget {
  const TelaBaixas({super.key});

  @override
  State<TelaBaixas> createState() => _TelaBaixasState();
}

class _TelaBaixasState extends State<TelaBaixas> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, String>> _todasAsVacas = [];
  List<Map<String, String>> _vacasFiltradas = [];

  @override
  void initState() {
    super.initState();
    _vacasFiltradas = _todasAsVacas;
  }

  void _filtrarVacas(String query) {
    setState(() {
      _vacasFiltradas = _todasAsVacas.where((vaca) {
        final nome = vaca['nome']!.toLowerCase();
        final numero = vaca['id']!.toLowerCase();
        final input = query.toLowerCase();

        return nome.contains(input) || numero.contains(input);
      }).toList();
    });
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
          Icon(
            icone,
            color: corIcone,
            size: 22,
          ),
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
          "Baixas",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.brown,
        automaticallyImplyLeading: false,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.brown,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        onPressed: () async {
          final Map<String, String>? novaBaixa = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FormularioBaixas(),
            ),
          );

          if (novaBaixa != null) {
            setState(() {
              _todasAsVacas.add(novaBaixa);
              _filtrarVacas(_searchController.text);
            });
          }
        },
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filtrarVacas,
              decoration: InputDecoration(
                hintText: 'Buscar vaca por nome ou número...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.brown,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  borderSide: const BorderSide(
                    color: Colors.brown,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: _vacasFiltradas.isEmpty
                ? const Center(
              child: Text(
                "Nenhum registro encontrado.",
              ),
            )
                : ListView.builder(
              itemCount: _vacasFiltradas.length,
              itemBuilder: (context, index) {
                final vaca = _vacasFiltradas[index];

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
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        vaca['foto'] ??
                            'https://via.placeholder.com/150',
                      ),
                    ),
                    title: Text(
                      vaca['nome']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Número: ${vaca['id']}',
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.purple,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InfBaixas(
                            vaca: vaca,
                          ),
                        ),
                      );
                    },
                  ),
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
                Icons.agriculture,
                "VACAS",
                Colors.green,
                const TelaVaca(),
              ),

              _botaoMenu(
                context,
                Icons.vaccines,
                "INSEMINAR",
                Colors.blueAccent,
                const TelaInseminar(),
              ),

              _botaoMenu(
                context,
                Icons.front_hand,
                "TOQUE",
                Colors.orange,
                const TelaToque(),
              ),

              _botaoMenu(
                context,
                Icons.favorite,
                "PRENHEZ",
                Colors.redAccent,
                const TelaPrenhez(),
              ),

              _botaoMenu(
                context,
                Icons.history,
                "HISTÓRICO",
                Colors.purpleAccent,
                const TelaHistorico(),
              ),

              _botaoMenu(
                context,
                Icons.person,
                "PERFIL",
                Colors.yellowAccent,
                const TelaPerfil(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}