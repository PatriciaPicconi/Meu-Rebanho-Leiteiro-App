import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/google_calendar_service.dart';

import 'telavaca.dart';
import 'telatoque.dart' as toque;
import 'telaprenhez.dart';
import 'menuprincipal.dart';
import 'tela_historico.dart';
import 'tela_baixas.dart';

const Color azulInseminacao = Colors.lightBlue;
const Color fundoInseminacao = Color(0xFFEAF3E8);
const String imagemAnimal = 'assets/img/animal.png';
const String imagemTouro = 'assets/img/touro.png';
const String imagemToque = 'assets/img/toque.png';
const String outroTouro = '__outro__';

bool _estaBaixado(Map<String, dynamic> dados) {
  final status = (dados['status'] ?? '')
      .toString()
      .trim()
      .toLowerCase();

  return dados['baixado'] == true ||
      status == 'baixado' ||
      status == 'baixada' ||
      status == 'baixa' ||
      status == 'baixado(a)';
}

bool _ehTouro(Map<String, dynamic> dados) {
  final tipo = (dados['tipoAnimal'] ?? '')
      .toString()
      .trim()
      .toLowerCase();

  return tipo.contains('touro');
}

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
    IconData? icone,
    String label,
    Color corIcone,
    Widget tela, {
    String? imagem,
  }) {
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
          if (imagem != null)
            Image.asset(
              imagem,
              width: 22,
              height: 22,
              fit: BoxFit.contain,
            )
          else
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

    final busca = _filtroBusca.trim().toLowerCase();
    final nome = (dados['nome'] ?? '').toString().toLowerCase();
    final brinco = (dados['brinco'] ?? '').toString().toLowerCase();

    return nome.contains(busca) || brinco.contains(busca);
  }

  Future<void> _abrirFormulario(
    DocumentSnapshot vaca,
  ) async {
    final dados = vaca.data() as Map<String, dynamic>;

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
          child: Text('Nenhum usuário autenticado.'),
        ),
      );
    }

  return Scaffold(
    backgroundColor: fundoInseminacao,
    appBar: AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: azulInseminacao,
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
              'Inseminar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
                hintText: 'Buscar por nome ou brinco',
                prefixIcon: const Icon(
                  Icons.search,
                  color: azulInseminacao,
                ),
                suffixIcon: _filtroBusca.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
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
                  borderRadius: BorderRadius.circular(12),
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
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Erro ao carregar os animais.'),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: azulInseminacao,
                    ),
                  );
                }

                final documentos = snapshot.data?.docs ?? [];

                final vacasFiltradas = documentos.where((doc) {
                  final dados =
                      doc.data() as Map<String, dynamic>;

                  if (_estaBaixado(dados)) return false;
                  if (_ehTouro(dados)) return false;

                  if (!_animalCorrespondeBusca(dados)) {
                    return false;
                  }

                  final status = (dados['status'] ?? '')
                      .toString()
                      .trim()
                      .toLowerCase();

                  return status == 'vazia' ||
                      status == 'seca' ||
                      status == 'inseminar';
                }).toList();

                if (vacasFiltradas.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Nenhum animal disponível para inseminação.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  itemCount: vacasFiltradas.length,
                  itemBuilder: (context, index) {
                    final vaca = vacasFiltradas[index];
                    final dados =
                        vaca.data() as Map<String, dynamic>;

                    final nome =
                        dados['nome']?.toString() ?? 'Sem nome';
                    final brinco =
                        dados['brinco']?.toString() ?? 'Sem brinco';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Image.asset(
                          imagemAnimal,
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                          color: azulInseminacao,
                          colorBlendMode: BlendMode.srcIn,
                        ),
                        title: Text(
                          nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text('Brinco: $brinco'),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: azulInseminacao,
                          ),
                          onPressed: () => _abrirFormulario(vaca),
                          child: const Text(
                            'Inseminar',
                            style: TextStyle(color: Colors.white),
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
      bottomNavigationBar: BottomAppBar(
        color: azulInseminacao,
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
                imagem: imagemAnimal,
              ),
              _botaoMenu(
                context,
                null,
                'TOQUE',
                Colors.orange,
                const toque.TelaToque(),
                imagem: imagemToque,
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
                Colors.purple,
                const TelaHistorico(),
              ),
              _botaoMenu(
                context,
                Icons.trending_down,
                'BAIXAS',
                Colors.brown,
                const TelaBaixas(),
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

class FormularioInseminar extends StatefulWidget {
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

class _FormularioInseminarState extends State<FormularioInseminar> {
  final _formKey = GlobalKey<FormState>();
  final _dataController = TextEditingController();
  final _outroTouroController = TextEditingController();

  String? _touroSelecionado;
  bool _salvando = false;

  @override
  void dispose() {
    _dataController.dispose();
    _outroTouroController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: azulInseminacao,
            ),
          ),
          child: child!,
        );
      },
    );

    if (data != null && mounted) {
      setState(() {
        _dataController.text =
            '${data.day.toString().padLeft(2, '0')}/'
            '${data.month.toString().padLeft(2, '0')}/'
            '${data.year}';
      });
    }
  }

  Future<bool> _googleCalendarAtivado(String usuarioId) async {
    final documento = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(usuarioId)
        .get();
    // Usuários existentes continuam com a integração ativada por padrão.
    return documento.data()?['usarGoogleCalendar'] != false;
  }

  Future<void> _perguntarAbrirGoogleCalendar({
    required String usuarioId,
    required String nomeVaca,
    required String brinco,
    required String dataInseminacao,
    required String touro,
  }) async {
    bool ativado;
    try {
      ativado = await _googleCalendarAtivado(usuarioId);
    } catch (_) {
      return;
    }
    if (!mounted || !ativado) return;

    final abrir = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Inseminação registrada'),
        content: const Text(
          'Deseja abrir o Google Calendar para criar um lembrete de '
          'verificação de prenhez? A data sugerida será 45 dias após '
          'a inseminação. Você poderá conferir e confirmar o evento no navegador.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Agora não'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.calendar_month),
            label: const Text('Abrir Google Calendar'),
          ),
        ],
      ),
    );

    if (abrir != true || !mounted) return;
    try {
      await GoogleCalendarService.criarLembreteVerificacaoPrenhez(
        nomeVaca: nomeVaca,
        brinco: brinco,
        dataInseminacao: dataInseminacao,
        touro: touro,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível abrir o Google Calendar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final usuarioId = FirebaseAuth.instance.currentUser?.uid;

    if (usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum usuário autenticado.'),
        ),
      );
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      final referenciaVaca = FirebaseFirestore.instance
          .collection('vacas')
          .doc(widget.vacaId);

      final documentoAtual = await referenciaVaca.get();

      if (!documentoAtual.exists) {
        throw Exception('O animal não foi encontrado.');
      }

      final dadosAtuais =
          documentoAtual.data() as Map<String, dynamic>;

      if (dadosAtuais['usuarioId'] != usuarioId) {
        throw Exception(
          'Você não tem permissão para alterar este animal.',
        );
      }

      if (_estaBaixado(dadosAtuais)) {
        throw Exception(
          'Este animal está registrado em baixas e não pode ser inseminado.',
        );
      }

      final nome =
          dadosAtuais['nome']?.toString() ?? 'Vaca';
      final brinco =
          dadosAtuais['brinco']?.toString() ?? '';

      String nomeTouro;
      String? touroIdRegistro;

      if (_touroSelecionado == outroTouro) {
        nomeTouro = _outroTouroController.text.trim();
      } else {
        touroIdRegistro = _touroSelecionado;
        final documentoTouro = await FirebaseFirestore.instance
            .collection('vacas')
            .doc(_touroSelecionado)
            .get();

        if (!documentoTouro.exists) {
          throw Exception(
            'O touro selecionado não foi encontrado.',
          );
        }

        final dadosTouro =
            documentoTouro.data() as Map<String, dynamic>;

        if (dadosTouro['usuarioId'] != usuarioId ||
            !_ehTouro(dadosTouro) ||
            _estaBaixado(dadosTouro)) {
          throw Exception(
            'O touro selecionado não está disponível.',
          );
        }

        nomeTouro = dadosTouro['nome']?.toString() ?? 'Touro';
        final brincoTouro =
            dadosTouro['brinco']?.toString() ?? '';

        if (brincoTouro.trim().isNotEmpty) {
          nomeTouro = '$nomeTouro (Brinco: $brincoTouro)';
        }
      }

      final dataInseminacao = _dataController.text.trim();

      // Registra o evento de inseminação.
      await FirebaseFirestore.instance
          .collection('inseminacoes')
          .add({
        'usuarioId': usuarioId,
        'vacaId': widget.vacaId,
        'nomeVaca': nome,
        'brinco': brinco,
        'dataInseminacao': dataInseminacao,
        'touro': nomeTouro,
        'touroId': touroIdRegistro,
        'touroExterno': _touroSelecionado == outroTouro,
        'dataRegistro': FieldValue.serverTimestamp(),
      });

      // Mantém a data no documento do animal para a tela Toque.
      await referenciaVaca.update({
        'status': 'Inseminada',
        'dataInseminacao': dataInseminacao,
        'ultimoTouroId': touroIdRegistro,
        'ultimoTouro': nomeTouro,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inseminação registrada com sucesso!'),
          backgroundColor: azulInseminacao,
        ),
      );

      await _perguntarAbrirGoogleCalendar(
        usuarioId: usuarioId,
        nomeVaca: nome,
        brinco: brinco,
        dataInseminacao: dataInseminacao,
        touro: nomeTouro,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao registrar inseminação: $e'),
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
        widget.dadosVaca['nome']?.toString() ?? 'Vaca';
    final brinco =
        widget.dadosVaca['brinco']?.toString() ?? '';
    final usuarioId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: azulInseminacao,
        foregroundColor: Colors.white,
        title: const Text('Registrar Inseminação'),
      ),
      backgroundColor: fundoInseminacao,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Image.asset(
                imagemAnimal,
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                color: azulInseminacao,
                colorBlendMode: BlendMode.srcIn,
              ),
              const SizedBox(height: 8),
              Text(
                nome,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: azulInseminacao,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Brinco: $brinco',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _dataController,
                readOnly: true,
                onTap: _selecionarData,
                decoration: InputDecoration(
                  labelText: 'Data da inseminação *',
                  hintText: 'DD/MM/AAAA',
                  prefixIcon: const Icon(
                    Icons.calendar_month,
                    color: azulInseminacao,
                  ),
                  suffixIcon: const Icon(
                    Icons.arrow_drop_down,
                    color: azulInseminacao,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Informe a data da inseminação.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: usuarioId == null
                    ? null
                    : FirebaseFirestore.instance
                        .collection('vacas')
                        .where(
                          'usuarioId',
                          isEqualTo: usuarioId,
                        )
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text(
                      'Não foi possível carregar os touros cadastrados.',
                    );
                  }

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        color: azulInseminacao,
                      ),
                    );
                  }

                  final documentos = snapshot.data?.docs ?? [];

                  final touros = documentos.where((doc) {
                    final dados =
                        doc.data() as Map<String, dynamic>;

                    return _ehTouro(dados) &&
                        !_estaBaixado(dados);
                  }).toList();

                  final opcoes = <DropdownMenuItem<String>>[
                    ...touros.map((doc) {
                      final dados =
                          doc.data() as Map<String, dynamic>;
                      final nomeTouro =
                          dados['nome']?.toString() ?? 'Touro';
                      final brincoTouro =
                          dados['brinco']?.toString() ?? '';

                      final rotulo = brincoTouro.trim().isEmpty
                          ? nomeTouro
                          : '$nomeTouro (Brinco: $brincoTouro)';

                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(
                          rotulo,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                    const DropdownMenuItem<String>(
                      value: outroTouro,
                      child: Text('Outro, digitar manualmente'),
                    ),
                  ];

                  final selecaoValida =
                      _touroSelecionado != null &&
                      opcoes.any(
                        (opcao) =>
                            opcao.value == _touroSelecionado,
                      );

                  return Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: selecaoValida
                            ? _touroSelecionado
                            : null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Touro / sêmen utilizado *',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              imagemTouro,
                              width: 22,
                              height: 22,
                              fit: BoxFit.contain,
                              color: azulInseminacao,
                              colorBlendMode: BlendMode.srcIn,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: opcoes,
                        onChanged: (valor) {
                          setState(() {
                            _touroSelecionado = valor;
                            if (valor != outroTouro) {
                              _outroTouroController.clear();
                            }
                          });
                        },
                        validator: (valor) {
                          if (valor == null || valor.isEmpty) {
                            return 'Selecione um touro ou escolha Outro.';
                          }
                          return null;
                        },
                      ),
                      if (_touroSelecionado == outroTouro) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _outroTouroController,
                          textCapitalization:
                              TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Nome do touro ou sêmen *',
                            hintText: 'Digite o nome ou identificação',
                            prefixIcon: const Icon(
                              Icons.edit,
                              color: azulInseminacao,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (valor) {
                            if (_touroSelecionado == outroTouro &&
                                (valor == null ||
                                    valor.trim().isEmpty)) {
                              return 'Digite o nome ou a identificação.';
                            }
                            return null;
                          },
                        ),
                      ],
                      if (touros.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Nenhum touro ativo cadastrado. Você pode escolher Outro.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azulInseminacao,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _salvando ? null : _salvar,
                  icon: _salvando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
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