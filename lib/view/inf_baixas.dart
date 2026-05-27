import 'package:flutter/material.dart';

class InfBaixas extends StatefulWidget {
  final Map<String, String> vaca;

  const InfBaixas({super.key, required this.vaca});

  @override
  State<InfBaixas> createState() => _InfBaixasState();
}

class _InfBaixasState extends State<InfBaixas> {
  bool _emEdicao = false;
  late TextEditingController _nomeController;
  late TextEditingController _brincoController;
  late TextEditingController _motivoController;
  late TextEditingController _obsController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.vaca['nome']);
    _brincoController = TextEditingController(text: widget.vaca['id']);
    _motivoController = TextEditingController(text: widget.vaca['motivo']);
    _obsController = TextEditingController(text: widget.vaca['observacao']);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _brincoController.dispose();
    _motivoController.dispose();
    _obsController.dispose();
    super.dispose();
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
            icon: Icon(_emEdicao ? Icons.save : Icons.edit, color: Colors.white),
            onPressed: () {
              setState(() {
                _emEdicao = !_emEdicao;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white, size: 30),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(widget.vaca['foto'] ?? 'https://via.placeholder.com/150'),
              ),
            ),
            const SizedBox(height: 25),
            _construirCampoInfo(
              rotulo: "Nome da Vaca",
              controlador: _nomeController,
              habilitado: _emEdicao,
            ),
            _construirCampoInfo(
              rotulo: "Brinco (Número/ID)",
              controlador: _brincoController,
              habilitado: _emEdicao,
            ),
            _construirCampoInfo(
              rotulo: "Motivo da Baixa",
              controlador: _motivoController,
              habilitado: _emEdicao,
            ),
            _construirCampoInfo(
              rotulo: "Observações",
              controlador: _obsController,
              habilitado: _emEdicao,
              linhasMaximas: 4,
            ),
            if (_emEdicao) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text("SALVAR ALTERAÇÕES", style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    setState(() {
                      _emEdicao = false;
                    });
                  },
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _construirCampoInfo({
    required String rotulo,
    required TextEditingController controlador,
    required bool habilitado,
    int linhasMaximas = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controlador,
        enabled: habilitado,
        maxLines: linhasMaximas,
        style: TextStyle(
          fontSize: 16,
          color: habilitado ? Colors.black : Colors.black87,
          fontWeight: habilitado ? FontWeight.normal : FontWeight.bold,
        ),
        decoration: InputDecoration(
          labelText: rotulo,
          labelStyle: const TextStyle(color: Colors.brown),
          disabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.brown)),
        ),
      ),
    );
  }
}