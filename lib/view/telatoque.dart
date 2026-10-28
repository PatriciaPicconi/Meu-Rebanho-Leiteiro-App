import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'telavaca.dart';
import 'telainseminar.dart' as inseminacao;
import 'telaprenhez.dart';
import 'telaperfil.dart';
import 'tela_historico.dart';
import 'tela_baixas.dart';

const String imagemToque = 'assets/img/toque.png';
const String imagemAnimal = 'assets/img/animal.png';

class TelaToque extends StatefulWidget {
  const TelaToque({super.key});

  @override
  State<TelaToque> createState() => _TelaToqueState();
}

class _TelaToqueState extends State<TelaToque> {
  final TextEditingController _buscaController =
      TextEditingController();

  String _busca = '';

  String? get _usuarioId =>
      FirebaseAuth.instance.currentUser?.uid;

  bool _animalEstaBaixado(Map<String, dynamic> dados) {
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

  String _formatarData(dynamic valor) {
    if (valor == null) return '--/--/----';

    if (valor is Timestamp) {
      final data = valor.toDate();
      return '${data.day.toString().padLeft(2, '0')}/'
          '${data.month.toString().padLeft(2, '0')}/'
          '${data.year}';
    }

    final texto = valor.toString().trim();

    if (texto.isEmpty) return '--/--/----';
    if (texto.contains('/')) return texto;

    final data = DateTime.tryParse(texto);

    if (data != null) {
      return '${data.day.toString().padLeft(2, '0')}/'
          '${data.month.toString().padLeft(2, '0')}/'
          '${data.year}';
    }

    return texto;
  }

  String _obterDataInseminacao(
    Map<String, dynamic> dados,
  ) {
    final dataNova = dados['dataInseminacao'];

    if (dataNova != null &&
        dataNova.toString().trim().isNotEmpty) {
      return _formatarData(dataNova);
    }

    final dataAntiga = dados['ultimaInseminacao'];

    if (dataAntiga != null &&
        dataAntiga.toString().trim().isNotEmpty) {
      return _formatarData(dataAntiga);
    }

    return '--/--/----';
  }

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
        automaticallyImplyLeading: false,
        title: const Text(
          'Toque',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _buscaController,
              onChanged: (value) {
                setState(() {
                  _busca = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText:
                    'Pesquisar animal por nome ou brinco...',
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
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
              child: Text('Erro ao carregar dados.'),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final documentos = snapshot.data?.docs ?? [];

          final animais = documentos.where((doc) {
            final dados =
                doc.data() as Map<String, dynamic>;

            final nome = (dados['nome'] ?? '')
                .toString()
                .toLowerCase();

            final brinco = (dados['brinco'] ?? '')
                .toString()
                .toLowerCase();

            final status = (dados['status'] ?? '')
                .toString()
                .trim()
                .toLowerCase();

            return status == 'inseminada' &&
                !_animalEstaBaixado(dados) &&
                (nome.contains(_busca) ||
                    brinco.contains(_busca));
          }).toList();

          if (animais.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum animal pendente de toque.',
              ),
            );
          }

          return ListView.builder(
            itemCount: animais.length,
            itemBuilder: (context, index) {
              final doc = animais[index];
              final vaca =
                  doc.data() as Map<String, dynamic>;

              final nome =
                  vaca['nome']?.toString() ?? 'Sem nome';

              final brinco =
                  vaca['brinco']?.toString() ?? '';

              final dataInseminacao =
                  _obterDataInseminacao(vaca);

              return ListTile(
                leading: Image.asset(
                  imagemToque,
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
                title: Text(
                  nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Brinco: $brinco - Insem.: '
                  '$dataInseminacao',
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FormularioToque(
                        vaca: vaca,
                        id: doc.id,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.orange,
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
                Icons.vaccines,
                'INSEMINAR',
                Colors.blue,
                const inseminacao.TelaInseminar(),
              ),
              _botaoMenu(
                context,
                Icons.favorite,
                'PRENHEZ',
                Colors.red,
                const TelaPrenhez(),
              ),
              _botaoMenu(
                context,
                Icons.history,
                'HISTÓRICO',
                Colors.purpleAccent,
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
                Icons.person,
                'PERFIL',
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

class FormularioToque extends StatefulWidget {
  final Map<String, dynamic> vaca;
  final String id;

  const FormularioToque({
    super.key,
    required this.vaca,
    required this.id,
  });

  @override
  State<FormularioToque> createState() =>
      _FormularioToqueState();
}

class _FormularioToqueState extends State<FormularioToque> {
  bool? _estaPrenha;
  bool _salvando = false;

  Future<void> _confirmarExame() async {
    if (_estaPrenha == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione o resultado!'),
        ),
      );
      return;
    }

    if (_salvando) return;

    setState(() {
      _salvando = true;
    });

    try {
      final referencia = FirebaseFirestore.instance
          .collection('vacas')
          .doc(widget.id);

      final documento = await referencia.get();

      if (!documento.exists) {
        throw Exception(
          'O animal não foi encontrado.',
        );
      }

      final dados =
          documento.data() as Map<String, dynamic>;

      final statusAtual = (dados['status'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      final baixado = dados['baixado'] == true ||
          statusAtual == 'baixado' ||
          statusAtual == 'baixada' ||
          statusAtual == 'baixa' ||
          statusAtual == 'baixado(a)';

      if (baixado) {
        throw Exception(
          'Este animal está registrado em baixas e não pode receber um toque.',
        );
      }

      await referencia.update({
        'status': _estaPrenha! ? 'Prenhe' : 'Vazia',
        'ultimoExameToque':
            DateTime.now().toString().split(' ')[0],
        'dataAtualizacao':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Exame de toque registrado com sucesso.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao registrar o toque: $e',
          ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Confirmar Resultado',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Image.asset(
              imagemToque,
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Text(
              'Vaca: ${widget.vaca['nome'] ?? 'Sem nome'} '
              '(Brinco: ${widget.vaca['brinco'] ?? ''})',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Resultado do Toque:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            RadioListTile<bool>(
              title: const Text('Sim, está prenha'),
              value: true,
              groupValue: _estaPrenha,
              onChanged: _salvando
                  ? null
                  : (value) {
                      setState(() {
                        _estaPrenha = value;
                      });
                    },
            ),
            RadioListTile<bool>(
              title: const Text('Não, está vazia'),
              value: false,
              groupValue: _estaPrenha,
              onChanged: _salvando
                  ? null
                  : (value) {
                      setState(() {
                        _estaPrenha = value;
                      });
                    },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                ),
                onPressed:
                    _salvando ? null : _confirmarExame,
                child: _salvando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'CONFIRMAR',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}