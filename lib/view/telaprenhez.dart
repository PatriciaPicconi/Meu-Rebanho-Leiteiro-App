import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'telavaca.dart';
import 'telainseminar.dart';
import 'telatoque.dart';
import 'telaperfil.dart';
import 'tela_historico.dart';
import 'tela_baixas.dart';

const String imagemAnimal = 'assets/img/animal.png';
const String imagemToque = 'assets/img/toque.png';

const int diasGestacaoBovina = 283;

/// Converte datas armazenadas no Firestore para DateTime.
/// Aceita Timestamp, DateTime, dd/MM/yyyy e yyyy-MM-dd.
DateTime? converterData(dynamic valor) {
  if (valor == null) return null;

  if (valor is Timestamp) {
    final data = valor.toDate();
    return DateTime(data.year, data.month, data.day);
  }

  if (valor is DateTime) {
    return DateTime(valor.year, valor.month, valor.day);
  }

  final texto = valor.toString().trim();
  if (texto.isEmpty) return null;

  final partes = texto.split('/');

  if (partes.length == 3) {
    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final ano = int.tryParse(partes[2]);

    if (dia != null && mes != null && ano != null) {
      try {
        return DateTime(ano, mes, dia);
      } catch (_) {
        return null;
      }
    }
  }

  return DateTime.tryParse(texto)?.letData();
}

/// Normaliza uma data para não considerar horas e minutos.
extension on DateTime {
  DateTime letData() => DateTime(year, month, day);
}

String formatarData(DateTime? data) {
  if (data == null) return '--/--/----';

  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');

  return '$dia/$mes/${data.year}';
}

/// Calcula a previsão de parto a partir da data da inseminação.
DateTime? calcularPrevisaoParto(Map<String, dynamic> vaca) {
  final dataInseminacao = converterData(
    vaca['dataInseminacao'] ?? vaca['ultimaInseminacao'],
  );

  if (dataInseminacao == null) return null;

  return dataInseminacao.add(
    const Duration(days: diasGestacaoBovina),
  );
}

class TelaPrenhez extends StatefulWidget {
  const TelaPrenhez({super.key});

  @override
  State<TelaPrenhez> createState() => _TelaPrenhezState();
}

class _TelaPrenhezState extends State<TelaPrenhez> {
  final TextEditingController _buscaController = TextEditingController();

  String _busca = '';

  // Evita solicitar a mesma atualização várias vezes enquanto
  // o Firestore ainda está processando a alteração.
  final Set<String> _atualizando = {};

  String? get _usuarioId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  /// Atualiza o status de Prenhe para Vazia quando a previsão
  /// de parto de 283 dias já passou.
  ///
  /// A atualização acontece quando esta tela recebe os documentos.
  Future<void> _atualizarGestacoesVencidas(
    List<QueryDocumentSnapshot> documentos,
  ) async {
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);

