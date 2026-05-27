import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'telavaca.dart';
import 'telainseminar.dart';
import 'telaprenhez.dart';
import 'telaperfil.dart';
import 'loja.dart';
import 'tela_historico.dart';
import 'tela_baixas.dart';

class TelaToque extends StatefulWidget {
  const TelaToque({super.key});

  @override
  State<TelaToque> createState() => _TelaToqueState();
}

class _TelaToqueState extends State<TelaToque> {
  final TextEditingController _buscaController = TextEditingController();
  String _busca = "";

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
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
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
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaPerfil()));
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _buscaController,
              onChanged: (value) => setState(() => _busca = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Pesquisar vaca por nome ou brinco...",
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
            .where('status', isEqualTo: 'Inseminada')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Erro ao carregar dados"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final documentos = snapshot.data!.docs.where((doc) {
            final nome = (doc['nome'] ?? "").toString().toLowerCase();
            final brinco = (doc['brinco'] ?? "").toString();
            return nome.contains(_busca) || brinco.contains(_busca);
          }).toList();

          if (documentos.isEmpty) {
            return const Center(child: Text("Nenhuma vaca pendente de toque."));
          }

          return ListView.builder(
            itemCount: documentos.length,
            itemBuilder: (context, index) {
              final doc = documentos[index];
              final vaca = doc.data() as Map<String, dynamic>;
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.front_hand, color: Colors.white),
                ),
                title: Text(vaca['nome'] ?? 'Sem nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Brinco: ${vaca['brinco']} - Insem.: ${vaca['ultimaInseminacao'] ?? '--/--/----'}"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FormularioToque(vaca: vaca, id: doc.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.green,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _botaoMenu(context, Icons.agriculture, "VACA", Colors.lightGreenAccent, const TelaVaca()),
              _botaoMenu(context, Icons.vaccines, "INSEMINAR", Colors.blue, const TelaInseminar()),
              _botaoMenu(context, Icons.favorite, "PRENHEZ", Colors.red, const TelaPrenhez()),
              _botaoMenu(context, Icons.shopping_cart, "LOJA", Colors.yellowAccent, const Loja()),
              _botaoMenu(context, Icons.history, "HISTÓRICO", Colors.white, const TelaHistorico()),
              _botaoMenu(context, Icons.trending_down, "BAIXAS", Colors.black54, const TelaBaixas()),
            ],
          ),
        ),
      ),
    );
  }
}

class FormularioToque extends StatefulWidget {
  final Map<String, dynamic> vaca;
  final String id;
  const FormularioToque({super.key, required this.vaca, required this.id});

  @override
  State<FormularioToque> createState() => _FormularioToqueState();
}

class _FormularioToqueState extends State<FormularioToque> {
  bool? _estaPrenha;

  void _confirmarExame() async {
    if (_estaPrenha == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecione o resultado!")));
      return;
    }

    await FirebaseFirestore.instance.collection('vacas').doc(widget.id).update({
      'status': _estaPrenha! ? 'Prenhe' : 'Vazia',
      'ultimoExameToque': DateTime.now().toString().split(' ')[0],
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirmar Resultado", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.front_hand, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              "Vaca: ${widget.vaca['nome']} (Brinco: ${widget.vaca['brinco']})",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            const Text("Resultado do Toque:", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            RadioListTile<bool>(
              title: const Text("Sim, está prenha"),
              value: true,
              groupValue: _estaPrenha,
              activeColor: Colors.green,
              onChanged: (value) => setState(() => _estaPrenha = value),
            ),
            RadioListTile<bool>(
              title: const Text("Não (Voltar para Vazia)"),
              value: false,
              groupValue: _estaPrenha,
              activeColor: Colors.green,
              onChanged: (value) => setState(() => _estaPrenha = value),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _confirmarExame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                "CONFIRMAR EXAME",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}