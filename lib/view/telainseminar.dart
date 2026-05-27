import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'telaperfil.dart';
import 'telavaca.dart';
import 'telatoque.dart';
import 'telaprenhez.dart';
import 'loja.dart';
import 'tela_historico.dart';
import 'tela_baixas.dart';
class TelaInseminar extends StatefulWidget {
  const TelaInseminar({super.key});

  @override
  State<TelaInseminar> createState() => _TelaInseminarState();
}

class _TelaInseminarState extends State<TelaInseminar> {
  final TextEditingController _buscaController = TextEditingController();
  String _filtro = "";

  Widget _botaoMenu(BuildContext context, IconData icone, String label, Color corIcone, Widget tela) {
    return TextButton(
      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => tela)),
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
        title: const Text("Vacas para Inseminar", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.person, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaPerfil()))),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _buscaController,
              onChanged: (value) => setState(() => _filtro = value.toLowerCase()),
              decoration: InputDecoration(hintText: "Pesquisar...", prefixIcon: const Icon(Icons.search), fillColor: Colors.white, filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('vacas').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Erro ao carregar"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final documentos = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['nome'].toString().toLowerCase().contains(_filtro) || data['brinco'].toString().toLowerCase().contains(_filtro);
          }).toList();

          return ListView.builder(
            itemCount: documentos.length,
            itemBuilder: (context, index) {
              final vaca = documentos[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.vaccines, color: Colors.white)),
                title: Text(vaca['nome'] ?? 'Sem nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Brinco: ${vaca['brinco'] ?? 'S/N'}"),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FormularioInseminar(brincoInicial: vaca['brinco']?.toString() ?? ""))),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blue,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _botaoMenu(context, Icons.agriculture, "VACAS", Colors.greenAccent, const TelaVaca()),
              _botaoMenu(context, Icons.front_hand, "TOQUE", Colors.orange, const TelaToque()),
              _botaoMenu(context, Icons.favorite, "PRENHEZ", Colors.redAccent, const TelaPrenhez()),
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

// --- FORMULÁRIO DE REGISTRO ---
class FormularioInseminar extends StatefulWidget {
  final String brincoInicial;
  const FormularioInseminar({super.key, this.brincoInicial = ""});

  @override
  State<FormularioInseminar> createState() => _FormularioInseminarState();
}

class _FormularioInseminarState extends State<FormularioInseminar> {
  final _brincoController = TextEditingController();
  final _dataCioController = TextEditingController();
  final _touroController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _brincoController.text = widget.brincoInicial;
  }

  void _salvar() async {
    await FirebaseFirestore.instance.collection('inseminacoes').add({
      'brinco': _brincoController.text,
      'data': _dataCioController.text,
      'touro': _touroController.text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar Inseminação"), backgroundColor: Colors.blue),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _brincoController, decoration: const InputDecoration(labelText: "Brinco")),
            TextField(controller: _dataCioController, decoration: const InputDecoration(labelText: "Data")),
            TextField(controller: _touroController, decoration: const InputDecoration(labelText: "Touro")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _salvar, child: const Text("SALVAR")),
          ],
        ),
      ),
    );
  }
}