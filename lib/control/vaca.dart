import 'package:flutter/material.dart';
import '../models/vaca_model.dart';

class VacaController extends ChangeNotifier {
  List<Vaca> _vacas = [];

  List<Vaca> get vacas => _vacas;

  Future<void> buscarTodasVacas() async {
    notifyListeners();
  }

  Future<void> adicionarVaca(Vaca novaVaca) async {
    _vacas.add(novaVaca);
    notifyListeners();
  }

  Future<void> deletarVaca(int id) async {
    _vacas.removeWhere((vaca) => vaca.id == id);
    notifyListeners();
  }

  Future<void> atualizarVaca(Vaca vacaEditada) async {
    final index = _vacas.indexWhere((v) => v.id == vacaEditada.id);
    if (index >= 0) {
      _vacas[index] = vacaEditada;
      notifyListeners();
    }
  }
}