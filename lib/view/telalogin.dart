import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'menuprincipal.dart';
import 'recuperar_senha.dart';
import 'telacadastrousuario.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _carregando = false;
  bool _mostrarSenha = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _carregando = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MenuPrincipal(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String mensagem = "Erro ao entrar no sistema.";

      if (e.code == 'user-not-found') {
        mensagem = "Usuário não encontrado.";
      } else if (e.code == 'wrong-password') {
        mensagem = "Senha incorreta.";
      } else if (e.code == 'invalid-email') {
        mensagem = "E-mail inválido.";
      } else if (e.code == 'invalid-credential') {
        mensagem = "E-mail ou senha inválidos.";
      } else if (e.code == 'too-many-requests') {
        mensagem = "Muitas tentativas. Aguarde um pouco e tente novamente.";
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
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

  String? _validarEmail(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return "Informe o e-mail";
    }

    if (!valor.contains("@")) {
      return "Informe um e-mail válido";
    }

    return null;
  }

  String? _validarSenha(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return "Informe a senha";
    }

    if (valor.length < 6) {
      return "A senha deve ter pelo menos 6 caracteres";
    }

    return null;
  }

  void _irParaCadastro() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TelaCadastroUsuario(),
      ),
    );
  }

  void _irParaRecuperarSenha() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecuperarSenha(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF3E8),
      appBar: AppBar(
        title: const Text(
          "Meu Rebanho Leiteiro",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
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
                    Icons.agriculture,
                    size: 90,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 10),

                  const Text(
                    "Acesso ao Sistema",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Entre para gerenciar os dados do seu rebanho.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),

                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _decoracaoCampo("E-mail", Icons.email),
                    validator: _validarEmail,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _senhaController,
                    obscureText: !_mostrarSenha,
                    decoration: _decoracaoCampo("Senha", Icons.lock).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _mostrarSenha
                              ? Icons.visibility_off
                              : Icons.visibility,
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

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _irParaRecuperarSenha,
                      child: const Text(
                        "Esqueci minha senha",
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

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
                      onPressed: _carregando ? null : _entrar,
                      child: _carregando
                          ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                          : const Text(
                        "ENTRAR",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: _irParaCadastro,
                    child: const Text(
                      "Ainda não tenho conta. Cadastrar",
                      style: TextStyle(
                        color: Colors.green,
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
}