import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class Formulario extends StatefulWidget {
  const Formulario({super.key});

  @override
  State<Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<Formulario> {
  final _nomeController = TextEditingController();
  final _brincoController = TextEditingController();
  final _racaController = TextEditingController();
  final _dataNasciController = TextEditingController();
  final _partoController = TextEditingController();

  String? _statusSelecionado = "Vazia";

  final maskFormatter = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  String? get _usuarioId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _adicionarVaca() async {
    final usuarioId = _usuarioId;

    if (usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuário não autenticado.")),
      );
      return;
    }

    try {
      final nome = _nomeController.text.trim();
      final brinco = _brincoController.text.trim();

      if (nome.isEmpty || brinco.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nome e brinco são obrigatórios!")),
        );
        return;
      }

      final queryDuplicados = await FirebaseFirestore.instance
          .collection('vacas')
          .where('usuarioId', isEqualTo: usuarioId)
          .where('brinco', isEqualTo: brinco)
          .get();

      if (queryDuplicados.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Já existe um animal com este brinco na sua conta."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('vacas').add({
        'usuarioId': usuarioId,
        'nome': nome,
        'brinco': brinco,
        'dataNascimento': _dataNasciController.text.trim(),
        'status': _statusSelecionado ?? "Vazia",
        'raca': _racaController.text.trim(),
        'ultimoParto': _partoController.text.trim(),
        'ultimaInseminacao': '',
        'ultimoExameToque': '',
        'pais': '',
        'producao_leite_mes': '',
        'observacoes': '',
        'partos_sucesso': 0,
        'partos_falhos': 0,
        'dataCriacao': FieldValue.serverTimestamp(),
        'dataAtualizacao': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Vaca cadastrada com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao cadastrar vaca: $e")),
      );
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _brincoController.dispose();
    _racaController.dispose();
    _dataNasciController.dispose();
    _partoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cadastrar Nova Vaca", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Center(
              child: Icon(Icons.agriculture, size: 70, color: Colors.green),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: "Nome do Animal",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _brincoController,
              decoration: const InputDecoration(
                labelText: "Número do Brinco",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _racaController,
              decoration: const InputDecoration(
                labelText: "Raça",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _dataNasciController,
              inputFormatters: [maskFormatter],
              decoration: const InputDecoration(
                labelText: "Data de Nascimento (DD/MM/AAAA)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _partoController,
              inputFormatters: [maskFormatter],
              decoration: const InputDecoration(
                labelText: "Data do Último Parto (DD/MM/AAAA)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _statusSelecionado,
              decoration: const InputDecoration(
                labelText: "Status Reprodutivo",
                border: OutlineInputBorder(),
              ),
              items: ["Vazia", "Inseminar", "Prenhe", "Seca"]
                  .map((status) => DropdownMenuItem(
                value: status,
                child: Text(status),
              ))
                  .toList(),
              onChanged: (valor) {
                setState(() {
                  _statusSelecionado = valor;
                });
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _adicionarVaca,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                "SALVAR REGISTRO",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}