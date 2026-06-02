import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/google_calendar_service.dart';

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
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _buscaController,
              onChanged: (value) {
                setState(() {
                  _filtro = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Pesquisar por nome ou brinco...",
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
            return const Center(child: Text("Erro ao carregar dados."));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final documentos = snapshot.data!.docs.where((doc) {
            final dados = doc.data() as Map<String, dynamic>;

            final nome = (dados['nome'] ?? '').toString().toLowerCase();
            final brinco = (dados['brinco'] ?? '').toString().toLowerCase();
            final status = (dados['status'] ?? '').toString();

            final correspondeBusca =
                nome.contains(_filtro) || brinco.contains(_filtro);

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

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.vaccines, color: Colors.white),
                  ),
                  title: Text(
                    vaca['nome'] ?? 'Sem nome',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Brinco: ${vaca['brinco'] ?? 'S/N'}"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FormularioInseminar(
                          vacaId: doc.id,
                          nomeVaca: vaca['nome']?.toString() ?? 'Sem nome',
                          brincoInicial: vaca['brinco']?.toString() ?? '',
                        ),
                      ),
                    );
                  },
                ),
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
              _botaoMenu(
                context,
                Icons.agriculture,
                "VACAS",
                Colors.greenAccent,
                const TelaVaca(),
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
                Icons.shopping_cart,
                "LOJA",
                Colors.yellowAccent,
                const Loja(),
              ),
              _botaoMenu(
                context,
                Icons.history,
                "HISTÓRICO",
                Colors.white,
                const TelaHistorico(),
              ),
              _botaoMenu(
                context,
                Icons.trending_down,
                "BAIXAS",
                Colors.black54,
                const TelaBaixas(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FormularioInseminar extends StatefulWidget {
  final String vacaId;
  final String nomeVaca;
  final String brincoInicial;

  const FormularioInseminar({
    super.key,
    required this.vacaId,
    required this.nomeVaca,
    this.brincoInicial = '',
  });

  @override
  State<FormularioInseminar> createState() => _FormularioInseminarState();
}

class _FormularioInseminarState extends State<FormularioInseminar> {
  final _brincoController = TextEditingController();
  final _dataCioController = TextEditingController();
  final _touroController = TextEditingController();

  bool _salvando = false;

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

  bool _dataValida(String data) {
    final partes = data.split('/');

    if (partes.length != 3) {
      return false;
    }

    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final ano = int.tryParse(partes[2]);

    if (dia == null || mes == null || ano == null) {
      return false;
    }

    if (dia < 1 || dia > 31 || mes < 1 || mes > 12 || ano < 2000) {
      return false;
    }

    return true;
  }

  Future<void> _perguntarSeDesejaCriarLembrete() async {
    final desejaCriar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Criar lembrete?"),
          content: const Text(
            "Deseja adicionar ao Google Agenda um lembrete para verificação de prenhez daqui a 45 dias?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Agora não"),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.calendar_month, color: Colors.white),
              label: const Text(
                "Adicionar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (desejaCriar == true) {
      await GoogleCalendarService.criarLembreteVerificacaoPrenhez(
        nomeVaca: widget.nomeVaca,
        brinco: _brincoController.text.trim(),
        dataInseminacao: _dataCioController.text.trim(),
        touro: _touroController.text.trim(),
      );
    }
  }

  Future<void> _salvar() async {
    final usuarioId = _usuarioId;

    if (usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Usuário não autenticado."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final brinco = _brincoController.text.trim();
    final dataInseminacao = _dataCioController.text.trim();
    final touro = _touroController.text.trim();

    if (brinco.isEmpty || dataInseminacao.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Informe o brinco e a data da inseminação."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_dataValida(dataInseminacao)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Informe a data no formato DD/MM/AAAA."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      await FirebaseFirestore.instance.collection('inseminacoes').add({
        'usuarioId': usuarioId,
        'vacaId': widget.vacaId,
        'nomeVaca': widget.nomeVaca,
        'brinco': brinco,
        'data': dataInseminacao,
        'touro': touro,
        'lembreteGoogleAgenda': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('vacas')
          .doc(widget.vacaId)
          .update({
        'status': 'Inseminada',
        'ultimaInseminacao': dataInseminacao,
        'dataAtualizacao': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Inseminação registrada com sucesso."),
          backgroundColor: Colors.green,
        ),
      );

      await _perguntarSeDesejaCriarLembrete();

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao registrar inseminação: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  InputDecoration _decoracaoCampo(String label, IconData icone) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icone),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF3E8),
      appBar: AppBar(
        title: const Text(
          "Registrar Inseminação",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.vaccines,
                color: Colors.blue,
                size: 70,
              ),
              const SizedBox(height: 10),
              Text(
                widget.nomeVaca,
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _brincoController,
                decoration: _decoracaoCampo(
                  "Brinco",
                  Icons.confirmation_number,
                ),
                readOnly: true,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _dataCioController,
                decoration: _decoracaoCampo(
                  "Data da inseminação - DD/MM/AAAA",
                  Icons.calendar_month,
                ),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _touroController,
                decoration: _decoracaoCampo(
                  "Touro ou sêmen utilizado",
                  Icons.pets,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _salvando ? null : _salvar,
                  icon: _salvando
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    "SALVAR INSEMINAÇÃO",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}