import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'menuprincipal.dart';
import 'termos_uso.dart';
import 'politica_privacidade.dart';

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

  // Controle da leitura dos documentos
  bool _leuTermos = false;
  bool _leuPolitica = false;
  bool _aceitouTermos = false;

  // Versões dos documentos
  static const String _versaoTermos = '1.0';
  static const String _versaoPolitica = '1.0';

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

  // Abre os Termos de Uso
  Future<void> _abrirTermos() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const TermosUso(),
      ),
    );

    if (resultado == true && mounted) {
      setState(() {
        _leuTermos = true;
      });
    }
  }

  // Abre a Política de Privacidade
  Future<void> _abrirPolitica() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const PoliticaPrivacidade(),
      ),
    );

    if (resultado == true && mounted) {
      setState(() {
        _leuPolitica = true;
      });
    }
  }

  Future<void> _cadastrarUsuario() async {
    // Primeiro valida os campos do cadastro
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Depois verifica os documentos
    if (!_leuTermos || !_leuPolitica || !_aceitouTermos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Leia os Termos de Uso e a Política de Privacidade e marque a concordância para continuar.',
          ),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      // Cria a conta no Firebase Authentication
      final credencial =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );

      final uid = credencial.user!.uid;

      // Salva os dados do usuário no Firestore
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

        // Registro do aceite dos documentos
        'aceiteTermos': true,
        'versaoTermosAceita': _versaoTermos,
        'versaoPoliticaCiente': _versaoPolitica,
        'dataAceiteTermos': FieldValue.serverTimestamp(),

        // Datas do cadastro
        'dataCadastro': FieldValue.serverTimestamp(),
        'dataAtualizacao': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Usuário cadastrado com sucesso!",
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MenuPrincipal(),
        ),
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
          content: Text(
            "Erro inesperado: $e",
          ),
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

  InputDecoration _decoracaoCampo(
      String label,
      IconData icone,
      ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icone,
        color: Colors.green,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.green,
          width: 2,
        ),
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
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
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
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 24),

                // NOME
                TextFormField(
                  controller: _nomeController,
                  decoration: _decoracaoCampo(
                    "Nome completo",
                    Icons.person,
                  ),
                  validator: _validarCampoObrigatorio,
                ),

                const SizedBox(height: 14),

                // E-MAIL
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decoracaoCampo(
                    "E-mail",
                    Icons.email,
                  ),
                  validator: _validarEmail,
                ),

                const SizedBox(height: 14),

                // SENHA
                TextFormField(
                  controller: _senhaController,
                  obscureText: !_mostrarSenha,

                  decoration: _decoracaoCampo(
                    "Senha",
                    Icons.lock,
                  ).copyWith(
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

                const SizedBox(height: 14),

                // DATA DE NASCIMENTO
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

                // PROPRIEDADE
                TextFormField(
                  controller: _propriedadeController,

                  decoration: _decoracaoCampo(
                    "Nome da propriedade / sítio / fazenda",
                    Icons.home_work,
                  ),

                  validator: _validarCampoObrigatorio,
                ),

                const SizedBox(height: 14),

                // CIDADE
                TextFormField(
                  controller: _cidadeController,

                  decoration: _decoracaoCampo(
                    "Cidade",
                    Icons.location_city,
                  ),

                  validator: _validarCampoObrigatorio,
                ),

                const SizedBox(height: 14),

                // ESTADO
                TextFormField(
                  controller: _estadoController,
                  maxLength: 2,
                  textCapitalization: TextCapitalization.characters,

                  decoration: _decoracaoCampo(
                    "Estado",
                    Icons.map,
                  ).copyWith(
                    counterText: "",
                  ),

                  validator: _validarCampoObrigatorio,
                ),

                const SizedBox(height: 14),

                // TIPO DE USUÁRIO
                DropdownButtonFormField<String>(
                  value: _tipoUsuario,

                  decoration: _decoracaoCampo(
                    "Tipo de usuário",
                    Icons.badge,
                  ),

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

                const SizedBox(height: 16),

                // ==========================================================
                // TERMOS E POLÍTICA
                // ==========================================================

                Container(
                  padding: const EdgeInsets.all(12),

                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.shade100,
                    ),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        "Antes de criar sua conta",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        "Leia os Termos de Uso e a Política de Privacidade antes de concluir o cadastro.",
                        style: TextStyle(
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // TERMOS DE USO
                      ListTile(
                        contentPadding: EdgeInsets.zero,

                        leading: Icon(
                          _leuTermos
                              ? Icons.check_circle
                              : Icons.description_outlined,
                          color: _leuTermos
                              ? Colors.green
                              : Colors.purple,
                        ),

                        title: const Text(
                          "Termos de Uso",
                        ),

                        subtitle: Text(
                          _leuTermos
                              ? "Leitura concluída"
                              : "É necessário ler",
                          style: TextStyle(
                            color: _leuTermos
                                ? Colors.green
                                : Colors.black54,
                          ),
                        ),

                        trailing: TextButton(
                          onPressed: _abrirTermos,
                          child: Text(
                            _leuTermos
                                ? "Ler novamente"
                                : "Ler",
                          ),
                        ),
                      ),

                      // POLÍTICA DE PRIVACIDADE
                      ListTile(
                        contentPadding: EdgeInsets.zero,

                        leading: Icon(
                          _leuPolitica
                              ? Icons.check_circle
                              : Icons.privacy_tip_outlined,
                          color: _leuPolitica
                              ? Colors.green
                              : Colors.purple,
                        ),

                        title: const Text(
                          "Política de Privacidade",
                        ),

                        subtitle: Text(
                          _leuPolitica
                              ? "Leitura concluída"
                              : "É necessário ler",
                          style: TextStyle(
                            color: _leuPolitica
                                ? Colors.green
                                : Colors.black54,
                          ),
                        ),

                        trailing: TextButton(
                          onPressed: _abrirPolitica,
                          child: Text(
                            _leuPolitica
                                ? "Ler novamente"
                                : "Ler",
                          ),
                        ),
                      ),

                      const Divider(),

                      // ACEITE
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,

                        controlAffinity:
                        ListTileControlAffinity.leading,

                        value: _aceitouTermos,

                        onChanged:
                        (!_leuTermos || !_leuPolitica)
                            ? null
                            : (valor) {
                          setState(() {
                            _aceitouTermos =
                                valor ?? false;
                          });
                        },

                        title: const Text(
                          "Li e concordo com os Termos de Uso e estou ciente da Política de Privacidade.",
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                // BOTÃO CADASTRAR
                SizedBox(
                  width: double.infinity,
                  height: 48,

                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,

                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                    ),

                    onPressed:
                    (_carregando || !_aceitouTermos)
                        ? null
                        : _cadastrarUsuario,

                    child: _carregando
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
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