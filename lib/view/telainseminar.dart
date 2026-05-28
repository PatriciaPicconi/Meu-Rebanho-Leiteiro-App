import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        title: const Text(
          "Vacas para Inseminar",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
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
                  _filtro = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Pesquisar...",
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
            return const Center(child: Text("Erro ao carregar."));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final documentos = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final nome = (data['nome'] ?? '').toString().toLowerCase();
            final brinco = (data['brinco'] ?? '').toString().toLowerCase();
            final status = (data['status'] ?? '').toString();

            final correspondeBusca = nome.contains(_filtro) || brinco.contains(_filtro);
            final podeInseminar = status == 'Vazia' || status == 'Inseminar';

            return correspondeBusca && podeInseminar;
          }).toList();

          if (documentos.isEmpty) {
            return const Center(
              child: Text("Nenhuma vaca disponível para inseminação."),
            );
          }

          return ListView.builder(
            itemCount: documentos.length,
            itemBuilder: (context, index) {
              final doc = documentos[index];
              final vaca = doc.data() as Map<String, dynamic>;

              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.vaccines, color: Colors.white),
                ),
                title: Text(
                  vaca['nome'] ?? 'Sem nome',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Brinco: ${vaca['brinco'] ?? 'S/N'}"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FormularioInseminar(
                        vacaId: doc.id,
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
  final String vacaId;
  final String brincoInicial;

  const FormularioInseminar({
    super.key,
    required this.vacaId,
    this.brincoInicial = "",
  });

  @override
  State<FormularioInseminar> createState() => _FormularioInseminarState();
}

class _FormularioInseminarState extends State<FormularioInseminar> {
  final _brincoController = TextEditingController();
  final _dataCioController = TextEditingController();
  final _touroController = TextEditingController();

  String? get _usuarioId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _brincoController.text = widget.brincoInicial;
  }

  @override
  void dispose() {
    _brincoController.dispose();
    _dataCioController.dispose();
    _touroController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final usuarioId = _usuarioId;

    if (usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuário não autenticado.")),
      );
      return;
    }

    if (_brincoController.text.trim().isEmpty || _dataCioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Informe o brinco e a data da inseminação.")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('inseminacoes').add({
      'usuarioId': usuarioId,
      'vacaId': widget.vacaId,
      'brinco': _brincoController.text.trim(),
      'data': _dataCioController.text.trim(),
      'touro': _touroController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('vacas').doc(widget.vacaId).update({
      'status': 'Inseminada',
      'ultimaInseminacao': _dataCioController.text.trim(),
      'dataAtualizacao': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Inseminação registrada com sucesso."),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrar Inseminação"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _brincoController,
              decoration: const InputDecoration(labelText: "Brinco"),
              readOnly: true,
            ),
            TextField(
              controller: _dataCioController,
              decoration: const InputDecoration(labelText: "Data"),
            ),
            TextField(
              controller: _touroController,
              decoration: const InputDecoration(labelText: "Touro"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _salvar,
              child: const Text("SALVAR"),
            ),
          ],
        ),
      ),
    );
  }
}