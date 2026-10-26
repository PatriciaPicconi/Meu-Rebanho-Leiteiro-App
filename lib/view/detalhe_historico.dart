import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class DetalheHistorico extends StatefulWidget {
  final String vacaId;

  const DetalheHistorico({super.key, required this.vacaId});

  @override
  State<DetalheHistorico> createState() => _DetalheHistoricoState();
}

class _DetalheHistoricoState extends State<DetalheHistorico> {
  final _leiteController = TextEditingController();
  final _obsController = TextEditingController();

  bool _editandoLeite = false;
  bool _editandoObs = false;
  bool _editandoPais = false;
  bool _editandoFilhos = false;
  bool _salvandoPais = false;
  bool _salvandoFilhos = false;

  String? _paiId;
  String? _maeId;
  bool _paiNaoCadastrado = false;
  bool _maeNaoCadastrado = false;
  List<String> _filhosIds = [];
  List<String> _filhosNaoCadastrados = [];
  bool _relacoesInicializadas = false;

  static const String _naoCadastrado = '__nao_cadastrado__';

  @override
  void dispose() {
    _leiteController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  String? get _usuarioId => FirebaseAuth.instance.currentUser?.uid;

  String _calcularIdade(String? dataNascimento) {
    if (dataNascimento == null || dataNascimento.isEmpty) {
      return 'Não informada';
    }

    try {
      final partes = dataNascimento.split('/');
      if (partes.length != 3) return 'Data inválida';

      final nascimento = DateTime(
        int.parse(partes[2]),
        int.parse(partes[1]),
        int.parse(partes[0]),
      );

      final hoje = DateTime.now();
      int anos = hoje.year - nascimento.year;
      int meses = hoje.month - nascimento.month;

      if (meses < 0 || (meses == 0 && hoje.day < nascimento.day)) {
        anos--;
        meses += 12;
      }

      return '$anos anos e $meses meses';
    } catch (_) {
      return 'Data inválida';
    }
  }

  void _carregarEstadoRelacoes(Map<String, dynamic> dados) {
    _paiId = dados['paiId'] as String?;
    _maeId = dados['maeId'] as String?;
    _paiNaoCadastrado = dados['paiNaoCadastrado'] == true;
    _maeNaoCadastrado = dados['maeNaoCadastrado'] == true;

    final paisAntigos = (dados['pais'] ?? '').toString().trim();

    if (_paiId == null &&
        _maeId == null &&
        !_paiNaoCadastrado &&
        !_maeNaoCadastrado &&
        paisAntigos.isNotEmpty) {
      _paiNaoCadastrado = true;
    }

    final filhos = dados['filhosIds'];
    _filhosIds = filhos is List
        ? filhos.map((e) => e.toString()).toList()
        : <String>[];

    final filhosAntigos =
        dados['filhosNaoCadascados'] ?? dados['filhosNaoCadastrados'];

    _filhosNaoCadastrados = filhosAntigos is List
        ? filhosAntigos.map((e) => e.toString()).toList()
        : <String>[];
  }

  Future<void> _salvarPais() async {
    setState(() => _salvandoPais = true);

    try {
      final paisTexto = [
        if (_paiNaoCadastrado) 'Pai não cadastrado',
        if (_paiId != null) 'Pai selecionado',
        if (_maeNaoCadastrado) 'Mãe não cadastrada',
        if (_maeId != null) 'Mãe selecionada',
      ].join(', ');

      await FirebaseFirestore.instance
          .collection('vacas')
          .doc(widget.vacaId)
          .update({
        'paiId': _paiNaoCadastrado ? null : _paiId,
        'maeId': _maeNaoCadastrado ? null : _maeId,
        'paiNaoCadastrado': _paiNaoCadastrado,
        'maeNaoCadastrado': _maeNaoCadastrado,
        'pais': paisTexto,
        'dataAtualizacao': FieldValue.serverTimestamp(),
      });

      _mensagem('Pais do animal atualizados.');
    } catch (e) {
      _mensagem('Não foi possível salvar os pais: $e', erro: true);
    } finally {
      if (mounted) setState(() => _salvandoPais = false);
    }
  }

  Future<void> _selecionarFilhos(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> animais,
  ) async {
    final selecionados = List<String>.from(_filhosIds);

    final naoCadastradosController = TextEditingController(
      text: _filhosNaoCadastrados.join(', '),
    );

    final resultado = await showDialog<List<dynamic>>(
      context: context,
      builder: (dialogContext) {
        final temporarios = List<String>.from(selecionados);

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Selecionar filhos'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (animais.isEmpty)
                      const Text(
                        'Não há outros animais cadastrados para selecionar.',
                      ),
                    ...animais.map((doc) {
                      final dados = doc.data();
                      final nome = (dados['nome'] ?? 'Sem nome').toString();
                      final brinco = (dados['brinco'] ?? '--').toString();

                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(nome),
                        subtitle: Text('Brinco: $brinco'),
                        value: temporarios.contains(doc.id),
                        onChanged: (marcado) {
                          setDialogState(() {
                            if (marcado == true) {
                              if (!temporarios.contains(doc.id)) {
                                temporarios.add(doc.id);
                              }
                            } else {
                              temporarios.remove(doc.id);
                            }
                          });
                        },
                      );
                    }),
                    const Divider(),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Filhos não cadastrados ou que não estão mais na propriedade',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: naoCadastradosController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Informe nomes separados por vírgula',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  [temporarios, naoCadastradosController.text],
                ),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        );
      },
    );

    naoCadastradosController.dispose();

    if (resultado == null || !mounted) return;

    setState(() {
      _filhosIds = List<String>.from(resultado[0] as List);
      _filhosNaoCadastrados = (resultado[1] as String)
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    });
  }

  Future<void> _salvarFilhos() async {
    setState(() => _salvandoFilhos = true);

    try {
      final nomes = <String>[];
      final usuarioId = _usuarioId;

      if (usuarioId != null && _filhosIds.isNotEmpty) {
        final snapshots = await Future.wait(
          _filhosIds.map(
            (id) => FirebaseFirestore.instance
                .collection('vacas')
                .doc(id)
                .get(),
          ),
        );

        for (final doc in snapshots) {
          if (doc.exists && doc.data()?['usuarioId'] == usuarioId) {
            final nome = (doc.data()?['nome'] ?? 'Sem nome').toString();
            final brinco = (doc.data()?['brinco'] ?? '--').toString();
            nomes.add('$nome (brinco $brinco)');
          }
        }
      }

      nomes.addAll(_filhosNaoCadastrados);

      await FirebaseFirestore.instance
          .collection('vacas')
          .doc(widget.vacaId)
          .update({
        'filhosIds': _filhosIds,
        'filhosNaoCadastrados': _filhosNaoCadastrados,
        'filhos': nomes.isEmpty ? '' : nomes.join(', '),
        'dataAtualizacao': FieldValue.serverTimestamp(),
      });

      _mensagem('Histórico de filhos atualizado.');
    } catch (e) {
      _mensagem('Não foi possível salvar os filhos: $e', erro: true);
    } finally {
      if (mounted) setState(() => _salvandoFilhos = false);
    }
  }

    Future<void> _salvarCampo(String campo, String valor) async {
    try {
      dynamic valorSalvo = valor.trim();

      if (campo == 'producao_leite_mes') {
        valorSalvo =
            double.tryParse(valor.trim().replaceAll(',', '.'));

        if (valorSalvo == null || valorSalvo < 0) {
          _mensagem('Informe uma produção válida em litros.', erro: true);
          return;
        }
      }

      await FirebaseFirestore.instance
          .collection('vacas')
          .doc(widget.vacaId)
          .update({
        campo: valorSalvo,
        'dataAtualizacao': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        if (campo == 'producao_leite_mes') _editandoLeite = false;
        if (campo == 'observacoes') _editandoObs = false;
      });

      _mensagem('Informação atualizada.');
    } catch (e) {
      _mensagem('Não foi possível salvar: $e', erro: true);
    }
  }

  void _mensagem(String texto, {bool erro = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: erro ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _campoEditavel({
    required String titulo,
    required TextEditingController controller,
    required bool editando,
    required VoidCallback aoEditar,
    required VoidCallback aoSalvar,
    required ValueChanged<bool> aoMudarEdicao,
    String? sufixo,
    int maxLinhas = 1,
    TextInputType? teclado,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          crossAxisAlignment: maxLinhas > 1
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                readOnly: !editando,
                maxLines: maxLinhas,
                keyboardType: teclado,
                decoration: InputDecoration(
                  hintText: titulo == 'Área de Observações'
                      ? 'Escreva anotações importantes sobre o animal...'
                      : 'Informe o valor',
                  border: maxLinhas > 1
                      ? const OutlineInputBorder()
                      : const UnderlineInputBorder(),
                  suffixText: sufixo,
                ),
              ),
            ),
            if (!editando)
              IconButton(
                tooltip: 'Editar',
                icon: Icon(Icons.edit, color: Colors.grey.shade700),
                onPressed: aoEditar,
              )
            else ...[
              IconButton(
                tooltip: 'Salvar',
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: aoSalvar,
              ),
              IconButton(
                tooltip: 'Cancelar edição',
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => aoMudarEdicao(false),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _gerarSugestaoDescarte(
    double producaoMedia,
    int partosFalhos,
  ) {
    final manter = producaoMedia >= 15.0 && partosFalhos <= 1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: manter ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: manter ? Colors.green : Colors.red),
      ),
      child: Row(
        children: [
          Icon(
            manter ? Icons.check_circle : Icons.warning,
            color: manter ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              manter
                  ? 'Sugestão: manter no rebanho se boa produtividade média e histórico reprodutivo favorável.'
                  : 'Sugestão: avaliar descarte se baixa produção ou histórico reprodutivo desfavorável.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: manter ? Colors.green.shade900 : Colors.red.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _graficoProducao(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> animais,
  ) {
    final dados = animais.map((doc) {
      final registro = doc.data();
      final valorBruto = registro['producao_leite_mes'];

      final litros = valorBruto is num
          ? valorBruto.toDouble()
          : double.tryParse(
                  (valorBruto ?? '0').toString().replaceAll(',', '.'),
                ) ??
                0.0;

      return {
        'id': doc.id,
        'nome': (registro['nome'] ?? 'Sem nome').toString(),
        'brinco': (registro['brinco'] ?? '--').toString(),
        'litros': litros < 0 ? 0.0 : litros,
      };
    }).toList()
      ..sort(
        (a, b) => (b['litros'] as double)
            .compareTo(a['litros'] as double),
      );

    if (dados.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Ainda não há animais cadastrados para comparar.'),
      );
    }

    final maior = dados
        .map((e) => e['litros'] as double)
        .fold<double>(0, (a, b) => a > b ? a : b);

    final maxY = maior <= 0 ? 10.0 : maior * 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comparação da produção mensal (litros)',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: (dados.length * 52.0).clamp(180.0, 420.0),
          child: BarChart(
            BarChartData(
              maxY: maxY,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ),
              barGroups: List.generate(dados.length, (index) {
                final item = dados[index];
                final atual = item['id'] == widget.vacaId;
                final litros = item['litros'] as double;

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: litros,
                      color: atual
                          ? Colors.purple
                          : Colors.blueGrey.shade300,
                      width: 18,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (
                    group,
                    groupIndex,
                    rod,
                    rodIndex,
                  ) {
                    final item = dados[group.x];
                    final atual = item['id'] == widget.vacaId;

                    return BarTooltipItem(
                      '${item['nome']}${atual ? ' (selecionado)' : ''}\n${rod.toY.toStringAsFixed(1)} L',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...dados.map((item) {
          final atual = item['id'] == widget.vacaId;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: atual
                        ? Colors.purple
                        : Colors.blueGrey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${item['nome']} (brinco ${item['brinco']})${atual ? ' • animal em destaque' : ''}',
                    style: TextStyle(
                      fontWeight:
                          atual ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Text('${(item['litros'] as double).toStringAsFixed(1)} L'),
              ],
            ),
          );
        }),
      ],
    );
  }

    @override
  Widget build(BuildContext context) {
    final usuarioId = _usuarioId;

    if (usuarioId == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meu Rebanho Leiteiro',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.purple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('vacas')
            .doc(widget.vacaId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Erro ao carregar o histórico.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.purple),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Registro não encontrado.'));
          }

          final dados = snapshot.data!.data()!;

          if (dados['usuarioId'] != usuarioId) {
            return const Center(
              child: Text(
                'Você não tem permissão para visualizar este animal.',
              ),
            );
          }

          if (!_editandoLeite) {
            _leiteController.text =
                (dados['producao_leite_mes'] ?? '').toString();
          }

          if (!_editandoObs) {
            _obsController.text =
                (dados['observacoes'] ?? '').toString();
          }

          if (!_relacoesInicializadas) {
            _carregarEstadoRelacoes(dados);
            _relacoesInicializadas = true;
          }

          final queryAnimais = FirebaseFirestore.instance
              .collection('vacas')
              .where('usuarioId', isEqualTo: usuarioId)
              .snapshots();

          final partosFalhos =
              (dados['partos_falhos'] as num?)?.toInt() ?? 0;

          final producaoMedia = double.tryParse(
                _leiteController.text.replaceAll(',', '.'),
              ) ??
              0.0;

          final filhosTexto = (dados['filhos'] ?? '').toString();

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: queryAnimais,
            builder: (context, animaisSnapshot) {
              final todosAnimais = animaisSnapshot.data?.docs ?? [];

              final disponiveis = todosAnimais
                  .where((doc) => doc.id != widget.vacaId)
                  .toList();

              final nomes = {
                for (final doc in todosAnimais)
                  doc.id:
                      '${doc.data()['nome'] ?? 'Sem nome'} (brinco ${doc.data()['brinco'] ?? '--'})',
              };

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage:
                                (dados['foto'] is String &&
                                        (dados['foto'] as String).isNotEmpty)
                                    ? NetworkImage(dados['foto'] as String)
                                    : null,
                            child: (dados['foto'] is String &&
                                    (dados['foto'] as String).isNotEmpty)
                                ? null
                                : const Icon(
                                    Icons.agriculture,
                                    size: 54,
                                    color: Colors.grey,
                                  ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            (dados['nome'] ?? 'Sem nome').toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          Text(
                            'Brinco Nº: ${dados['brinco'] ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.purple.shade700,
                            ),
                          ),
                          Text(
                            'Idade: ${_calcularIdade(dados['dataNascimento']?.toString())}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 40),
                    const Text(
                      'Genealogia / Pais:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    if (!_editandoPais) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Pai: ${_paiNaoCadastrado ? 'Não cadastrado / fora da propriedade' : (_paiId == null ? 'Não informado' : (nomes[_paiId] ?? 'Animal não disponível'))}',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mãe: ${_maeNaoCadastrado ? 'Não cadastrada / fora da propriedade' : (_maeId == null ? 'Não informada' : (nomes[_maeId] ?? 'Animal não disponível'))}',
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          tooltip: 'Editar pais',
                          onPressed: () =>
                              setState(() => _editandoPais = true),
                          icon: const Icon(Icons.edit, color: Colors.grey),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _paiNaoCadastrado
                            ? _naoCadastrado
                            : (disponiveis.any((doc) => doc.id == _paiId)
                                ? _paiId
                                : null),
                        decoration: const InputDecoration(labelText: 'Pai'),
                        items: [
                          const DropdownMenuItem(
                            value: _naoCadastrado,
                            child: Text(
                              'Não cadastrado / fora da propriedade',
                            ),
                          ),
                          ...disponiveis.map(
                            (doc) => DropdownMenuItem(
                              value: doc.id,
                              child: Text(
                                '${doc.data()['nome'] ?? 'Sem nome'} (brinco ${doc.data()['brinco'] ?? '--'})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (valor) => setState(() {
                          _paiNaoCadastrado = valor == _naoCadastrado;
                          _paiId = _paiNaoCadastrado ? null : valor;
                        }),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _maeNaoCadastrado
                            ? _naoCadastrado
                            : (disponiveis.any((doc) => doc.id == _maeId)
                                ? _maeId
                                : null),
                        decoration: const InputDecoration(labelText: 'Mãe'),
                        items: [
                          const DropdownMenuItem(
                            value: _naoCadastrado,
                            child: Text(
                              'Não cadastrada / fora da propriedade',
                            ),
                          ),
                          ...disponiveis.map(
                            (doc) => DropdownMenuItem(
                              value: doc.id,
                              child: Text(
                                '${doc.data()['nome'] ?? 'Sem nome'} (brinco ${doc.data()['brinco'] ?? '--'})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (valor) => setState(() {
                          _maeNaoCadastrado = valor == _naoCadastrado;
                          _maeId = _maeNaoCadastrado ? null : valor;
                        }),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: 'Salvar pais',
                              onPressed: _salvandoPais
                                  ? null
                                  : () async {
                                      await _salvarPais();
                                      if (mounted) {
                                        setState(
                                          () => _editandoPais = false,
                                        );
                                      }
                                    },
                              icon: _salvandoPais
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.check,
                                      color: Colors.green,
                                    ),
                            ),
                            IconButton(
                              tooltip: 'Cancelar',
                              onPressed: () => setState(() {
                                _carregarEstadoRelacoes(dados);
                                _editandoPais = false;
                              }),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text(
                      'Histórico de Filhos:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (_filhosIds.isEmpty &&
                        _filhosNaoCadastrados.isEmpty &&
                        filhosTexto.isNotEmpty &&
                        !_editandoFilhos)
                      Text(
                        filhosTexto,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    if (_filhosIds.isEmpty &&
                        _filhosNaoCadastrados.isEmpty &&
                        filhosTexto.isEmpty &&
                        !_editandoFilhos)
                      const Text(
                        'Nenhum filho registrado até o momento.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    if (!_editandoFilhos) ...[
                      ..._filhosIds.map(
                        (id) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '• ${nomes[id] ?? 'Animal não disponível (ID: $id)'}',
                          ),
                        ),
                      ),
                      ..._filhosNaoCadastrados.map(
                        (nome) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('• $nome (não cadastrado)'),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          tooltip: 'Editar filhos',
                          onPressed: () =>
                              setState(() => _editandoFilhos = true),
                          icon: const Icon(Icons.edit, color: Colors.grey),
                        ),
                      ),
                    ] else ...[
                      TextButton.icon(
                        onPressed: () => _selecionarFilhos(disponiveis),
                        icon: const Icon(Icons.checklist),
                        label: const Text('Selecionar filhos'),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: 'Salvar filhos',
                              onPressed: _salvandoFilhos
                                  ? null
                                  : () async {
                                      await _salvarFilhos();
                                      if (mounted) {
                                        setState(
                                          () => _editandoFilhos = false,
                                        );
                                      }
                                    },
                              icon: _salvandoFilhos
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.check,
                                      color: Colors.green,
                                    ),
                            ),
                            IconButton(
                              tooltip: 'Cancelar',
                              onPressed: () => setState(() {
                                _carregarEstadoRelacoes(dados);
                                _editandoFilhos = false;
                              }),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _campoEditavel(
                      titulo: 'Produção de Leite Deste Mês (Litros)',
                      controller: _leiteController,
                      editando: _editandoLeite,
                      aoEditar: () =>
                          setState(() => _editandoLeite = true),
                      aoSalvar: () => _salvarCampo(
                        'producao_leite_mes',
                        _leiteController.text,
                      ),
                      aoMudarEdicao: (valor) {
                        setState(() {
                          _editandoLeite = valor;
                          if (!valor) {
                            _leiteController.text =
                                (dados['producao_leite_mes'] ?? '').toString();
                          }
                        });
                      },
                      sufixo: 'L',
                      teclado: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _campoEditavel(
                      titulo: 'Área de Observações',
                      controller: _obsController,
                      editando: _editandoObs,
                      aoEditar: () =>
                          setState(() => _editandoObs = true),
                      aoSalvar: () => _salvarCampo(
                        'observacoes',
                        _obsController.text,
                      ),
                      aoMudarEdicao: (valor) {
                        setState(() {
                          _editandoObs = valor;
                          if (!valor) {
                            _obsController.text =
                                (dados['observacoes'] ?? '').toString();
                          }
                        });
                      },
                      maxLinhas: 3,
                    ),
                    const SizedBox(height: 30),
                    _gerarSugestaoDescarte(
                      producaoMedia,
                      partosFalhos,
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Comparação da Produção Leiteira:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _graficoProducao(todosAnimais),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}