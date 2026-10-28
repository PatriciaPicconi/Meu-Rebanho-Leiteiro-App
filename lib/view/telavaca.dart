import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'telainseminar.dart';
import 'telatoque.dart';
import 'telaprenhez.dart';
import 'telaperfil.dart';
import 'tela_historico.dart';
import 'tela_baixas.dart';
import 'tela_detalhe_vaca.dart';

const String imagemVaca = 'assets/img/animal.png';
const String imagemTouro = 'assets/img/touro.png';

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
  bool _ehTouro = false;
  String _filtroTipo = "todos";

  final maskFormatter = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  String? get _usuarioId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _nomeController.dispose();
    _brincoController.dispose();
    _racaController.dispose();
    _dataNasciController.dispose();
    _partoController.dispose();
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
      onPressed: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => tela),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          imagem != null
              ? Image.asset(
                  imagem,
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                )
              : Icon(icone, color: corIcone, size: 22),
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

  Future<void> _excluirVaca(String id) async {
    try {
      await FirebaseFirestore.instance.collection('vacas').doc(id).delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vaca excluída com sucesso."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao excluir vaca: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _adicionarVaca() async {
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

    final nome = _nomeController.text.trim();
    final brinco = _brincoController.text.trim();

    if (nome.isEmpty || brinco.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nome e brinco são obrigatórios!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_ehTouro &&
        (_statusSelecionado == null || _statusSelecionado!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selecione o status reprodutivo da vaca."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final queryDuplicados = await FirebaseFirestore.instance
          .collection('vacas')
          .where('usuarioId', isEqualTo: usuarioId)
          .where('brinco', isEqualTo: brinco)
          .get();

      if (queryDuplicados.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Já existe um animal com o brinco $brinco na sua conta.",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('vacas').add({
        'usuarioId': usuarioId,
        'nome': nome,
        'brinco': brinco,
        'tipoAnimal': _ehTouro ? 'touro' : 'vaca',
        'dataNascimento': _dataNasciController.text.trim(),
        'status': _ehTouro ? null : _statusSelecionado,
        'raca': _racaController.text.trim(),
        'ultimoParto': _ehTouro ? '' : _partoController.text.trim(),
        'ultimaInseminacao': '',
        'ultimoExameToque': '',
        'dataCriacao': FieldValue.serverTimestamp(),
        'dataAtualizacao': FieldValue.serverTimestamp(),
      });

      _nomeController.clear();
      _brincoController.clear();
      _racaController.clear();
      _dataNasciController.clear();
      _partoController.clear();
      _statusSelecionado = "Vazia";
      _ehTouro = false;

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Animal cadastrado com sucesso."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao cadastrar animal: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmarExclusao(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir animal"),
        content: const Text(
          "Deseja realmente excluir este animal? Esta ação não poderá ser desfeita.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _excluirVaca(id);
            },
            child: const Text(
              "Excluir",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _abrirFormulario() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Cadastrar novo animal",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 15),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Este animal é um touro?"),
                    subtitle: const Text(
                      "Se não marcar, será cadastrado como vaca.",
                    ),
                    value: _ehTouro,
                    onChanged: (valor) {
                      setModalState(() {
                        _ehTouro = valor ?? false;
                        _statusSelecionado = _ehTouro ? null : "Vazia";
                        if (_ehTouro) _partoController.clear();
                      });
                    },
                  ),
                  TextField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: "Nome",
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                  TextField(
                    controller: _brincoController,
                    decoration: const InputDecoration(
                      labelText: "Brinco",
                      prefixIcon: Icon(Icons.confirmation_number),
                    ),
                  ),
                  TextField(
                    controller: _racaController,
                    decoration: const InputDecoration(
                      labelText: "Raça",
                      prefixIcon: Icon(Icons.pets),
                    ),
                  ),
                  TextField(
                    controller: _dataNasciController,
                    inputFormatters: [maskFormatter],
                    decoration: const InputDecoration(
                      labelText: "Data de Nascimento",
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  if (!_ehTouro)
                    TextField(
                      controller: _partoController,
                      inputFormatters: [maskFormatter],
                      decoration: const InputDecoration(
                        labelText: "Data do Último Parto",
                        prefixIcon: Icon(Icons.child_care),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  if (!_ehTouro)
                    DropdownButtonFormField<String>(
                      value: _statusSelecionado ?? "Vazia",
                      decoration: const InputDecoration(
                        labelText: "Status",
                        prefixIcon: Icon(Icons.info),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "Vazia",
                          child: Text("Vazia"),
                        ),
                        DropdownMenuItem(
                          value: "Inseminar",
                          child: Text("Inseminar"),
                        ),
                        DropdownMenuItem(
                          value: "Inseminada",
                          child: Text("Inseminada"),
                        ),
                        DropdownMenuItem(
                          value: "Prenhe",
                          child: Text("Prenhe"),
                        ),
                        DropdownMenuItem(
                          value: "Seca",
                          child: Text("Seca"),
                        ),
                      ],
                      onChanged: (valor) {
                        setModalState(() {
                          _statusSelecionado = valor;
                        });
                      },
                    ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: _adicionarVaca,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      "SALVAR ANIMAL",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _abrirDetalhes(String vacaId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaDetalheVaca(vacaId: vacaId),
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
        automaticallyImplyLeading: false,
        title: const Text("Animal", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(116),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Column(
              children: [
                TextField(
                  controller: _buscaController,
                  onChanged: (value) {
                    setState(() => _busca = value.toLowerCase().trim());
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
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filtroTipo,
                        decoration: InputDecoration(
                          labelText: "Filtrar animais",
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "todos",
                            child: Text("Todos os animais"),
                          ),
                          DropdownMenuItem(
                            value: "vaca",
                            child: Text("Apenas vacas"),
                          ),
                          DropdownMenuItem(
                            value: "touro",
                            child: Text("Apenas touros"),
                          ),
                        ],
                        onChanged: (valor) {
                          setState(() => _filtroTipo = valor ?? "todos");
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: "Limpar filtros",
                      icon: const Icon(
                        Icons.filter_alt_off,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _filtroTipo = "todos";
                          _busca = "";
                          _buscaController.clear();
                        });
                      },
                    ),
                  ],
                ),
              ],
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
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          final documentos = snapshot.data!.docs.where((doc) {
            final dados = doc.data() as Map<String, dynamic>;
            if (dados['baixado'] == true) return false;

            final nome = (dados['nome'] ?? "").toString().toLowerCase();
            final brinco = (dados['brinco'] ?? "").toString().toLowerCase();
            final tipo =
                (dados['tipoAnimal'] ?? 'vaca').toString().toLowerCase();

            final correspondeBusca =
                nome.contains(_busca) || brinco.contains(_busca);
            final correspondeTipo =
                _filtroTipo == "todos" || tipo == _filtroTipo;

            return correspondeBusca && correspondeTipo;
          }).toList();

          if (documentos.isEmpty) {
            return const Center(
              child: Text("Nenhum animal cadastrado para este usuário."),
            );
          }

          return ListView.builder(
            itemCount: documentos.length,
            itemBuilder: (context, index) {
              final doc = documentos[index];
              final vaca = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 6,
                ),
                child: ListTile(
                  onTap: () => _abrirDetalhes(doc.id),
                  leading: SizedBox(
                    width: 40,
                    height: 40,
                    child: Image.asset(
                      (vaca['tipoAnimal'] ?? 'vaca')
                                  .toString()
                                  .toLowerCase() ==
                              'touro'
                          ? imagemTouro
                          : imagemVaca,
                      fit: BoxFit.contain,
                    ),
                  ),
                  title: Text(
                    vaca['nome'] ?? 'Sem nome',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    (vaca['tipoAnimal'] ?? 'vaca').toString().toLowerCase() ==
                            'touro'
                        ? "Brinco: ${vaca['brinco'] ?? '--'}"
                        : "Brinco: ${vaca['brinco'] ?? '--'} | "
                            "Parto: ${vaca['ultimoParto'] ?? '--'}",
                  ),
                  trailing: Text(
                    (vaca['tipoAnimal'] ?? 'vaca').toString().toLowerCase() ==
                            'touro'
                        ? "Touro"
                        : (vaca['status'] ?? "").toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
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
              _botaoMenu(
                context,
                Icons.vaccines,
                "INSEMINAR",
                Colors.blue,
                const TelaInseminar(),
              ),
              _botaoMenu(
                context,
                null,
                "TOQUE",
                Colors.orange,
                const TelaToque(),
                imagem: 'assets/img/toque.png',
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
                Colors.purple,
                const TelaHistorico(),
              ),
              _botaoMenu(
                context,
                Icons.trending_down,
                "BAIXAS",
                Colors.black54,
                const TelaBaixas(),
              ),
              _botaoMenu(
                context,
                Icons.person,
                "PERFIL",
                Colors.deepOrangeAccent,
                const TelaPerfil(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}