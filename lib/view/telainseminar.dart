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
        title: const Text("Vacas para Inseminar", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
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
              onChanged: (value) => setState(() => _filtro = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Pesquisar por nome ou brinco...",
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
        stream: FirebaseFirestore.instance.collection('vacas').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Erro ao carregar"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final documentos = snapshot.data!.docs.where((doc) {
            final nome = doc['nome'].toString().toLowerCase();
            final brinco = doc['brinco'].toString().toLowerCase();
            return nome.contains(_filtro) || brinco.contains(_filtro);
          }).toList();

          return ListView.builder(
            itemCount: documentos.length,
            itemBuilder: (context, index) {
              final vaca = documentos[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.vaccines, color: Colors.white),
                ),
                title: Text(vaca['nome'] ?? 'Sem nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Brinco: ${vaca['brinco'] ?? 'S/N'}"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FormularioInseminar(
                        brincoInicial: vaca['brinco']?.toString() ?? "",
                      ),
                    ),
                  );
                },
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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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

class FormularioInseminar extends StatefulWidget {
  final String brincoInicial;
  const FormularioInseminar({super.key, this.brincoInicial = ""});

  @override
  State<FormularioInseminar> createState() => _FormularioInseminarState();
}

class _FormularioInseminarState extends State<FormularioInseminar> {
  late TextEditingController _brincoController;
  final _dataCioController = TextEditingController();
  final _touroController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _brincoController = TextEditingController(text: widget.brincoInicial);
  }

  @override
  void dispose() {
    _brincoController.dispose();
    _dataCioController.dispose();
    _touroController.dispose();
    super.dispose();
  }

  void _salvarInseminacao() async {
    try {
      await FirebaseFirestore.instance.collection('inseminacoes').add({
        'brinco': _brincoController.text,
        'dataCio': _dataCioController.text,
        'touro': _touroController.text,
        'dataRegistro': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inseminação registrada com sucesso!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao salvar: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrar Procedimento", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Icon(Icons.vaccines, size: 80, color: Colors.blue)),
            const SizedBox(height: 20),
            const Text("Dados do Animal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _brincoController,
              decoration: const InputDecoration(labelText: "Número do Brinco", border: OutlineInputBorder(), prefixIcon: Icon(Icons.numbers)),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _dataCioController,
              decoration: const InputDecoration(labelText: "Data do Cio (DD/MM/AAAA)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _touroController,
              decoration: const InputDecoration(labelText: "Touro (Sêmen)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.pets)),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _salvarInseminacao,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("SALVAR REGISTRO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}