import 'package:flutter/material.dart';

class PoliticaPrivacidade extends StatefulWidget {
  const PoliticaPrivacidade({super.key});

  @override
  State<PoliticaPrivacidade> createState() => _PoliticaPrivacidadeState();
}

class _PoliticaPrivacidadeState extends State<PoliticaPrivacidade> {
  final ScrollController _scrollController = ScrollController();

  bool _chegouAoFinal = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_verificarFinal);
  }

  void _verificarFinal() {
    if (!_scrollController.hasClients) {
      return;
    }

    final posicaoAtual = _scrollController.position.pixels;
    final tamanhoTotal = _scrollController.position.maxScrollExtent;

    if (posicaoAtual >= tamanhoTotal - 50 && !_chegouAoFinal) {
      setState(() {
        _chegouAoFinal = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_verificarFinal);
    _scrollController.dispose();
    super.dispose();
  }

  void _confirmarLeitura() {
    if (!_chegouAoFinal) {
      return;
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF3E8),

      appBar: AppBar(
        title: const Text(
          'Política de Privacidade',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),

              child: Container(
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),

                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Center(
                      child: Icon(
                        Icons.privacy_tip,
                        size: 70,
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Center(
                      child: Text(
                        'POLÍTICA DE PRIVACIDADE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Center(
                      child: Text(
                        'Meu Rebanho Leiteiro',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Center(
                      child: Text(
                        'Versão 1.0',
                        style: TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    _titulo('1. Apresentação'),

                    _texto(
                      'Esta Política de Privacidade explica como o aplicativo '
                          'Meu Rebanho Leiteiro realiza o tratamento das informações '
                          'fornecidas pelos usuários durante a utilização do sistema. '
                          'O aplicativo foi desenvolvido como uma ferramenta de apoio '
                          'ao gerenciamento de rebanhos leiteiros, permitindo o '
                          'registro e acompanhamento de informações relacionadas aos '
                          'animais e à propriedade rural.',
                    ),

                    _titulo('2. Dados tratados'),

                    _texto(
                      'Durante o cadastro e utilização do aplicativo, poderão '
                          'ser tratados dados fornecidos pelo próprio usuário, '
                          'incluindo nome, endereço de e-mail, senha de acesso, '
                          'data de nascimento, propriedade, cidade, estado e tipo '
                          'de usuário.',
                    ),

                    _texto(
                      'Também poderão ser armazenadas informações relacionadas '
                          'ao gerenciamento do rebanho, como dados de identificação '
                          'dos animais, informações produtivas, reprodutivas, '
                          'sanitárias, registros de inseminação, acompanhamento de '
                          'prenhez, histórico e demais informações inseridas pelo '
                          'usuário durante a utilização do aplicativo.',
                    ),

                    _titulo('3. Finalidade do tratamento'),

                    _texto(
                      'As informações são utilizadas para permitir a criação '
                          'e manutenção da conta do usuário, autenticação de acesso, '
                          'funcionamento das funcionalidades do aplicativo e '
                          'gerenciamento das informações relacionadas ao rebanho.',
                    ),

                    _texto(
                      'Os dados do rebanho são utilizados para possibilitar '
                          'o cadastro, organização, consulta, acompanhamento e '
                          'histórico dos animais e de seus respectivos registros.',
                    ),

                    _titulo('4. Autenticação da conta'),

                    _texto(
                      'A autenticação dos usuários é realizada por meio do '
                          'Firebase Authentication. O serviço é utilizado para '
                          'criar e autenticar as contas utilizadas para acesso '
                          'ao aplicativo.',
                    ),

                    _texto(
                      'A senha utilizada para autenticação não é armazenada '
                          'diretamente pelo aplicativo como texto disponível para '
                          'consulta. O processo de autenticação é realizado pelo '
                          'serviço utilizado pelo sistema.',
                    ),

                    _titulo('5. Armazenamento e sincronização'),

                    _texto(
                      'Os dados utilizados pelo aplicativo poderão ser '
                          'armazenados no Firebase Cloud Firestore, serviço utilizado '
                          'para armazenamento e sincronização das informações.',
                    ),

                    _texto(
                      'O aplicativo também poderá utilizar armazenamento local '
                          'para permitir determinadas funcionalidades quando o '
                          'dispositivo estiver sem conexão com a internet. Quando '
                          'a conexão estiver disponível novamente, os dados poderão '
                          'ser sincronizados com os serviços utilizados pelo sistema.',
                    ),

                    _titulo('6. Funcionamento offline'),

                    _texto(
                      'O funcionamento offline tem como objetivo permitir que '
                          'determinadas informações possam ser consultadas ou '
                          'registradas mesmo em locais com conectividade limitada.',
                    ),

                    _texto(
                      'Durante períodos sem conexão, algumas informações poderão '
                          'permanecer temporariamente armazenadas no dispositivo até '
                          'que a sincronização possa ser realizada.',
                    ),

                    _titulo('7. Google Agenda'),

                    _texto(
                      'O aplicativo poderá disponibilizar uma integração opcional '
                          'com o Google Agenda para auxiliar o usuário na criação de '
                          'lembretes relacionados às atividades registradas no sistema, '
                          'como a verificação de prenhez.',
                    ),

                    _texto(
                      'A utilização dessa integração é opcional e não é necessária '
                          'para utilizar as demais funcionalidades do Meu Rebanho '
                          'Leiteiro.',
                    ),

                    _texto(
                      'O usuário não precisa utilizar uma Conta Google para '
                          'criar ou utilizar sua conta no Meu Rebanho Leiteiro. '
                          'Quando optar por utilizar o Google Agenda, poderá ser '
                          'direcionado ao serviço correspondente, que poderá solicitar '
                          'autenticação de acordo com as configurações da conta e '
                          'do dispositivo.',
                    ),

                    _texto(
                      'O Meu Rebanho Leiteiro não solicita nem armazena a senha '
                          'da Conta Google do usuário.',
                    ),

                    _titulo('8. Serviços de terceiros'),

                    _texto(
                      'O aplicativo utiliza serviços de terceiros necessários '
                          'para determinadas funcionalidades, incluindo serviços '
                          'relacionados à autenticação, armazenamento e sincronização '
                          'dos dados.',
                    ),

                    _texto(
                      'Esses serviços possuem suas próprias políticas e condições '
                          'de utilização. O tratamento realizado diretamente por '
                          'esses provedores está sujeito às respectivas políticas '
                          'de privacidade.',
                    ),

                    _titulo('9. Compartilhamento de informações'),

                    _texto(
                      'As informações dos usuários são utilizadas para o '
                          'funcionamento do aplicativo e poderão ser processadas '
                          'pelos provedores de serviços utilizados para autenticação, '
                          'armazenamento e funcionamento da aplicação.',
                    ),

                    _texto(
                      'O aplicativo não comercializa os dados pessoais dos '
                          'usuários.',
                    ),

                    _titulo('10. Segurança'),

                    _texto(
                      'São adotadas medidas técnicas e administrativas '
                          'compatíveis com a natureza das informações tratadas, '
                          'buscando proteger os dados contra acesso não autorizado, '
                          'perda, alteração, divulgação ou destruição indevida.',
                    ),

                    _texto(
                      'Apesar das medidas de segurança adotadas, nenhum sistema '
                          'eletrônico pode garantir segurança absoluta contra todos '
                          'os riscos existentes.',
                    ),

                    _titulo('11. Responsabilidade pelas informações'),

                    _texto(
                      'O usuário é responsável pelas informações que inserir '
                          'no aplicativo, devendo buscar manter os registros '
                          'corretos e atualizados.',
                    ),

                    _texto(
                      'As informações, cálculos, alertas e recursos de '
                          'acompanhamento disponibilizados pelo aplicativo possuem '
                          'finalidade de apoio ao gerenciamento do rebanho e não '
                          'substituem avaliação, diagnóstico, prescrição ou '
                          'orientação de profissionais habilitados, especialmente '
                          'em questões veterinárias, sanitárias ou produtivas.',
                    ),

                    _titulo('12. Direitos do titular'),

                    _texto(
                      'Nos termos da legislação aplicável, especialmente da '
                          'Lei nº 13.709/2018 (Lei Geral de Proteção de Dados '
                          'Pessoais - LGPD), o titular poderá exercer os direitos '
                          'previstos na legislação em relação aos seus dados pessoais, '
                          'observadas as hipóteses e limitações legais.',
                    ),

                    _texto(
                      'Entre esses direitos estão, conforme aplicável, a '
                          'confirmação da existência de tratamento, o acesso aos '
                          'dados, a correção de informações incompletas ou '
                          'desatualizadas e a eliminação de dados pessoais tratados '
                          'nas hipóteses previstas pela legislação.',
                    ),

                    _titulo('13. Exclusão da conta'),

                    _texto(
                      'O usuário poderá solicitar a exclusão de sua conta e '
                          'dos dados pessoais associados, observadas as obrigações '
                          'legais e as hipóteses que permitam ou exijam a conservação '
                          'de determinadas informações.',
                    ),

                    _texto(
                      'A exclusão da conta poderá resultar na perda de acesso '
                          'aos dados e informações armazenados no aplicativo.',
                    ),

                    _titulo('14. Dados de crianças e adolescentes'),

                    _texto(
                      'O aplicativo não é direcionado especificamente a crianças. '
                          'Caso sejam fornecidos dados pessoais de crianças ou '
                          'adolescentes, o tratamento deverá observar as disposições '
                          'legais aplicáveis e o melhor interesse desses titulares.',
                    ),

                    _titulo('15. Alterações desta Política'),

                    _texto(
                      'Esta Política de Privacidade poderá ser atualizada para '
                          'refletir alterações no aplicativo, nos serviços utilizados '
                          'ou nas exigências legais aplicáveis.',
                    ),

                    _texto(
                      'Quando houver alterações relevantes, uma nova versão '
                          'poderá ser apresentada ao usuário para ciência ou '
                          'aceite, conforme a natureza da alteração.',
                    ),

                    _titulo('16. Contato'),

                    _texto(
                      'Para dúvidas, solicitações relacionadas à privacidade '
                          'ou exercício de direitos previstos na legislação, o '
                          'usuário deverá utilizar o canal oficial de atendimento '
                          'disponibilizado pelo responsável pelo aplicativo.',
                    ),

                    const SizedBox(height: 12),

                    /**const Text(
                      'Canal de atendimento: [PREENCHER ANTES DA PUBLICAÇÃO]',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),**/

                    const SizedBox(height: 24),

                    const Divider(),

                    const SizedBox(height: 16),

                    const Center(
                      child: Text(
                        'Última atualização: [23/09/2026]',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),

          // Botão inferior
          Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20,
            ),

            color: Colors.white,

            child: SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton(
                onPressed:
                _chegouAoFinal ? _confirmarLeitura : null,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,

                  disabledBackgroundColor:
                  Colors.grey.shade300,

                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                ),

                child: Text(
                  _chegouAoFinal
                      ? 'LI E ESTOU CIENTE'
                      : 'LEIA ATÉ O FINAL PARA CONTINUAR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _chegouAoFinal
                        ? Colors.white
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _titulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 18,
        bottom: 8,
      ),

      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _texto(String texto) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),

      child: Text(
        texto,
        textAlign: TextAlign.justify,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Colors.black87,
        ),
      ),
    );
  }
}