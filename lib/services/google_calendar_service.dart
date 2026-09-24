import 'package:url_launcher/url_launcher.dart';

class GoogleCalendarService {
  static DateTime? converterDataBrasileira(
      String data,
      ) {
    try {
      final partes = data.split('/');

      if (partes.length != 3) {
        return null;
      }

      final dia = int.parse(partes[0]);
      final mes = int.parse(partes[1]);
      final ano = int.parse(partes[2]);

      return DateTime(
        ano,
        mes,
        dia,
      );
    } catch (e) {
      return null;
    }
  }

  static String _formatarDataGoogle(
      DateTime data,
      ) {
    String doisDigitos(int valor) =>
        valor.toString().padLeft(2, '0');

    final ano = data.year.toString();
    final mes = doisDigitos(data.month);
    final dia = doisDigitos(data.day);
    final hora = doisDigitos(data.hour);
    final minuto = doisDigitos(data.minute);
    final segundo = doisDigitos(data.second);

    return '$ano$mes${dia}T$hora$minuto$segundo';
  }

  static Future<void> abrirEventoNoGoogleAgenda({
    required String titulo,
    required String descricao,
    required DateTime dataInicio,
    Duration duracao =
    const Duration(minutes: 30),
    String local = '',
  }) async {
    final dataFim =
    dataInicio.add(duracao);

    final uri = Uri.https(
      'calendar.google.com',
      '/calendar/render',
      {
        'action': 'TEMPLATE',
        'text': titulo,
        'dates':
        '${_formatarDataGoogle(dataInicio)}/${_formatarDataGoogle(dataFim)}',
        'details': descricao,
        'location': local,
      },
    );

    final abriu = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!abriu) {
      throw Exception(
        'Não foi possível abrir o Google Agenda.',
      );
    }
  }

  static Future<void>
  criarLembreteVerificacaoPrenhez({
    required String nomeVaca,
    required String brinco,
    required String dataInseminacao,
    String touro = '',
  }) async {
    final dataConvertida =
    converterDataBrasileira(
      dataInseminacao,
    );

    if (dataConvertida == null) {
      throw Exception(
        'Data de inseminação inválida.',
      );
    }

    final dataLembrete =
    dataConvertida.add(
      const Duration(days: 45),
    );

    final dataComHorario = DateTime(
      dataLembrete.year,
      dataLembrete.month,
      dataLembrete.day,
      9,
      0,
    );

    await abrirEventoNoGoogleAgenda(
      titulo:
      'Verificação de prenhez - $nomeVaca',
      descricao:
      'Realizar verificação de prenhez da vaca '
          '$nomeVaca, brinco $brinco. '
          'Data da inseminação: '
          '$dataInseminacao. '
          '${touro.isNotEmpty ? 'Touro/Sêmen utilizado: $touro.' : ''}',
      dataInicio: dataComHorario,
      local: 'Propriedade rural',
    );
  }
}