    for (final doc in documentos) {
      final vaca = doc.data() as Map<String, dynamic>;
      final status = (vaca['status'] ?? '').toString();

      if (status != 'Prenhe' || _atualizando.contains(doc.id)) {
        continue;
      }

      final previsao = calcularPrevisaoParto(vaca);

      if (previsao == null || previsao.isAfter(hojeSemHora)) {
        continue;
      }

      _atualizando.add(doc.id);

      try {
        await FirebaseFirestore.instance
            .collection('vacas')
            .doc(doc.id)
            .update({
          'status': 'Vazia',
          'ultimoParto': formatarData(previsao),
          'atualizadoAutomaticamente': true,
        });
      } catch (erro) {
        debugPrint(
          'Erro ao atualizar o status do animal ${doc.id}: $erro',
        );
      } finally {
        _atualizando.remove(doc.id);
      }
    }
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
          MaterialPageRoute(builder: (context) => tela),
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
              color: corIcone,
              colorBlendMode: BlendMode.srcIn,
            )
          else if (icone != null)
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
          'Prenhez',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _buscaController,
              onChanged: (value) {
                setState(() {
                  _busca = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Pesquisar animal prenhe...',
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
            .where('usuarioId', isEqualTo: usuarioId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Erro ao carregar dados.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final todosDocumentos = snapshot.data!.docs;

          final documentos = todosDocumentos.where((doc) {
            final vaca = doc.data() as Map<String, dynamic>;

            final nome = (vaca['nome'] ?? '')
                .toString()
                .toLowerCase();

            final brinco = (vaca['brinco'] ?? '')
                .toString()
                .toLowerCase();

            final status = (vaca['status'] ?? '').toString();

            return status == 'Prenhe' &&
                (nome.contains(_busca) || brinco.contains(_busca));
          }).toList();

          if (documentos.isEmpty) {
            return const Center(
              child: Text('Nenhum animal prenhe encontrado.'),
            );
          }

          return ListView.builder(
            itemCount: documentos.length,
            itemBuilder: (context, index) {
              final doc = documentos[index];
              final vaca = <String, dynamic>{
                ...(doc.data() as Map<String, dynamic>),
                'id': doc.id,
              };

              final previsaoParto = calcularPrevisaoParto(vaca);

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                child: ListTile(
                  leading: Image.asset(
                    imagemAnimal,
                    width: 45,
                    height: 45,
                    fit: BoxFit.contain,
                    color: Colors.red,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                  title: Text(
                    "${vaca['nome'] ?? 'Sem nome'} "
                    "(Brinco: ${vaca['brinco'] ?? 'N/A'})",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Previsão de Parto: ${formatarData(previsaoParto)}',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetalhesPrenhez(
                          vaca: vaca,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.red,
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
                const TelaInseminar(),
              ),
              _botaoMenu(
                context,
                null,
                'TOQUE',
                Colors.orange,
                const TelaToque(),
                imagem: imagemToque,
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
                Icons.person,
                'PERFIL',
                Colors.deepOrangeAccent,
                const TelaPerfil(),
              ),
              _botaoMenu(
                context,
                Icons.trending_down,
                'BAIXAS',
                Colors.brown,
                const TelaBaixas(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DetalhesPrenhez extends StatefulWidget {
  final Map<String, dynamic> vaca;

  const DetalhesPrenhez({
    super.key,
    required this.vaca,
  });

  @override
  State<DetalhesPrenhez> createState() => _DetalhesPrenhezState();
}

class _DetalhesPrenhezState extends State<DetalhesPrenhez> {
  Future<void> _registrarResultadoParto() async {
    String resultado = 'sucesso';

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Confirmar resultado do parto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Como foi o parto de ${(widget.vaca['nome'] ?? 'este animal').toString()}?',
              ),
              const SizedBox(height: 12),
              RadioListTile<String>(
                value: 'sucesso',
                groupValue: resultado,
                title: const Text('Parto com sucesso'),
                activeColor: Colors.green,
                onChanged: (valor) {
                  if (valor != null) {
                    setDialogState(() => resultado = valor);
                  }
                },
              ),
              RadioListTile<String>(
                value: 'falho',
                groupValue: resultado,
                title: const Text('Parto falho'),
                activeColor: Colors.red,
                onChanged: (valor) {
                  if (valor != null) {
                    setDialogState(() => resultado = valor);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirmar resultado'),
            ),
          ],
        ),
      ),
    );

    if (confirmado != true || !mounted) return;

    final usuarioId = FirebaseAuth.instance.currentUser?.uid;
    if (usuarioId == null) {
      _mostrarMensagem('Usuário não autenticado.', erro: true);
      return;
    }

    final referencia = FirebaseFirestore.instance
        .collection('vacas')
        .doc((widget.vaca['id'] ?? '').toString());

    // O ID nem sempre vem dentro do mapa recebido. Procuramos pelo animal
    // do usuário usando o nome/brinco quando necessário.
    try {
      DocumentReference<Map<String, dynamic>> docRef = referencia;
      if ((widget.vaca['id'] ?? '').toString().isEmpty) {
        final consulta = await FirebaseFirestore.instance
            .collection('vacas')
            .where('usuarioId', isEqualTo: usuarioId)
            .where('brinco', isEqualTo: widget.vaca['brinco'])
            .limit(1)
            .get();
        if (consulta.docs.isEmpty) {
          _mostrarMensagem('Não foi possível localizar o registro do animal.', erro: true);
          return;
        }
        docRef = consulta.docs.first.reference;
      }

      await FirebaseFirestore.instance.runTransaction((transacao) async {
        final snapshot = await transacao.get(docRef);
        if (!snapshot.exists) {
          throw Exception('Registro do animal não encontrado.');
        }

        final dadosAtuais = snapshot.data() ?? <String, dynamic>{};
        if (dadosAtuais['usuarioId'] != usuarioId) {
          throw Exception('Você não tem permissão para alterar este animal.');
        }
        if ((dadosAtuais['status'] ?? '').toString() != 'Prenhe') {
          throw Exception('O resultado deste período de prenhez já foi registrado ou o animal não está prenhe.');
        }

        int numero(String campo) {
          final valor = dadosAtuais[campo];
          if (valor is num) return valor.toInt();
          return int.tryParse((valor ?? '0').toString()) ?? 0;
        }

        final atualizacao = <String, dynamic>{
          'status': 'Vazia',
          'ultimoParto': formatarData(DateTime.now()),
          'dataUltimoParto': Timestamp.now(),
          'ultimoResultadoParto': resultado,
          'quantidade_prenhez': numero('quantidade_prenhez') + 1,
          'dataAtualizacao': FieldValue.serverTimestamp(),
        };

        if (resultado == 'sucesso') {
          atualizacao['partos_sucesso'] = numero('partos_sucesso') + 1;
        } else {
          atualizacao['partos_falhos'] = numero('partos_falhos') + 1;
        }

        transacao.update(docRef, atualizacao);
      });

      if (mounted) {
        _mostrarMensagem(
          resultado == 'sucesso'
              ? 'Parto registrado com sucesso!'
              : 'Parto falho registrado. Os dados foram atualizados.',
        );
        Navigator.pop(context);
      }
    } catch (erro) {
      _mostrarMensagem('Não foi possível registrar o parto: $erro', erro: true);
    }
  }

  void _mostrarMensagem(String mensagem, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: erro ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataInseminacao = converterData(
      widget.vaca['dataInseminacao'] ?? widget.vaca['ultimaInseminacao'],
    );

    final previsaoParto = calcularPrevisaoParto(widget.vaca);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalhes da Prenhez',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Image.asset(
                    imagemAnimal,
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                    color: Colors.red,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    (widget.vaca['nome'] ?? 'Sem nome').toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Brinco: ${widget.vaca['brinco'] ?? 'N/A'}",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 40),
            _cardData(
              'Data da Inseminação',
              formatarData(dataInseminacao),
              const Icon(
                Icons.calendar_today,
                color: Colors.blue,
                size: 30,
              ),
            ),
            const SizedBox(height: 15),
            _cardData(
              'Data do Exame de Toque',
              (widget.vaca['ultimoExameToque'] ?? '--/--/----').toString(),
              Image.asset(
                imagemToque,
                width: 30,
                height: 30,
                fit: BoxFit.contain,
                color: Colors.orange,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 15),
            _cardData(
              'Previsão de Parto (283 dias)',
              formatarData(previsaoParto),
              const Icon(
                Icons.insights,
                color: Colors.red,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (widget.vaca['status'] ?? '').toString() == 'Prenhe'
                    ? _registrarResultadoParto
                    : null,
                icon: const Icon(Icons.fact_check),
                label: const Text('Registrar resultado do parto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.blueGrey.withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.blueGrey,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'A previsão é estimada em 283 dias após a '
                      'inseminação. A data real do parto pode variar. '
                      'Após o vencimento, o sistema altera o status '
                      'para Vazia quando a tela de prenhez verifica '
                      'os registros.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardData(
    String titulo,
    String data,
    Widget icone,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: Center(child: icone),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.purple,
                  ),
                ),
                Text(
                  data,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}