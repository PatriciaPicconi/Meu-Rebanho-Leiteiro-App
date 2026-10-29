import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FormularioBaixas extends StatefulWidget {
  const FormularioBaixas({super.key});

  @override
  State<FormularioBaixas> createState() => _FormularioBaixasState();
}

class _FormularioBaixasState extends State<FormularioBaixas> {
  final _formKey = GlobalKey<FormState>();
  final _obsController = TextEditingController();

  String? _animalSelecionado;
  String? _situacao = 'Vendida';
  bool _salvando = false;

  String? get _usuarioId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _salvarBaixa() async {
    if (!_formKey.currentState!.validate()) return;

    final usuarioId = _usuarioId;

    if (usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuário não autenticado.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_animalSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um animal.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final referencia = FirebaseFirestore.instance
          .collection('vacas')
          .doc(_animalSelecionado);

      final documento = await referencia.get();

      if (!documento.exists ||
          documento.data()?['usuarioId'] != usuarioId) {
        throw Exception('Animal não encontrado na sua conta.');
      }

      final dados = documento.data()!;

      if (dados['baixado'] == true) {
        throw Exception('Este animal já possui uma baixa registrada.');
      }

      await referencia.update({
        'baixado': true,
        'motivoBaixa': _situacao ?? 'Vendida',
        'observacaoBaixa': _obsController.text.trim(),
        'dataBaixa': FieldValue.serverTimestamp(),
        'dataAtualizacao': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível registrar a baixa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuarioId = _usuarioId;

    if (usuarioId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Usuário não autenticado.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Registrar Baixa',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.brown,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('vacas')
            .where('usuarioId', isEqualTo: usuarioId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Erro ao carregar os animais cadastrados.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.brown),
            );
          }

          final animais = snapshot.data?.docs.where((doc) {
                return doc.data()['baixado'] != true;
              }).toList() ??
              [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Registrar Baixa de Animal',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    value: _animalSelecionado,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Selecione o animal',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.brown),
                      ),
                    ),
                    items: animais.map((doc) {
                      final dados = doc.data();
                      final nome = (dados['nome'] ?? 'Sem nome').toString();
                      final brinco = (dados['brinco'] ?? '--').toString();

                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(
                          '$nome | Brinco: $brinco',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (valor) {
                      setState(() {
                        _animalSelecionado = valor;
                      });
                    },
                    validator: (valor) {
                      if (valor == null || valor.isEmpty) {
                        return 'Selecione um animal.';
                      }
                      return null;
                    },
                  ),

                  if (animais.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Não há animais ativos disponíveis para baixa.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),

                  const SizedBox(height: 24),

                  const Text(
                    'Motivo da Baixa:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),

                  Row(
                    children: [
                      Radio<String>(
                        value: 'Vendida',
                        groupValue: _situacao,
                        activeColor: Colors.brown,
                        onChanged: (valor) {
                          setState(() => _situacao = valor);
                        },
                      ),
                      const Text('Vendida'),
                      const SizedBox(width: 20),
                      Radio<String>(
                        value: 'Morreu',
                        groupValue: _situacao,
                        activeColor: Colors.brown,
                        onChanged: (valor) {
                          setState(() => _situacao = valor);
                        },
                      ),
                      const Text('Morreu'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _obsController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Observações adicionais',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.brown),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _salvando || animais.isEmpty
                          ? null
                          : _salvarBaixa,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _salvando
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'SALVAR BAIXA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
