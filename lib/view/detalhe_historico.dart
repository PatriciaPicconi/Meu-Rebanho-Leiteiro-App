import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class DetalheHistorico extends StatefulWidget {
  final String vacaId;

  const DetalheHistorico({super.key, required this.vacaId});

  @override
  State<DetalheHistorico> createState() => _DetalheHistoricoState();
}

class _DetalheHistoricoState extends State<DetalheHistorico> {
  final TextEditingController _paisController = TextEditingController();
  final TextEditingController _leiteController = TextEditingController();
  final TextEditingController _obsController = TextEditingController();

  @override
  void dispose() {
    _paisController.dispose();
    _leiteController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  String _calcularIdade(String? dataNascimento) {
    if (dataNascimento == null || dataNascimento.isEmpty) {
      return "Não informada";
    }

    try {
      final partes = dataNascimento.split('/');

      if (partes.length != 3) {
        return "Data inválida";
      }

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

      return "$anos anos e $meses meses";
    } catch (e) {
      return "Data inválida";
    }
  }

  Future<void> _atualizarCampo(String campo, String valor) async {
    await FirebaseFirestore.instance.collection('vacas').doc(widget.vacaId).update({
      campo: valor,
      'dataAtualizacao': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Informação atualizada."),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _gerarSugestaoDescarte(double producaoMedia, int partosFalhos) {
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
                  ? "Sugestão: manter no rebanho. Boa produtividade média e histórico reprodutivo favorável."
                  : "Sugestão: avaliar descarte. Baixa produção ou histórico reprodutivo desfavorável.",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Meu Rebanho Leiteiro",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vacas')
            .doc(widget.vacaId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("Erro ao carregar o histórico."),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.purple),
            );
          }

          if (!snapshot.data!.exists) {
            return const Center(
              child: Text("Registro não encontrado."),
            );
          }

          final dados = snapshot.data!.data() as Map<String, dynamic>;

          _paisController.text = dados['pais'] ?? '';
          _leiteController.text = dados['producao_leite_mes'] ?? '';
          _obsController.text = dados['observacoes'] ?? '';

          final partosSucesso = dados['partos_sucesso'] ?? 0;
          final partosFalhos = dados['partos_falhos'] ?? 0;
          final producaoMedia = double.tryParse(_leiteController.text) ?? 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(
                          dados['foto'] ?? 'https://via.placeholder.com/150',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        dados['nome'] ?? 'Sem Nome',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      Text(
                        'Brinco Nº: ${dados['brinco'] ?? 'N/A'}',
                        style: TextStyle(fontSize: 16, color: Colors.purple.shade700),
                      ),
                      Text(
                        'Idade: ${_calcularIdade(dados['dataNascimento'])}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 40),

                const Text(
                  "Genealogia / Pais:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _paisController,
                  decoration: const InputDecoration(
                    hintText: 'Informe os pais do animal',
                    suffixIcon: Icon(Icons.edit, size: 20),
                  ),
                  onSubmitted: (valor) => _atualizarCampo('pais', valor),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Histórico de Filhos:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  dados['filhos'] ?? "Nenhum filho registrado até o momento.",
                  style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Produção de Leite Deste Mês (Litros):",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _leiteController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Ex: 450',
                    suffixText: 'L',
                  ),
                  onSubmitted: (valor) => _atualizarCampo('producao_leite_mes', valor),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Área de Observações:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _obsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Escreva anotações importantes sobre o gado...',
                  ),
                  onSubmitted: (valor) => _atualizarCampo('observacoes', valor),
                ),

                const SizedBox(height: 30),

                _gerarSugestaoDescarte(producaoMedia, partosFalhos),

                const SizedBox(height: 30),

                const Text(
                  "Gráfico de Índices Zootécnicos:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 160,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          color: Colors.green,
                          value: partosSucesso.toDouble(),
                          title: '$partosSucesso',
                          radius: 50,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PieChartSectionData(
                          color: Colors.red,
                          value: partosFalhos.toDouble(),
                          title: '$partosFalhos',
                          radius: 50,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PieChartSectionData(
                          color: Colors.blue,
                          value: producaoMedia <= 0 ? 1 : producaoMedia,
                          title: '${producaoMedia.toStringAsFixed(1)}L',
                          radius: 50,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _construirLegenda(Colors.green, "Partos Sucesso"),
                    _construirLegenda(Colors.red, "Partos Falhos"),
                    _construirLegenda(Colors.blue, "Prod. Média"),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _construirLegenda(Color cor, String texto) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}