import 'package:flutter/material.dart';

class FormularioBaixas extends StatefulWidget {
  const FormularioBaixas({super.key});

  @override
  State<FormularioBaixas> createState() => _FormularioBaixasState();
}

class _FormularioBaixasState extends State<FormularioBaixas> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _brincoController = TextEditingController();
  final TextEditingController _idadeController = TextEditingController();
  final TextEditingController _obsController = TextEditingController();
  String? _situacao = 'Vendida';

  @override
  void dispose() {
    _nomeController.dispose();
    _brincoController.dispose();
    _idadeController.dispose();
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
            icon: const Icon(Icons.account_circle, color: Colors.white, size: 30),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Registrar Baixa de Animal",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome da Vaca',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.brown)),
                ),
                validator: (value) => value!.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _brincoController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Brinco (Número/ID)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.brown)),
                ),
                validator: (value) => value!.isEmpty ? 'Informe o número do brinco' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _idadeController,
                decoration: InputDecoration(
                  labelText: 'Idade (Ex: 4 anos)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.brown)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Motivo da Baixa:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown),
              ),
              Row(
                children: [
                  Radio<String>(
                    value: 'Vendida',
                    groupValue: _situacao,
                    activeColor: Colors.brown,
                    onChanged: (value) {
                      setState(() {
                        _situacao = value;
                      });
                    },
                  ),
                  const Text('Vendida', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 30),
                  Radio<String>(
                    value: 'Morreu',
                    groupValue: _situacao,
                    activeColor: Colors.brown,
                    onChanged: (value) {
                      setState(() {
                        _situacao = value;
                      });
                    },
                  ),
                  const Text('Morreu', style: TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _obsController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Observações Adicionais',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.brown)),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Map<String, String> novaVaca = {
                        'nome': _nomeController.text,
                        'id': _brincoController.text,
                        'motivo': _situacao ?? 'Vendida',
                        'observacao': _obsController.text,
                        'foto': 'https://via.placeholder.com/150',
                      };
                      Navigator.pop(context, novaVaca);
                    }
                  },
                  child: const Text(
                    "SALVAR",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}