import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'telalogin.dart';

class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key});

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _propriedadeController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  String _tipoUsuario = "Produtor Rural";
  bool _modoEdicao = false;
  bool _carregando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _dataNascimentoController.dispose();
    _propriedadeController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  void _preencherCampos(Map<String, dynamic> dados) {
    _nomeController.text = dados['nome'] ?? '';
    _dataNascimentoController.text = dados['dataNascimento'] ?? '';
    _propriedadeController.text = dados['propriedade'] ?? '';
    _cidadeController.text = dados['cidade'] ?? '';
    _estadoController.text = dados['estado'] ?? '';
    _tipoUsuario = dados['tipoUsuario'] ?? 'Produtor Rural';
  }

  Future<void> _selecionarDataNascimento() async {
    if (!_modoEdicao) return;

    final dataSelecionada = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );

    if (dataSelecionada != null) {
      setState(() {
        _dataNascimentoController.text =
        "${dataSelecionada.day.toString().padLeft(2, '0')}/"
            "${dataSelecionada.month.toString().padLeft(2, '0')}/"
            "${dataSelecionada.year}";
      });
    }
  }

  Future<void> _salvarPerfil() async {
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
          .collection('usuarios')
          .doc(usuario.uid)
          .set({
        'uid': usuario.uid,
        'nome': _nomeController.text.trim(),
        'email': usuario.email ?? '',
        'dataNascimento': _dataNascimentoController.text.trim(),
        'propriedade': _propriedadeController.text.trim(),
        'cidade': _cidadeController.text.trim(),
        'estado': _estadoController.text.trim().toUpperCase(),
        'tipoUsuario': _tipoUsuario,
        'fotoUrl': '',
        'dataAtualizacao': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      setState(() {
        _modoEdicao = false;
      });

      _mostrarMensagem("Perfil atualizado com sucesso.", Colors.green);
    } catch (e) {
      _mostrarMensagem("Erro ao salvar perfil: $e", Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  Future<void> _sairDaConta() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const TelaLogin()),
          (route) => false,
    );
  }

  void _confirmarSaida() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Sair da conta"),
          content: const Text("Deseja realmente sair do aplicativo?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                _sairDaConta();
              },
              child: const Text(
                "Sair",
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

  String? _validarObrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return "Campo obrigatório";
    }

    return null;
  }

  InputDecoration _decoracaoCampo(String label, IconData icone) {
    return InputDecoration(
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
    );
  }

  Widget _campoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icone,
    bool obrigatorio = true,
    bool somenteLeitura = false,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        enabled: _modoEdicao && !somenteLeitura,
        readOnly: somenteLeitura,
        maxLength: maxLength,
        decoration: _decoracaoCampo(label, icone).copyWith(
          counterText: '',
        ),
        validator: obrigatorio ? _validarObrigatorio : null,
      ),
    );
  }

  Widget _campoEmail(String email) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        initialValue: email,
        enabled: false,
        decoration: _decoracaoCampo("E-mail", Icons.email),
      ),
    );
  }

  Widget _cabecalho(Map<String, dynamic> dados) {
    final nome = dados['nome'] ?? 'Usuário';
    final propriedade = dados['propriedade'] ?? 'Propriedade não informada';
    final tipoUsuario = dados['tipoUsuario'] ?? _tipoUsuario;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _decoracaoCard(),
      child: Column(
        children: [
          CircleAvatar(
            radius: 62,
            backgroundColor: Colors.green.shade100,
            child: const Icon(
              Icons.person,
              size: 82,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nome,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            propriedade,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tipoUsuario,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formularioPerfil(User usuario) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _decoracaoCard(),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _campoTexto(
              controller: _nomeController,
              label: "Nome completo",
              icone: Icons.person,
            ),
            GestureDetector(
              onTap: _selecionarDataNascimento,
              child: AbsorbPointer(
                child: _campoTexto(
                  controller: _dataNascimentoController,
                  label: "Data de nascimento",
                  icone: Icons.calendar_month,
                  somenteLeitura: true,
                ),
              ),
            ),
            _campoEmail(usuario.email ?? ''),
            _campoTexto(
              controller: _propriedadeController,
              label: "Propriedade",
              icone: Icons.home_work,
            ),
            _campoTexto(
              controller: _cidadeController,
              label: "Cidade",
              icone: Icons.location_city,
            ),
            _campoTexto(
              controller: _estadoController,
              label: "Estado",
              icone: Icons.map,
              maxLength: 2,
            ),
            DropdownButtonFormField<String>(
              value: _tipoUsuario,
              decoration: _decoracaoCampo("Tipo de usuário", Icons.badge),
              items: const [
                DropdownMenuItem(
                  value: "Produtor Rural",
                  child: Text("Produtor Rural"),
                ),
                DropdownMenuItem(
                  value: "Funcionário",
                  child: Text("Funcionário"),
                ),
                DropdownMenuItem(
                  value: "Técnico Veterinário",
                  child: Text("Técnico Veterinário"),
                ),
                DropdownMenuItem(
                  value: "Administrador",
                  child: Text("Administrador"),
                ),
              ],
              onChanged: _modoEdicao
                  ? (valor) {
                if (valor != null) {
                  setState(() {
                    _tipoUsuario = valor;
                  });
                }
              }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _botoesAcao() {
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
              onPressed: _carregando ? null : _salvarPerfil,
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
        const SizedBox(height: 12),
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
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              "SAIR DA CONTA",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: _confirmarSaida,
          ),
        ),
      ],
    );
  }

  BoxDecoration _decoracaoCard() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 6,
          offset: Offset(0, 3),
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
          child: Text("Nenhum usuário autenticado."),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEAF3E8),
      appBar: AppBar(
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Perfil do Usuário",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
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
            .collection('usuarios')
            .doc(usuario.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("Erro ao carregar os dados do perfil."),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(usuario.uid)
                        .set({
                      'uid': usuario.uid,
                      'nome': usuario.email ?? 'Usuário',
                      'email': usuario.email ?? '',
                      'dataNascimento': '',
                      'propriedade': '',
                      'cidade': '',
                      'estado': '',
                      'tipoUsuario': 'Produtor Rural',
                      'fotoUrl': '',
                      'dataCadastro': FieldValue.serverTimestamp(),
                      'dataAtualizacao': FieldValue.serverTimestamp(),
                    });

                    if (!mounted) return;

                    _mostrarMensagem(
                      "Perfil criado. Agora você pode editá-lo.",
                      Colors.green,
                    );
                  },
                  child: const Text(
                    "Criar perfil do usuário",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            );
          }

          final dados = snapshot.data!.data() as Map<String, dynamic>;

          if (!_modoEdicao) {
            _preencherCampos(dados);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _cabecalho(dados),
                const SizedBox(height: 20),
                _formularioPerfil(usuario),
                const SizedBox(height: 20),
                _botoesAcao(),
              ],
            ),
          );
        },
      ),
    );
  }
}