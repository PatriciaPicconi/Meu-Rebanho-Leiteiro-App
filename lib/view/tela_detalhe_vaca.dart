import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class TelaDetalheVaca extends StatefulWidget {
  final String vacaId;

  const TelaDetalheVaca({
    super.key,
    required this.vacaId,
  });

  @override
  State<TelaDetalheVaca> createState() => _TelaDetalheVacaState();
}

class _TelaDetalheVacaState extends State<TelaDetalheVaca> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _brincoController = TextEditingController();
  final _racaController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _ultimoPartoController = TextEditingController();

  bool _modoEdicao = false;
  bool _carregando = false;
  String _statusSelecionado = "Vazia";

  final maskFormatter = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void dispose() {
    _nomeController.dispose();
    _brincoController.dispose();
    _racaController.dispose();
    _dataNascimentoController.dispose();
    _ultimoPartoController.dispose();
    super.dispose();
  }

  void _preencherCampos(Map<String, dynamic> dados) {
    _nomeController.text = dados['nome'] ?? '';
    _brincoController.text = dados['brinco'] ?? '';
    _racaController.text = dados['raca'] ?? '';
    _dataNascimentoController.text = dados['dataNascimento'] ?? '';
    _ultimoPartoController.text = dados['ultimoParto'] ?? '';
    _statusSelecionado = dados['status'] ?? 'Vazia';
  }

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;

    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      _mostrarMensagem("Usuário não autenticado.", Colors.red);
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('vacas')
          .doc(widget.vacaId)
          .update({
        'usuarioId': usuario.uid,
        'nome': _nomeController.text.trim(),
        'brinco': _brincoController.text.trim(),
        'raca': _racaController.text.trim(),
        'dataNascimento': _dataNascimentoController.text.trim(),
        'ultimoParto': _ultimoPartoController.text.trim(),
        'status': _statusSelecionado,
        'dataAtualizacao': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _modoEdicao = false;
      });

      _mostrarMensagem("Informações atualizadas com sucesso.", Colors.green);
    } catch (e) {
      _mostrarMensagem("Erro ao atualizar: $e", Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  Future<void> _excluirVaca() async {
    try {
      await FirebaseFirestore.instance
          .collection('vacas')
          .doc(widget.vacaId)
          .delete();

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vaca excluída com sucesso."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _mostrarMensagem("Erro ao excluir: $e", Colors.red);
    }
  }

  void _confirmarExclusao() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Excluir vaca"),
          content: const Text(
            "Deseja realmente excluir esta vaca? Este botão foi criado para o caso de um registro em duplicidade, ao confirmar a exclusão, esse animal não aparecerá em baixas. Esta ação não poderá ser desfeita.",
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
                _excluirVaca();
              },
              child: const Text(
                "Excluir",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _mostrarMensagem(String mensagem, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: cor,
      ),
    );
  }

  Widget _campoTexto({
    required String label,
    required TextEditingController controller,
    required IconData icone,
    bool obrigatorio = false,
    TextInputType teclado = TextInputType.text,
    List<dynamic>? formatadores,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        enabled: _modoEdicao,
        keyboardType: teclado,
        inputFormatters: formatadores?.cast(),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icone, color: Colors.green),
          filled: !_modoEdicao,
          fillColor: _modoEdicao ? Colors.white : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.green, width: 2),
          ),
        ),
        validator: (valor) {
          if (obrigatorio && (valor == null || valor.trim().isEmpty)) {
            return "Campo obrigatório";
          }
          return null;
        },
      ),
    );
  }

  Widget _linhaInformacao(String titulo, String valor, IconData icone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icone, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              valor.isEmpty ? "Não informado" : valor,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cabecalho(Map<String, dynamic> dados) {
    return Column(
      children: [
        const SizedBox(height: 10),
        CircleAvatar(
          radius: 62,
          backgroundColor: Colors.green.shade100,
          child: const Icon(
            Icons.agriculture,
            size: 80,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            _mostrarMensagem(
              "Foto da vaca poderá ser implementada futuramente.",
              Colors.green,
            );
          },
          icon: const Icon(Icons.camera_alt, size: 18),
          label: const Text("Mudar foto"),
        ),
        const SizedBox(height: 12),
        Text(
          dados['nome'] ?? "Vaca sem nome",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        Text(
          "Brinco: ${dados['brinco'] ?? 'Não informado'}",
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 10),
        Chip(
          backgroundColor: Colors.green.shade100,
          label: Text(
            dados['status'] ?? "Sem status",
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _visualizacao(Map<String, dynamic> dados) {
    return Column(
      children: [
        _linhaInformacao(
          "Nome",
          dados['nome'] ?? '',
          Icons.badge,
        ),
        _linhaInformacao(
          "Brinco",
          dados['brinco'] ?? '',
          Icons.confirmation_number,
        ),
        _linhaInformacao(
          "Raça",
          dados['raca'] ?? '',
          Icons.pets,
        ),
        _linhaInformacao(
          "Data de nascimento",
          dados['dataNascimento'] ?? '',
          Icons.calendar_month,
        ),
        _linhaInformacao(
          "Status",
          dados['status'] ?? '',
          Icons.info,
        ),
        _linhaInformacao(
          "Último parto",
          dados['ultimoParto'] ?? '',
          Icons.child_care,
        ),
        if ((dados['ultimaInseminacao'] ?? '').toString().isNotEmpty)
          _linhaInformacao(
            "Última inseminação",
            dados['ultimaInseminacao'] ?? '',
            Icons.vaccines,
          ),
        if ((dados['ultimoExameToque'] ?? '').toString().isNotEmpty)
          _linhaInformacao(
            "Último toque",
            dados['ultimoExameToque'] ?? '',
            Icons.front_hand,
          ),
      ],
    );
  }

  Widget _formularioEdicao() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _campoTexto(
            label: "Nome",
            controller: _nomeController,
            icone: Icons.badge,
            obrigatorio: true,
          ),
          _campoTexto(
            label: "Brinco",
            controller: _brincoController,
            icone: Icons.confirmation_number,
            obrigatorio: true,
          ),
          _campoTexto(
            label: "Raça",
            controller: _racaController,
            icone: Icons.pets,
          ),
          _campoTexto(
            label: "Data de nascimento",
            controller: _dataNascimentoController,
            icone: Icons.calendar_month,
            teclado: TextInputType.number,
            formatadores: [maskFormatter],
          ),
          _campoTexto(
            label: "Último parto",
            controller: _ultimoPartoController,
            icone: Icons.child_care,
            teclado: TextInputType.number,
            formatadores: [maskFormatter],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: DropdownButtonFormField<String>(
              value: _statusSelecionado,
              decoration: InputDecoration(
                labelText: "Status",
                prefixIcon: const Icon(Icons.info, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: "Vazia", child: Text("Vazia")),
                DropdownMenuItem(value: "Inseminar", child: Text("Inseminar")),
                DropdownMenuItem(value: "Inseminada", child: Text("Inseminada")),
                DropdownMenuItem(value: "Prenhe", child: Text("Prenhe")),
                DropdownMenuItem(value: "Seca", child: Text("Seca")),
              ],
              onChanged: _modoEdicao
                  ? (valor) {
                if (valor != null) {
                  setState(() {
                    _statusSelecionado = valor;
                  });
                }
              }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _botoes() {
    return Column(
      children: [
        if (_modoEdicao)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _carregando ? null : _salvarAlteracoes,
              icon: _carregando
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
                "SALVAR ALTERAÇÕES",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _confirmarExclusao,
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text(
              "EXCLUIR VACA",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return const Scaffold(
        body: Center(
          child: Text("Usuário não autenticado."),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEAF3E8),
      appBar: AppBar(
        title: const Text(
          "Perfil da Vaca",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _modoEdicao ? Icons.close : Icons.edit,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _modoEdicao = !_modoEdicao;
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vacas')
            .doc(widget.vacaId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("Erro ao carregar os dados da vaca."),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("Vaca não encontrada."),
            );
          }

          final dados = snapshot.data!.data() as Map<String, dynamic>;

          if (dados['usuarioId'] != usuario.uid) {
            return const Center(
              child: Text("Você não tem permissão para visualizar esta vaca."),
            );
          }

          if (!_modoEdicao) {
            _preencherCampos(dados);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
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
                      _cabecalho(dados),
                      const Divider(height: 35),
                      _modoEdicao ? _formularioEdicao() : _visualizacao(dados),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _botoes(),
              ],
            ),
          );
        },
      ),
    );
  }
}