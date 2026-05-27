import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'menuprincipal.dart';

class TelaCadastroUsuario extends StatefulWidget {
  const TelaCadastroUsuario({super.key});

  @override
  State<TelaCadastroUsuario> createState() => _TelaCadastroUsuarioState();
}

class _TelaCadastroUsuarioState extends State<TelaCadastroUsuario> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _propriedadeController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  String _tipoUsuario = "Produtor Rural";
  bool _carregando = false;
  bool _mostrarSenha = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _dataNascimentoController.dispose();
    _propriedadeController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarDataNascimento() async {
    final DateTime? dataSelecionada = await showDatePicker(
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

  Future<void> _cadastrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _carregando = true;
    });

    try {
      final credencial = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );

      final uid = credencial.user!.uid;

      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'uid': uid,
        'nome': _nomeController.text.trim(),
        'email': _emailController.text.trim(),
        'dataNascimento': _dataNascimentoController.text.trim(),
        'propriedade': _propriedadeController.text.trim(),
        'cidade': _cidadeController.text.trim(),
        'estado': _estadoController.text.trim().toUpperCase(),
        'tipoUsuario': _tipoUsuario,
        'fotoUrl': '',
        'dataCadastro': FieldValue.serverTimestamp(),
        'dataAtualizacao': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Usuário cadastrado com sucesso!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MenuPrincipal()),
      );
    } on FirebaseAuthException catch (e) {
      String mensagem = "Erro ao cadastrar usuário.";

      if (e.code == 'email-already-in-use') {
        mensagem = "Este e-mail já está cadastrado.";
      } else if (e.code == 'invalid-email') {
        mensagem = "Informe um e-mail válido.";
      } else if (e.code == 'weak-password') {
        mensagem = "A senha deve ter pelo menos 6 caracteres.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro inesperado: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  InputDecoration _decoracaoCampo(String label, IconData icone) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icone, color: Colors.green),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.green, width: 2),
      ),
    );
  }

  String? _validarCampoObrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return "Campo obrigatório";
    }
    return null;
  }

  String? _validarEmail(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return "Campo obrigatório";
    }

    if (!valor.contains("@")) {
      return "Informe um e-mail válido";
    }

    return null;
  }

  String? _validarSenha(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return "Campo obrigatório";
    }

    if (valor.length < 6) {
      return "A senha deve ter pelo menos 6 caracteres";
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF3E8),
      appBar: AppBar(
        title: const Text(
          "Cadastro de Usuário",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
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
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(
                  Icons.account_circle,
                  size: 90,
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Criar Perfil do Produtor",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Preencha os dados para gerenciar o rebanho leiteiro.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _nomeController,
                  decoration: _decoracaoCampo("Nome completo", Icons.person),
                  validator: _validarCampoObrigatorio,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decoracaoCampo("E-mail", Icons.email),
                  validator: _validarEmail,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _senhaController,
                  obscureText: !_mostrarSenha,
                  decoration: _decoracaoCampo("Senha", Icons.lock).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _mostrarSenha ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _mostrarSenha = !_mostrarSenha;
                        });
                      },
                    ),
                  ),
                  validator: _validarSenha,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _dataNascimentoController,
                  readOnly: true,
                  onTap: _selecionarDataNascimento,
                  decoration: _decoracaoCampo(
                    "Data de nascimento",
                    Icons.calendar_month,
                  ),
                  validator: _validarCampoObrigatorio,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _propriedadeController,
                  decoration: _decoracaoCampo(
                    "Nome da propriedade / sítio / fazenda",
                    Icons.home_work,
                  ),
                  validator: _validarCampoObrigatorio,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _cidadeController,
                  decoration: _decoracaoCampo("Cidade", Icons.location_city),
                  validator: _validarCampoObrigatorio,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _estadoController,
                  maxLength: 2,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _decoracaoCampo("Estado", Icons.map).copyWith(
                    counterText: "",
                  ),
                  validator: _validarCampoObrigatorio,
                ),
                const SizedBox(height: 14),

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
                  onChanged: (valor) {
                    if (valor != null) {
                      setState(() {
                        _tipoUsuario = valor;
                      });
                    }
                  },
                ),
                const SizedBox(height: 26),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _carregando ? null : _cadastrarUsuario,
                    child: _carregando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "CADASTRAR",
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
      ),
    );
  }
}