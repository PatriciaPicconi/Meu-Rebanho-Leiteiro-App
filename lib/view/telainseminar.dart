import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'telavaca.dart';
import 'telatoque.dart';
import 'telaprenhez.dart';
import 'telaperfil.dart';
import 'tela_historico.dart';
import '../services/google_calendar_service.dart';

class TelaInseminar extends StatefulWidget {
  const TelaInseminar({super.key});

  @override
  State<TelaInseminar> createState() => _TelaInseminarState();
}

class _TelaInseminarState extends State<TelaInseminar> {
  final TextEditingController _buscaController =
  TextEditingController();

  String _filtroBusca = '';

  String? get _usuarioId =>
      FirebaseAuth.instance.currentUser?.uid;

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
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => tela,
          ),
        );
      },
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

  bool _animalCorrespondeBusca(
      Map<String, dynamic> dados,
      ) {
    if (_filtroBusca.trim().isEmpty) {
      return true;
    }

    final busca =
    _filtroBusca.trim().toLowerCase();

    final nome =
        dados['nome']?.toString().toLowerCase() ?? '';

    final brinco =
        dados['brinco']?.toString().toLowerCase() ?? '';

    return nome.contains(busca) ||
        brinco.contains(busca);
  }

  Future<void> _abrirFormulario(
      DocumentSnapshot vaca,
      ) async {
    final dados =
    vaca.data() as Map<String, dynamic>;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioInseminar(
          vacaId: vaca.id,
          dadosVaca: dados,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuarioId = _usuarioId;

    if (usuarioId == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Nenhum usuário autenticado.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
      const Color(0xFFEAF3E8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'Inseminar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _buscaController,
              onChanged: (valor) {
                setState(() {
                  _filtroBusca = valor;
                });
              },
              decoration: InputDecoration(
                hintText:
                'Buscar por nome ou brinco',
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.lightBlue,
                ),
                suffixIcon:
                _filtroBusca.isNotEmpty
                    ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                  ),
                  onPressed: () {
                    _buscaController.clear();

                    setState(() {
                      _filtroBusca = '';
                    });
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vacas')
                  .where(
                'usuarioId',
                isEqualTo: usuarioId,
              )
                  .snapshots(),
              builder: (
                  context,
                  snapshot,
                  ) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Erro ao carregar as vacas.',
                    ),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                    CircularProgressIndicator(
                      color: Colors.lightBlue,
                    ),
                  );
                }

                final documentos =
                    snapshot.data?.docs ?? [];

                final vacasFiltradas =
                documentos.where((doc) {
                  final dados =
                  doc.data()
                  as Map<String, dynamic>;

                  if (!_animalCorrespondeBusca(
                    dados,
                  )) {
                    return false;
                  }

                  final status =
                      dados['status']
                          ?.toString()
                          .toLowerCase() ??
                          '';

                  return status == 'vazia' ||
                      status == 'inseminar';
                }).toList();

                if (vacasFiltradas.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Nenhuma vaca disponível para inseminação.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  itemCount:
                  vacasFiltradas.length,
                  itemBuilder:
                      (context, index) {
                    final vaca =
                    vacasFiltradas[index];

                    final dados =
                    vaca.data()
                    as Map<String, dynamic>;

                    final nome =
                        dados['nome']
                            ?.toString() ??
                            'Sem nome';

                    final brinco =
                        dados['brinco']
                            ?.toString() ??
                            'Sem brinco';

                    return Card(
                      margin:
                      const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: ListTile(
                        leading:
                        const CircleAvatar(
                          backgroundColor:
                          Colors.lightBlue,
                          child: Icon(
                            Icons.agriculture,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          nome,
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Brinco: $brinco',
                        ),
                        trailing:
                        ElevatedButton(
                          style:
                          ElevatedButton.styleFrom(
                            backgroundColor:
                            Colors.lightBlue,
                          ),
                          onPressed: () =>
                              _abrirFormulario(
                                vaca,
                              ),
                          child:
                          const Text(
                            'Inseminar',
                            style:
                            TextStyle(
                              color:
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar:
      BottomAppBar(
        color: Colors.lightBlue,
        child: SingleChildScrollView(
          scrollDirection:
          Axis.horizontal,
          child: Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceEvenly,
            children: [
              _botaoMenu(
                context,
                Icons.agriculture,
                'VACAS',
                Colors.green,
                const TelaVaca(),
              ),
              _botaoMenu(
                context,
                Icons.front_hand,
                'TOQUE',
                Colors.orange,
                const TelaToque(),
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
                Icons.person,
                'PERFIL',
                Colors.white,
                const TelaPerfil(),
              ),
              _botaoMenu(
                context,
                Icons.history,
                'HISTÓRICO',
                Colors.white,
                const TelaHistorico(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FormularioInseminar
    extends StatefulWidget {
  final String vacaId;
  final Map<String, dynamic> dadosVaca;

  const FormularioInseminar({
    super.key,
    required this.vacaId,
    required this.dadosVaca,
  });

  @override
  State<FormularioInseminar> createState() =>
      _FormularioInseminarState();
}

class _FormularioInseminarState
    extends State<FormularioInseminar> {
  final _formKey =
  GlobalKey<FormState>();

  final _dataController =
  TextEditingController();

  final _touroController =
  TextEditingController();

  bool _salvando = false;

  @override
  void dispose() {
    _dataController.dispose();
    _touroController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (data != null) {
      setState(() {
        _dataController.text =
        '${data.day.toString().padLeft(2, '0')}/'
            '${data.month.toString().padLeft(2, '0')}/'
            '${data.year}';
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final usuarioId =
        FirebaseAuth.instance.currentUser?.uid;

    if (usuarioId == null) {
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      final dadosVaca = widget.dadosVaca;

      final nome =
          dadosVaca['nome']?.toString() ??
              'Vaca';

      final brinco =
          dadosVaca['brinco']?.toString() ??
              '';

      await FirebaseFirestore.instance
          .collection('inseminacoes')
          .add({
        'usuarioId': usuarioId,
        'vacaId': widget.vacaId,
        'nomeVaca': nome,
        'brinco': brinco,
        'dataInseminacao':
        _dataController.text.trim(),
        'touro': _touroController.text.trim(),
        'dataRegistro':
        FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('vacas')
          .doc(widget.vacaId)
          .update({
        'usuarioId': usuarioId,
        'status': 'Inseminar',
        'dataInseminacao':
        _dataController.text.trim(),
      });

      try {
        await GoogleCalendarService
            .criarLembreteVerificacaoPrenhez(
          nomeVaca: nome,
          brinco: brinco,
          dataInseminacao:
          _dataController.text.trim(),
          touro:
          _touroController.text.trim(),
        );
      } catch (_) {
        // O cadastro continua mesmo se o Google Agenda não abrir.
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Inseminação registrada com sucesso!',
          ),
          backgroundColor: Colors.lightBlue,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao registrar inseminação: $e',
          ),
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

  @override
  Widget build(BuildContext context) {
    final nome =
        widget.dadosVaca['nome']
            ?.toString() ??
            'Vaca';

    final brinco =
        widget.dadosVaca['brinco']
            ?.toString() ??
            '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'Registrar Inseminação',
        ),
      ),
      backgroundColor:
      const Color(0xFFEAF3E8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                nome,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Brinco: $brinco',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _dataController,
                readOnly: true,
                onTap: _selecionarData,
                decoration:
                InputDecoration(
                  labelText:
                  'Data da inseminação',
                  prefixIcon: const Icon(
                    Icons.calendar_month,
                    color: Colors.lightBlue,
                  ),
                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
                validator: (valor) {
                  if (valor == null ||
                      valor.isEmpty) {
                    return 'Informe a data.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller:
                _touroController,
                decoration:
                InputDecoration(
                  labelText:
                  'Touro / Sêmen utilizado',
                  prefixIcon: const Icon(
                    Icons.pets,
                    color: Colors.lightBlue,
                  ),
                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    Colors.lightBlue,
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                  onPressed:
                  _salvando
                      ? null
                      : _salvar,
                  icon: _salvando
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(
                    Icons.save,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'SALVAR INSEMINAÇÃO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                      FontWeight.bold,
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