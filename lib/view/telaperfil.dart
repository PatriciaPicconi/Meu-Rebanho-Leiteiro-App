import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'telalogin.dart';
import 'telavaca.dart';
import 'telainseminar.dart';
import 'telatoque.dart';
import 'telaprenhez.dart';
import 'loja.dart';
import 'tela_historico.dart';

class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key});

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _emEdicao = false;

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _aniversarioController = TextEditingController();
  final TextEditingController _propriedadeController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _aniversarioController.dispose();
    _propriedadeController.dispose();
    super.dispose();
  }

  void _fazerLogout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => TelaLogin()),
            (route) => false,
      );
    }
  }

  void _deletarConta() async {
    try {
      User? usuarioAtual = _auth.currentUser;
      if (usuarioAtual != null) {
        await _firestore.collection('usuarios').doc(usuarioAtual.uid).delete();
        await usuarioAtual.delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sua conta foi apagada permanentemente.')),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => TelaLogin()),
                (route) => false,
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao apagar conta: Reautenticação necessária.')),
      );
    }
  }

  Future<void> _selecionarData(BuildContext context) async {
    if (!_emEdicao) return;

    final DateTime? selecionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.brown,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selecionada != null) {
      setState(() {
        _aniversarioController.text =
        "${selecionada.day.toString().padLeft(2, '0')}/${selecionada.month.toString().padLeft(2, '0')}/${selecionada.year}";
      });
    }
  }

  void _mostrarAlertaConfirmacao({
    required String titulo,
    required String mensagem,
    required VoidCallback onConfirmar,
    bool ePerigoso = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirmar();
            },
            child: Text(
              "Confirmar",
              style: TextStyle(color: ePerigoso ? Colors.red : Colors.brown, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

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
    User? usuarioLogado = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Meu Perfil",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.brown,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_emEdicao ? Icons.check : Icons.edit, color: Colors.white),
            onPressed: () async {
              if (_emEdicao && usuarioLogado != null) {
                await _firestore.collection('usuarios').doc(usuarioLogado.uid).update({
                  'nome': _nomeController.text,
                  'aniversario': _aniversarioController.text,
                  'propriedade': _propriedadeController.text,
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perfil updated com sucesso!')),
                  );
                }
              }
              setState(() {
                _emEdicao = !_emEdicao;
              });
            },
          ),
        ],
      ),
      body: usuarioLogado == null
          ? const Center(child: Text("Nenhum usuário autenticado."))
          : StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('usuarios').doc(usuarioLogado.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Erro ao carregar dados: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.brown));
          }

          Map<String, dynamic> dados = {};
          if (snapshot.hasData && snapshot.data!.exists) {
            dados = snapshot.data!.data() as Map<String, dynamic>;
          } else {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  "Documento do usuário não foi encontrado no Firestore.",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!_emEdicao) {
            _nomeController.text = dados['nome'] ?? '';
            _aniversarioController.text = dados['aniversario'] ?? '';
            _propriedadeController.text = dados['propriedade'] ?? '';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.brown.shade100,
                        backgroundImage: NetworkImage(
                          dados['foto_url'] ?? 'https://via.placeholder.com/150',
                        ),
                      ),
                      if (_emEdicao)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Colors.brown,
                            radius: 20,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                              onPressed: () {},
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _construirCampoCadastral(
                  rotulo: "Nome do Produtor",
                  controlador: _nomeController,
                  habilitado: _emEdicao,
                  icone: Icons.person,
                ),
                _construirCampoCadastral(
                  rotulo: "E-mail de Cadastro",
                  controlador: TextEditingController(text: usuarioLogado.email),
                  habilitado: false,
                  icone: Icons.email,
                ),
                GestureDetector(
                  onTap: () => _selecionarData(context),
                  child: AbsorbPointer(
                    absorbing: _emEdicao,
                    child: _construirCampoCadastral(
                      rotulo: "Data de Aniversário",
                      controlador: _aniversarioController,
                      habilitado: false,
                      icone: Icons.cake,
                    ),
                  ),
                ),
                _construirCampoCadastral(
                  rotulo: "Nome da Propriedade / Sítio / Fazenda",
                  controlador: _propriedadeController,
                  habilitado: _emEdicao,
                  icone: Icons.gite,
                ),
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.brown),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.logout, color: Colors.brown),
                    label: const Text("SAIR DA CONTA", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
                    onPressed: () => _mostrarAlertaConfirmacao(
                      titulo: "Sair do Aplicativo",
                      mensagem: "Tem certeza que deseja encerrar a sessão?",
                      onConfirmar: _fazerLogout,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text("APAGAR MEU PERFIL DEFINITIVAMENTE", style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _mostrarAlertaConfirmacao(
                      titulo: "EXCLUIR CONTA?",
                      mensagem: "Atenção! Esta ação é irreversível. Deseja continuar?",
                      ePerigoso: true,
                      onConfirmar: _deletarConta,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.brown,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _botaoMenu(context, Icons.agriculture, "VACAS", Colors.greenAccent, const TelaVaca()),
              _botaoMenu(context, Icons.vaccines, "INSEMINAR", Colors.blueAccent, const TelaInseminar()),
              _botaoMenu(context, Icons.front_hand, "TOQUE", Colors.orange, const TelaToque()),
              _botaoMenu(context, Icons.favorite, "PRENHEZ", Colors.redAccent, const TelaPrenhez()),
              _botaoMenu(context, Icons.shopping_cart, "LOJA", Colors.yellowAccent, const Loja()),
              _botaoMenu(context, Icons.history, "HISTÓRICO", Colors.white, const TelaHistorico()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirCampoCadastral({
    required String rotulo,
    required TextEditingController controlador,
    required bool habilitado,
    required IconData icone,
    TextInputType teclado = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextField(
        controller: controlador,
        enabled: habilitado,
        keyboardType: teclado,
        style: TextStyle(
          color: habilitado ? Colors.black : Colors.black54,
          fontWeight: habilitado ? FontWeight.normal : FontWeight.bold,
        ),
        decoration: InputDecoration(
          labelText: rotulo,
          labelStyle: const TextStyle(color: Colors.brown),
          prefixIcon: Icon(icone, color: Colors.brown),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.brown, width: 2),
          ),
        ),
      ),
    );
  }
}