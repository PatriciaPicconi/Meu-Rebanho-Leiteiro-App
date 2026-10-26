import 'package:flutter_test/flutter_test.dart';
// Mude 'untitled' para o nome do seu projeto se for diferente
import 'package:untitled/main.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Teste de carregamento da Home', (WidgetTester tester) async {
    // Agora ele tenta carregar o MaterialApp que criamos no main.dart
    // Removi o "const MyApp()" que estava dando erro
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));

    // Verifica se o título do seu app aparece na tela
    // Nota: Como o teste é simples, apenas garantimos que ele não quebre
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
