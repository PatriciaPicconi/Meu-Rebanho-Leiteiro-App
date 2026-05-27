import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'telainseminar.dart';
import 'telatoque.dart';
import 'telaprenhez.dart';
import 'telaperfil.dart';
import 'loja.dart';
import 'tela_historico.dart';
import 'tela_baixas.dart';

class TelaVaca extends StatefulWidget {
  const TelaVaca({super.key});

  @override
  State<TelaVaca> createState() => _TelaVacaState();
}

class _TelaVacaState extends State<TelaVaca> {
  final _nomeController = TextEditingController();
  final _brincoController = TextEditingController();
  final _racaController = TextEditingController();
  final _dataNasciController = TextEditingController();
  final _partoController = TextEditingController();
  final _buscaController = TextEditingController();

  String? _statusSelecionado = "Vazia";
  String _busca = "";

  final maskFormatter = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

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

  void _excluirVaca(String id) async {
    await FirebaseFirestore.instance.collection('vacas').doc(id).delete();
  }

  void _adicionarVaca() async {
    try {
      String nome = _nomeController.text.trim();
      String brinco = _brincoController.text.trim();

      if (nome.isEmpty || brinco.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nome e Brinco são obrigatórios!")),
        );
        return;
      }

      final queryDuplicados = await FirebaseFirestore.instance
          .collection('vacas')
          .where('nome', isEqualTo: nome)
          .where('brinco', isEqualTo: brinco)
          .get();

      if (queryDuplicados.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Animal já cadastrado!"), backgroundColor: Colors.red),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('vacas').add({
        'nome': nome,
        'brinco': brinco,
        'dataNascimento': _dataNasciController.text,
        'status': _statusSelecionado ?? "Vazia",
        'raca': _racaController.text,
        'ultimoParto': _partoController.text,
        'dataCriacao': FieldValue.serverTimestamp(),
      });

      _nomeController.clear();
      _brincoController.clear();
      _racaController.clear();
      _dataNasciController.clear();
      _partoController.clear();

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }

  void _abrirFormulario() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Cadastrar Nova Vaca", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                TextField(controller: _nomeController, decoration: const InputDecoration(labelText: "Nome")),
                TextField(controller: _brincoController, decoration: const InputDecoration(labelText: "Brinco")),
                TextField(controller: _racaController, decoration: const InputDecoration(labelText: "Raça")),
                TextField(
                  controller: _dataNasciController,
                  inputFormatters: [maskFormatter],
                  decoration: const InputDecoration(labelText: "Data de Nascimento"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _partoController,
                  inputFormatters: [maskFormatter],
                  decoration: const InputDecoration(labelText: "Data do Último Parto"),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: _statusSelecionado,
                  decoration: const InputDecoration(labelText: "Status"),
                  items: ["Vazia", "Inseminar", "Prenhe", "Seca"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setModalState(() => _statusSelecionado = val),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: _adicionarVaca,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50)),
                  child: const Text("SALVAR VACA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meu Rebanho Leiteiro", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaPerfil())),
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
        stream: FirebaseFirestore.instance.collection('vacas').orderBy('dataCriacao', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Erro ao carregar dados"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final documentos = snapshot.data!.docs.where((doc) {
            final nome = (doc['nome'] ?? "").toString().toLowerCase();
            final brinco = (doc['brinco'] ?? "").toString();
            return nome.contains(_busca) || brinco.contains(_busca);
          }).toList();

          return ListView.builder(
            itemCount: documentos.length,
            itemBuilder: (context, index) {
              final doc = documentos[index];
              final vaca = doc.data() as Map<String, dynamic>;

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) => _excluirVaca(doc.id),
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.agriculture, color: Colors.white)),
                    title: Text(vaca['nome'] ?? 'Sem nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Brinco: ${vaca['brinco']} | Parto: ${vaca['ultimoParto'] ?? '--'}"),
                    trailing: Text(vaca['status'] ?? "", style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.green)),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormulario,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.green,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _botaoMenu(context, Icons.vaccines, "INSEMINAR", Colors.blue, const TelaInseminar()),
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