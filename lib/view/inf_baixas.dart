import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InfBaixas extends StatefulWidget {
  final Map<String, String> vaca;

  const InfBaixas({super.key, required this.vaca});

  @override
  State<InfBaixas> createState() => _InfBaixasState();
}

class _InfBaixasState extends State<InfBaixas> {
  bool _emEdicao = false;
  bool _restaurando = false;
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


  Future<void> _confirmarRestauracao() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar a baixa?'),
        content: Text(
          'Confirma que a baixa de ${widget.vaca['nome'] ?? 'este animal'} foi registrada por engano ou que a venda foi cancelada? '
          'O animal voltará a aparecer nas telas e nos gráficos do rebanho ativo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Não, manter baixa'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sim, cancelar baixa'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final usuarioId = FirebaseAuth.instance.currentUser?.uid;
    final vacaId = widget.vaca['vacaId'];

    if (usuarioId == null || vacaId == null || vacaId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível identificar o animal ou o usuário.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _restaurando = true);

    try {
      final referencia =
          FirebaseFirestore.instance.collection('vacas').doc(vacaId);
      final documento = await referencia.get();

      if (!documento.exists || documento.data()?['usuarioId'] != usuarioId) {
        throw Exception('Animal não encontrado na sua conta.');
      }

      await referencia.update({
        'baixado': false,
        'motivoBaixa': FieldValue.delete(),
        'observacaoBaixa': FieldValue.delete(),
        'dataBaixa': FieldValue.delete(),
        'dataAtualizacao': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Baixa cancelada. O animal voltou ao rebanho ativo.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível cancelar a baixa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _restaurando = false);
    }
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                ((widget.vaca['tipoAnimal'] ?? '').toLowerCase().contains('touro') ||
                        (widget.vaca['tipoAnimal'] ?? '').toLowerCase().contains('macho'))
                    ? 'assets/img/touro.png'
                    : 'assets/img/animal.png',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
                color: Colors.brown,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.pets, size: 72, color: Colors.brown),
              ),
            ),
            const SizedBox(height: 25),
            _construirCampoInfo(
              rotulo: "Nome do animal",
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
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                ),
                icon: _restaurando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.undo),
                label: const Text('CANCELAR BAIXA / REGISTRADA POR ENGANO'),
                onPressed: _restaurando ? null : _confirmarRestauracao,
              ),
            )
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