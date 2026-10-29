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
  final _litrosMesController = TextEditingController();
  final _anoMesController = TextEditingController();

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
  bool _mostrarGraficoProducao = false;
  bool _mostrarGraficoPartos = false;
  bool _mostrarListaProducaoOutros = false;

  static const String _naoCadastrado = '__nao_cadastrado__';

  @override
  void dispose() {
    _leiteController.dispose();
    _obsController.dispose();
    _litrosMesController.dispose();
    _anoMesController.dispose();
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

  bool _ehTouro(Map<String, dynamic> dados) {
    final tipo = (dados['tipoAnimal'] ?? dados['tipo'] ?? dados['sexo'] ?? '').toString().trim().toLowerCase();
    return tipo.contains('touro') || tipo == 'macho' || tipo == 'boi';
  }

  Future<void> _registrarProducaoMensal(Map<String, dynamic> dados) async {
    final litros = double.tryParse(_litrosMesController.text.trim().replaceAll(',', '.'));
    final mesAno = _anoMesController.text.trim();
    if (litros == null || litros < 0 || !RegExp(r'^\d{2}/\d{4}$').hasMatch(mesAno)) {
      _mensagem('Informe mês/ano no formato MM/AAAA e uma quantidade válida de litros.', erro: true);
      return;
    }
    final mes = int.tryParse(mesAno.substring(0, 2)) ?? 0;
    if (mes < 1 || mes > 12) {
      _mensagem('O mês deve estar entre 01 e 12.', erro: true);
      return;
    }
    try {
      final ref = FirebaseFirestore.instance.collection('vacas').doc(widget.vacaId);
      final snap = await ref.get();
      final raw = snap.data()?['historicoProducaoLeite'];
      final registros = raw is List ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
      final novo = <String, dynamic>{'mesAno': mesAno, 'litros': litros, 'encerrado': true};
      final indice = registros.indexWhere((r) => r['mesAno']?.toString() == mesAno);
      if (indice >= 0) { registros[indice] = novo; } else { registros.add(novo); }
      registros.sort((a, b) => (a['mesAno'] ?? '').toString().split('/').reversed.join().compareTo((b['mesAno'] ?? '').toString().split('/').reversed.join()));
      await ref.update({'historicoProducaoLeite': registros, 'producao_leite_mes': litros, 'dataAtualizacao': FieldValue.serverTimestamp()});
      _litrosMesController.clear();
      _anoMesController.clear();
      _mensagem('Mês encerrado. Você já pode registrar outro mês.');
    } catch (e) { _mensagem('Não foi possível registrar a produção: $e', erro: true); }
  }

  Widget _secaoProducaoMensal(Map<String, dynamic> dados) {
    final raw = dados['historicoProducaoLeite'];
    final registros = raw is List ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
    registros.sort((a, b) => (b['mesAno'] ?? '').toString().compareTo((a['mesAno'] ?? '').toString()));
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Produção de leite por mês', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple)),
      const SizedBox(height: 8),
      TextField(controller: _anoMesController, keyboardType: TextInputType.datetime, decoration: const InputDecoration(labelText: 'Mês e ano (MM/AAAA)', hintText: 'Ex.: 10/2026', border: OutlineInputBorder())),
      const SizedBox(height: 8),
      TextField(controller: _litrosMesController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Quantidade em litros', border: OutlineInputBorder())),
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white), onPressed: () => _registrarProducaoMensal(dados), icon: const Icon(Icons.check_circle_outline), label: const Text('Encerrar mês e registrar'))),
      const SizedBox(height: 8),
      const Text('Meses registrados', style: TextStyle(fontWeight: FontWeight.bold)),
      if (registros.isEmpty) const Text('Nenhum mês registrado ainda.'),
      ...registros.map((r) { final v = r['litros'] is num ? (r['litros'] as num).toDouble() : double.tryParse((r['litros'] ?? '0').toString()) ?? 0.0; return ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text((r['mesAno'] ?? 'Não informado').toString()), trailing: Text('${v.toStringAsFixed(1)} L')); }),
    ])));
  }

  Widget _buildDetalheTouro(Map<String, dynamic> dados, List<QueryDocumentSnapshot<Map<String, dynamic>>> animais) {
    final nome = (dados['nome'] ?? 'Touro').toString();
    final brinco = (dados['brinco'] ?? '--').toString();
    final usuarioId = _usuarioId;
    final rawFilhos = dados['filhosIds'];
    final filhosIds = rawFilhos is List ? rawFilhos.map((e) => e.toString()).toList() : <String>[];
    final rawExternos = dados['filhosNaoCadastrados'] ?? dados['filhosNaoCadascados'];
    final filhosExternos = rawExternos is List ? rawExternos.map((e) => e.toString()).toList() : <String>[];
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Column(children: [Image.asset('assets/img/touro.png', width: 90, height: 90, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.pets, size: 80, color: Colors.purple)), const SizedBox(height: 8), Text(nome, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple)), Text('Brinco Nº: $brinco', style: TextStyle(color: Colors.purple.shade700, fontSize: 16))])),
      const SizedBox(height: 16),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Inseminações deste touro', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.purple)),
        const SizedBox(height: 8),
        if (usuarioId == null) const Text('Usuário não autenticado.') else StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('inseminacoes').where('usuarioId', isEqualTo: usuarioId).snapshots(), builder: (context, snap) {
          if (snap.hasError) return const Text('Não foi possível carregar as inseminações.');
          if (!snap.hasData) return const LinearProgressIndicator();
          final touroNomeComBrinco = '$nome (Brinco: $brinco)';
          final regs = snap.data!.docs.where((d) { final x=d.data(); return x['touroId']?.toString()==widget.vacaId || (x['touro'] ?? '').toString()==touroNomeComBrinco || (x['touro'] ?? '').toString()==nome; }).toList();
          int sucesso=0, falha=0;
          for (final reg in regs) { final id=(reg.data()['vacaId'] ?? '').toString(); final vacas=animais.where((a)=>a.id==id).toList(); if(vacas.isEmpty) continue; final dadosVaca=vacas.first.data(); final touroAtual=dadosVaca['ultimoTouroId']?.toString(); if(touroAtual != null && touroAtual.isNotEmpty && touroAtual != widget.vacaId) continue; final status=(dadosVaca['status'] ?? '').toString().toLowerCase(); if(status=='prenhe') sucesso++; else if(status=='vazia') falha++; }
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Total de inseminações: ${regs.length}'), Text('Sucesso (prenhez confirmada): $sucesso'), Text('Falha (vazia confirmada): $falha'), const SizedBox(height: 4), const Text('Os resultados refletem a situação reprodutiva atual das vacas inseminadas.')]);
        }),
      ]))),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Filhos registrados', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.purple)),
        const SizedBox(height: 8),
        if (filhosIds.isEmpty && filhosExternos.isEmpty) const Text('Nenhum filho registrado até o momento.'),
        ...filhosIds.map((id) { final achado=animais.where((a)=>a.id==id).toList(); final texto=achado.isEmpty ? 'Animal não disponível' : '${achado.first.data()['nome'] ?? 'Sem nome'} (brinco ${achado.first.data()['brinco'] ?? '--'})'; return Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text('• $texto')); }),
        ...filhosExternos.map((n)=>Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text('• $n (fora da propriedade)'))),
        Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => setState(() => _editandoFilhos=true), icon: const Icon(Icons.edit), label: const Text('Editar filhos'))),
        if (_editandoFilhos) ...[
          TextButton.icon(onPressed: () => _selecionarFilhos(animais.where((a)=>a.id!=widget.vacaId).toList()), icon: const Icon(Icons.checklist), label: const Text('Selecionar animais ou outros')),
          Align(alignment: Alignment.centerRight, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [IconButton(onPressed: () async { await _salvarFilhos(); if(mounted) setState(()=>_editandoFilhos=false); }, icon: const Icon(Icons.check, color: Colors.green)), IconButton(onPressed: ()=>setState(()=>_editandoFilhos=false), icon: const Icon(Icons.close, color: Colors.red))])),
        ],
      ]))),
    ]));
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
      ],
    );
  }

    Widget _graficoPartos(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> animais,
  ) {
    int inteiro(dynamic valor) {
      if (valor is num) return valor.toInt();
      return int.tryParse((valor ?? '0').toString()) ?? 0;
    }

    final dados = animais.map((doc) {
      final registro = doc.data();
      final sucessos = inteiro(registro['partos_sucesso']);
      final falhos = inteiro(registro['partos_falhos']);
      final prenhezesSalvas = inteiro(registro['quantidade_prenhez']);

      return <String, dynamic>{
        'id': doc.id,
        'nome': (registro['nome'] ?? 'Sem nome').toString(),
        'brinco': (registro['brinco'] ?? '--').toString(),
        'prenhezes': prenhezesSalvas > 0
            ? prenhezesSalvas
            : sucessos + falhos,
        'sucessos': sucessos,
        'falhos': falhos,
      };
    }).toList()
      ..sort((a, b) {
        final totalA = (a['sucessos'] as int) + (a['falhos'] as int);
        final totalB = (b['sucessos'] as int) + (b['falhos'] as int);
        return totalB.compareTo(totalA);
      });

    if (dados.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Ainda não há animais cadastrados para comparar.'),
      );
    }

    final maior = dados.fold<int>(0, (maiorAtual, item) {
      final sucessos = item['sucessos'] as int;
      final falhos = item['falhos'] as int;
      final maximo = sucessos > falhos ? sucessos : falhos;
      return maximo > maiorAtual ? maximo : maiorAtual;
    });
    final maxY = maior == 0 ? 1.0 : (maior + 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Partos por animal: sucesso x falha',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
        const SizedBox(height: 8),
        const Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            _LegendaParto(cor: Colors.green, texto: 'Sucesso'),
            _LegendaParto(cor: Colors.red, texto: 'Falho'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: (dados.length * 58.0).clamp(200.0, 440.0),
          child: BarChart(
            BarChartData(
              maxY: maxY,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              groupsSpace: 12,
              gridData: FlGridData(show: true, drawHorizontalLine: true, drawVerticalLine: false),
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
                    interval: 1,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ),
              barGroups: List.generate(dados.length, (index) {
                final item = dados[index];
                return BarChartGroupData(
                  x: index,
                  barsSpace: 4,
                  barRods: [
                    BarChartRodData(
                      toY: (item['sucessos'] as int).toDouble(),
                      color: Colors.green,
                      width: 10,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3),
                      ),
                    ),
                    BarChartRodData(
                      toY: (item['falhos'] as int).toDouble(),
                      color: Colors.red,
                      width: 10,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3),
                      ),
                    ),
                  ],
                );
              }),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final item = dados[group.x];
                    final tipo = rodIndex == 0 ? 'Sucesso' : 'Falho';
                    return BarTooltipItem(
                      '${item['nome']}\n$tipo: ${rod.toY.toInt()}',
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

      ],
    );
  }

  Widget _cartaoHistoricoToques(Map<String, dynamic> dados) {
    final raw = dados['historicoToques'];
    final registros = raw is List ? raw.whereType<Map>().toList() : <Map>[];
    int sucesso = 0;
    int falha = 0;
    for (final registro in registros) {
      final resultado = registro['resultado'];
      if (resultado == true || resultado.toString().toLowerCase() == 'prenhe' || resultado.toString().toLowerCase() == 'sucesso') {
        sucesso++;
      } else if (resultado == false || resultado.toString().toLowerCase() == 'vazia' || resultado.toString().toLowerCase() == 'falha') {
        falha++;
      }
    }
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Histórico de toques', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple)),
            const SizedBox(height: 8),
            Text('Total de toques registrados: ${registros.length}'),
            Text('Toques com prenhez confirmada: $sucesso'),
            Text('Toques sem prenhez confirmada: $falha'),
            if (registros.isEmpty)
              const Text('Os exames anteriores não possuem histórico individual salvo. Os próximos exames serão contabilizados.'),
          ],
        ),
      ),
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
              dados['partos_falhos'] is num ? (dados['partos_falhos'] as num).toInt() : int.tryParse((dados['partos_falhos'] ?? '0').toString()) ?? 0;

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

              if (_ehTouro(dados)) return _buildDetalheTouro(dados, todosAnimais);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: Image.asset(
                              'assets/img/animal.png',
                              fit: BoxFit.contain,
                              color: Colors.purple,
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
                    _secaoProducaoMensal(dados),
                    const SizedBox(height: 16),
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
                    const Text('Comparação da produção de leite', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 16)),
                    const SizedBox(height: 8),
                    _graficoProducao(todosAnimais),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text(
                              'Informações de produção das outras vacas',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                            trailing: Icon(
                              _mostrarListaProducaoOutros
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.purple,
                            ),
                            onTap: () => setState(() {
                              _mostrarListaProducaoOutros =
                                  !_mostrarListaProducaoOutros;
                            }),
                          ),
                          if (_mostrarListaProducaoOutros)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: Column(
                                children: todosAnimais
                                    .where((animal) =>
                                        animal.id != widget.vacaId &&
                                        !_ehTouro(animal.data()))
                                    .map((animal) {
                                  final animalDados = animal.data();
                                  final valor = animalDados['producao_leite_mes'];
                                  final litros = valor is num
                                      ? valor.toDouble()
                                      : double.tryParse(
                                            (valor ?? '0').toString(),
                                          ) ??
                                          0.0;
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      '${animalDados['nome'] ?? 'Sem nome'} '
                                      '(brinco ${animalDados['brinco'] ?? '--'})',
                                    ),
                                    trailing: Text('${litros.toStringAsFixed(1)} L'),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _graficoPartos(todosAnimais),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text(
                              'Informações reprodutivas das outras vacas',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                            trailing: Icon(
                              _mostrarGraficoPartos
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.purple,
                            ),
                            onTap: () => setState(() {
                              _mostrarGraficoPartos = !_mostrarGraficoPartos;
                            }),
                          ),
                          if (_mostrarGraficoPartos)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: Column(
                                children: todosAnimais
                                    .where((animal) =>
                                        animal.id != widget.vacaId &&
                                        !_ehTouro(animal.data()))
                                    .map((animal) {
                                  final animalDados = animal.data();
                                  final quantidade = animalDados['quantidade_prenhez'];
                                  final sucessoValor = animalDados['partos_sucesso'];
                                  final falhaValor = animalDados['partos_falhos'];
                                  final prenhezes = quantidade is num
                                      ? quantidade.toInt()
                                      : int.tryParse((quantidade ?? '0').toString()) ?? 0;
                                  final sucessos = sucessoValor is num
                                      ? sucessoValor.toInt()
                                      : int.tryParse((sucessoValor ?? '0').toString()) ?? 0;
                                  final falhas = falhaValor is num
                                      ? falhaValor.toInt()
                                      : int.tryParse((falhaValor ?? '0').toString()) ?? 0;
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      '${animalDados['nome'] ?? 'Sem nome'} '
                                      '(brinco ${animalDados['brinco'] ?? '--'})',
                                    ),
                                    subtitle: Text(
                                      'Prenhezes: $prenhezes | Partos com sucesso: '
                                      '$sucessos | Falhas: $falhas',
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _cartaoHistoricoToques(dados),
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

class _LegendaParto extends StatelessWidget {
  final Color cor;
  final String texto;

  const _LegendaParto({required this.cor, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(texto),
      ],
    );
  }
}