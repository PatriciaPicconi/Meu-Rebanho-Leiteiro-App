import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'telalogin.dart';
import 'telavaca.dart';
import 'telainseminar.dart';
import 'telatoque.dart';
import 'telaprenhez.dart';
import 'tela_historico.dart';

class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key});

  @override
  State<TelaPerfil> createState() =>
      _TelaPerfilState();
}

class _TelaPerfilState
    extends State<TelaPerfil> {
  final _formKey =
  GlobalKey<FormState>();

  final _nomeController =
  TextEditingController();

  final _dataNascimentoController =
  TextEditingController();

  final _propriedadeController =
  TextEditingController();

  final _cidadeController =
  TextEditingController();

  final _estadoController =
  TextEditingController();

  String _tipoUsuario =
      "Produtor Rural";

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

  Future<void>
  _selecionarDataNascimento() async {
    if (!_modoEdicao) return;

    final DateTime? dataSelecionada =
    await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );

    if (dataSelecionada != null) {
      setState(() {
        _dataNascimentoController
            .text =
        "${dataSelecionada.day.toString().padLeft(2, '0')}/"
            "${dataSelecionada.month.toString().padLeft(2, '0')}/"
            "${dataSelecionada.year}";
      });
    }
  }

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    final usuario =
        FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Nenhum usuário autenticado.",
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .set(
        {
          'nome':
          _nomeController.text.trim(),
          'dataNascimento':
          _dataNascimentoController
              .text
              .trim(),
          'email':
          usuario.email ?? '',
          'propriedade':
          _propriedadeController.text
              .trim(),
          'cidade':
          _cidadeController.text
              .trim(),
          'estado':
          _estadoController.text
              .trim()
              .toUpperCase(),
          'tipoUsuario':
          _tipoUsuario,
          'dataAtualizacao':
          FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        _modoEdicao = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Perfil atualizado com sucesso!",
          ),
          backgroundColor: Colors.yellowAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Erro ao atualizar perfil: $e",
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

  Future<void> _sairDaConta() async {
    await FirebaseAuth.instance
        .signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const TelaLogin(),
      ),
          (route) => false,
    );
  }

  Future<void> _excluirConta() async {
    final usuario =
        FirebaseAuth.instance.currentUser;

    if (usuario == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .delete();

      await usuario.delete();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
          const TelaLogin(),
        ),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Não foi possível excluir a conta. "
                "Faça login novamente e tente outra vez.",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmarAcao({
    required String titulo,
    required String mensagem,
    required VoidCallback aoConfirmar,
    bool perigoso = false,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensagem),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child:
              const Text("Cancelar"),
            ),
            ElevatedButton(
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                perigoso
                    ? Colors.red
                    : Colors.yellowAccent.shade700,
              ),
              onPressed: () {
                Navigator.pop(context);
                aoConfirmar();
              },
              child: const Text(
                "Confirmar",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _preencherCampos(
      Map<String, dynamic> dados) {
    _nomeController.text =
        dados['nome']?.toString() ?? '';

    _dataNascimentoController.text =
        dados['dataNascimento']
            ?.toString() ??
            '';

    _propriedadeController.text =
        dados['propriedade']
            ?.toString() ??
            '';

    _cidadeController.text =
        dados['cidade']?.toString() ??
            '';

    _estadoController.text =
        dados['estado']?.toString() ??
            '';

    _tipoUsuario =
        dados['tipoUsuario']?.toString() ??
            'Produtor Rural';
  }

  InputDecoration _decoracaoCampo(
      String label,
      IconData icone,
      ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icone,
        color: Colors.yellowAccent.shade700,
      ),
      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(12),
      ),
      disabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(12),
        borderSide:
        const BorderSide(
          color: Colors.yellowAccent,
          width: 2,
        ),
      ),
      filled: !_modoEdicao,
      fillColor: _modoEdicao
          ? Colors.white
          : Colors.grey.shade100,
    );
  }

  String? _validarCampoObrigatorio(
      String? valor,
      ) {
    if (valor == null ||
        valor.trim().isEmpty) {
      return "Campo obrigatório";
    }

    return null;
  }

  Widget _campoTexto({
    required TextEditingController
    controller,
    required String label,
    required IconData icone,
    bool obrigatorio = true,
    bool somenteLeitura = false,
    int? maxLength,
  }) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 14,
      ),
      child: TextFormField(
        controller: controller,
        enabled:
        _modoEdicao &&
            !somenteLeitura,
        readOnly: somenteLeitura,
        maxLength: maxLength,
        textCapitalization:
        label == "Estado"
            ? TextCapitalization
            .characters
            : TextCapitalization
            .sentences,
        decoration:
        _decoracaoCampo(
          label,
          icone,
        ).copyWith(
          counterText: "",
        ),
        validator: obrigatorio
            ? _validarCampoObrigatorio
            : null,
      ),
    );
  }

  Widget _campoEmail(
      String email) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 14,
      ),
      child: TextFormField(
        initialValue: email,
        enabled: false,
        decoration:
        _decoracaoCampo(
          "E-mail",
          Icons.email,
        ),
      ),
    );
  }

  Widget _cabecalhoPerfil(
      Map<String, dynamic> dados,
      ) {
    final nome =
        dados['nome']?.toString() ??
            'Usuário';

    final propriedade =
        dados['propriedade']
            ?.toString() ??
            'Propriedade não informada';

    return Column(
      children: [
        const SizedBox(height: 8),
        Stack(
          alignment:
          Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 62,
              backgroundColor:
              Colors.yellowAccent.shade700,
              child: const Icon(
                Icons.person,
                size: 82,
                color: Colors.yellowAccent,
              ),
            ),
            CircleAvatar(
              radius: 20,
              backgroundColor:
              Colors.yellowAccent.shade700,
              child: IconButton(
                icon: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Foto de perfil será implementada futuramente.",
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          nome,
          textAlign:
          TextAlign.center,
          style: const TextStyle(
            fontSize: 23,
            fontWeight:
            FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          propriedade,
          textAlign:
          TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          decoration:
          BoxDecoration(
            color:
            Colors.green.shade100,
            borderRadius:
            BorderRadius.circular(
              20,
            ),
          ),
          child: Text(
            _tipoUsuario,
            style:
            const TextStyle(
              color: Colors.yellowAccent,
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _formularioPerfil(
      User usuario) {
    return Container(
      padding:
      const EdgeInsets.all(16),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
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
            _campoTexto(
              controller:
              _nomeController,
              label: "Nome",
              icone: Icons.person,
            ),
            GestureDetector(
              onTap:
              _selecionarDataNascimento,
              child:
              AbsorbPointer(
                child: _campoTexto(
                  controller:
                  _dataNascimentoController,
                  label:
                  "Data de nascimento",
                  icone:
                  Icons.calendar_month,
                  somenteLeitura:
                  true,
                ),
              ),
            ),
            _campoEmail(
              usuario.email ?? '',
            ),
            _campoTexto(
              controller:
              _propriedadeController,
              label: "Propriedade",
              icone:
              Icons.home_work,
            ),
            _campoTexto(
              controller:
              _cidadeController,
              label: "Cidade",
              icone:
              Icons.location_city,
            ),
            _campoTexto(
              controller:
              _estadoController,
              label: "Estado",
              icone: Icons.map,
              maxLength: 2,
            ),
            DropdownButtonFormField<
                String>(
              value: _tipoUsuario,
              decoration:
              _decoracaoCampo(
                "Tipo de usuário",
                Icons.badge,
              ),
              items: const [
                DropdownMenuItem(
                  value:
                  "Produtor Rural",
                  child: Text(
                    "Produtor Rural",
                  ),
                ),
                DropdownMenuItem(
                  value: "Funcionário",
                  child: Text(
                    "Funcionário",
                  ),
                ),
                DropdownMenuItem(
                  value:
                  "Técnico Veterinário",
                  child: Text(
                    "Técnico Veterinário",
                  ),
                ),
                DropdownMenuItem(
                  value:
                  "Administrador",
                  child: Text(
                    "Administrador",
                  ),
                ),
              ],
              onChanged:
              _modoEdicao
                  ? (valor) {
                if (valor !=
                    null) {
                  setState(() {
                    _tipoUsuario =
                        valor;
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
            width:
            double.infinity,
            height: 48,
            child:
            ElevatedButton.icon(
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                Colors.yellowAccent.shade700,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius
                      .circular(
                    12,
                  ),
                ),
              ),
              icon: _carregando
                  ? const SizedBox(
                width: 18,
                height: 18,
                child:
                CircularProgressIndicator(
                  color: Colors
                      .white,
                  strokeWidth: 2,
                ),
              )
                  : const Icon(
                Icons.save,
                color:
                Colors.white,
              ),
              label:
              const Text(
                "SALVAR ALTERAÇÕES",
                style: TextStyle(
                  color:
                  Colors.white,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              onPressed:
              _carregando
                  ? null
                  : _salvarPerfil,
            ),
          ),
        const SizedBox(
          height: 12,
        ),
        SizedBox(
          width:
          double.infinity,
          height: 48,
          child:
          OutlinedButton.icon(
            style:
            OutlinedButton.styleFrom(
              side:
              const BorderSide(
                color:
                Colors.green,
              ),
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
              ),
            ),
            icon: const Icon(
              Icons.logout,
              color:
              Colors.green,
            ),
            label: const Text(
              "SAIR DA CONTA",
              style: TextStyle(
                color:
                Colors.green,
                fontWeight:
                FontWeight.bold,
              ),
            ),
            onPressed: () {
              _confirmarAcao(
                titulo:
                "Sair da conta",
                mensagem:
                "Deseja realmente sair do aplicativo?",
                aoConfirmar:
                _sairDaConta,
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          icon: const Icon(
            Icons.delete_forever,
            color: Colors.red,
          ),
          label: const Text(
            "EXCLUIR CONTA",
            style: TextStyle(
              color: Colors.red,
              fontWeight:
              FontWeight.bold,
            ),
          ),
          onPressed: () {
            _confirmarAcao(
              titulo:
              "Excluir conta",
              mensagem:
              "Esta ação é permanente. Os dados do perfil serão removidos. Deseja continuar?",
              perigoso: true,
              aoConfirmar:
              _excluirConta,
            );
          },
        ),
      ],
    );
  }

  Widget _botaoMenu(
      BuildContext context,
      IconData icone,
      String label,
      Color corIcone,
      Widget tela,
      ) {
    return TextButton(
      onPressed: () =>
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => tela,
            ),
          ),
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
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
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
      BuildContext context) {
    final usuario =
        FirebaseAuth.instance
            .currentUser;

    if (usuario == null) {
      return Scaffold(
        appBar: AppBar(
          title:
          const Text("Perfil"),
          backgroundColor:
          Colors.yellowAccent.shade700,
        ),
        body:
        const Center(
          child: Text(
            "Nenhum usuário autenticado.",
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
      const Color(0xFFEAF3E8),
      appBar: AppBar(
        backgroundColor:
        Colors.yellowAccent.shade700,
        iconTheme:
        const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          "Perfil do Usuário",
          style: TextStyle(
            color: Colors.white,
            fontWeight:
            FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _modoEdicao
                  ? Icons.close
                  : Icons.edit,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _modoEdicao =
                !_modoEdicao;
              });
            },
          ),
        ],
      ),
      body:
      StreamBuilder<DocumentSnapshot>(
        stream:
        FirebaseFirestore.instance
            .collection(
            'usuarios')
            .doc(usuario.uid)
            .snapshots(),
        builder: (
            context,
            snapshot,
            ) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Erro ao carregar os dados do usuário.",
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
              CircularProgressIndicator(
                color: Colors.yellowAccent,
              ),
            );
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Padding(
                padding:
                EdgeInsets.all(20),
                child: Text(
                  "Perfil não encontrado. Verifique se o cadastro foi concluído corretamente.",
                  textAlign:
                  TextAlign.center,
                ),
              ),
            );
          }

          final dados =
          snapshot.data!.data()
          as Map<String, dynamic>;

          if (!_modoEdicao) {
            _preencherCampos(
              dados,
            );
          }

          return SingleChildScrollView(
            padding:
            const EdgeInsets.all(
              20,
            ),
            child: Column(
              children: [
                _cabecalhoPerfil(
                  dados,
                ),
                const SizedBox(
                  height: 24,
                ),
                _formularioPerfil(
                  usuario,
                ),
                const SizedBox(
                  height: 20,
                ),
                _botoesAcao(),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar:
      BottomAppBar(
        color: Colors.yellowAccent.shade700,
        child:
        SingleChildScrollView(
          scrollDirection:
          Axis.horizontal,
          child: Row(
            mainAxisAlignment:
            MainAxisAlignment
                .spaceEvenly,
            children: [
              _botaoMenu(
                context,
                Icons.agriculture,
                "VACAS",
                Colors.lightGreenAccent,
                const TelaVaca(),
              ),
              _botaoMenu(
                context,
                Icons.vaccines,
                "INSEMINAR",
                Colors.blueAccent,
                const TelaInseminar(),
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
                Icons.history,
                "HISTÓRICO",
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