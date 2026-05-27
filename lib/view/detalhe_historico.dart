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

  String _calcularIdade(String? dataNascimento) {
    if (dataNascimento == null || dataNascimento.isEmpty) return "Não informada";
    try {
      DateTime nascimento = DateTime.parse(dataNascimento);
      DateTime hoje = DateTime.now();
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

  Widget _gerarSugestaoDescarte(double producaoMedia, int partosFalhos) {
    bool manter = producaoMedia >= 15.0 && partosFalhos <= 1;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: manter ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: manter ? Colors.green : Colors.red),
      ),
      child: Row(
        children: [
          Icon(manter ? Icons.check_circle : Icons.warning, color: manter ? Colors.green : Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              manter
                  ? "Sugestão: MANTER NO REBANHO. Alta produtividade média de leite e boa saúde reprodutiva."
                  : "Sugestão: AVALIAR DESCARTE. Baixa produção leiteira recente ou histórico de partos falhos.",
              style: TextStyle(fontWeight: FontWeight.bold, color: manter ? Colors.green.shade900 : Colors.red.shade900),
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
        backgroundColor: Colors.brown,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white, size: 30),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('vacas').doc(widget.vacaId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.brown));
          }

          var dados = snapshot.data!.data() as Map<String, dynamic>;

          _paisController.text = dados['pais'] ?? '';
          _leiteController.text = dados['producao_leite_mes'] ?? '';
          _obsController.text = dados['observacoes'] ?? '';

          int partosSucesso = dados['partos_sucesso'] ?? 4;
          int partosFalhos = dados['partos_falhos'] ?? 1;
          double producaoMedia = double.tryParse(_leiteController.text) ?? 12.5;

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
                        backgroundImage: NetworkImage(dados['foto'] ?? 'https://via.placeholder.com/150'),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        dados['nome'] ?? 'Sem Nome',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown),
                      ),
                      Text('Brinco Nº: ${dados['id'] ?? 'N/A'}', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                      Text('Idade: ${_calcularIdade(dados['data_nascimento'])}', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                const Divider(height: 40),
                const Text("Genealogia / Pais:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown)),
                const SizedBox(height: 5),
                TextField(
                  controller: _paisController,
                  decoration: const InputDecoration(
                    hintText: 'Informe os Pais do animal (Mãe / Touro PAI)',
                    suffixIcon: Icon(Icons.edit, size: 20),
                  ),
                  onSubmitted: (val) {
                    FirebaseFirestore.instance.collection('vacas').doc(widget.vacaId).update({'pais': val});
                  },
                ),
                const SizedBox(height: 20),
                const Text("Histórico de Filhos (Vindo da Prenhez):", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown)),
                const SizedBox(height: 5),
                Text(
                  dados['filhos'] ?? "Nenhum filho registrado até o momento.",
                  style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 20),
                const Text("Produção de Leite Deste Mês (Litros):", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown)),
                const SizedBox(height: 5),
                TextField(
                  controller: _leiteController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Ex: 450',
                    suffixText: 'L',
                  ),
                  onSubmitted: (val) {
                    FirebaseFirestore.instance.collection('vacas').doc(widget.vacaId).update({'producao_leite_mes': val});
                  },
                ),
                const SizedBox(height: 20),
                const Text("Área de Observações:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown)),
                const SizedBox(height: 5),
                TextField(
                  controller: _obsController,
                  maxLines: 2,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Escreva anotações importantes sobre o gado...'),
                  onSubmitted: (val) {
                    FirebaseFirestore.instance.collection('vacas').doc(widget.vacaId).update({'observacoes': val});
                  },
                ),
                const SizedBox(height: 30),
                const Text("Gráfico de Índices Zootécnicos:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown)),
                const SizedBox(height: 15),
                SizedBox(
                  height: 160,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(color: Colors.green, value: partosSucesso.toDouble(), title: '$partosSucesso', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        PieChartSectionData(color: Colors.red, value: partosFalhos.toDouble(), title: '$partosFalhos', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        PieChartSectionData(color: Colors.blue, value: producaoMedia, title: '${producaoMedia.toStringAsFixed(1)}L', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    _construirLegenda(Colors.blue, "Prod. Média (L)"),
                  ],
                ),
                const SizedBox(height: 35),
                _gerarSugestaoDescarte(producaoMedia, partosFalhos),
                const SizedBox(height: 20),
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
        Container(width: 14, height: 14, decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(texto, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}