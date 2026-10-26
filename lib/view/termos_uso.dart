import 'package:flutter/material.dart';

class TermosUso extends StatefulWidget {
  const TermosUso({super.key});

  @override
  State<TermosUso> createState() => _TermosUsoState();
}

class _TermosUsoState extends State<TermosUso> {
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
          'Termos de Uso',
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
                        Icons.description,
                        size: 70,
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Center(
                      child: Text(
                        'TERMOS DE USO',
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

                    _titulo('1. Sobre o aplicativo'),

                    _texto(
                      'O Meu Rebanho Leiteiro é um aplicativo desenvolvido '
                          'para auxiliar no gerenciamento de rebanhos leiteiros, '
                          'permitindo ao usuário registrar, organizar e consultar '
                          'informações relacionadas aos animais e à propriedade '
                          'rural.',
                    ),

                    _texto(
                      'O aplicativo possui finalidade de apoio à gestão e '
                          'organização das informações do rebanho, não substituindo '
                          'sistemas oficiais, profissionais especializados ou '
                          'serviços de assistência técnica e veterinária.',
                    ),

                    _titulo('2. Aceitação dos Termos'),

                    _texto(
                      'Ao criar uma conta e utilizar o Meu Rebanho Leiteiro, '
                          'o usuário declara que leu, compreendeu e concorda com '
                          'estes Termos de Uso e com a Política de Privacidade '
                          'do aplicativo.',
                    ),

                    _texto(
                      'Caso o usuário não concorde com estes Termos de Uso, '
                          'não deverá concluir o cadastro ou utilizar as '
                          'funcionalidades do aplicativo.',
                    ),

                    _titulo('3. Criação e utilização da conta'),

                    _texto(
                      'Para utilizar determinadas funcionalidades do aplicativo, '
                          'o usuário deverá criar uma conta fornecendo informações '
                          'solicitadas no processo de cadastro.',
                    ),

                    _texto(
                      'O usuário é responsável por fornecer informações '
                          'verdadeiras, completas e atualizadas durante o cadastro '
                          'e durante a utilização do aplicativo.',
                    ),

                    _texto(
                      'A conta é de uso pessoal e o usuário deve manter suas '
                          'credenciais de acesso protegidas, não devendo compartilhar '
                          'sua senha com terceiros.',
                    ),

                    _titulo('4. Uso adequado do aplicativo'),

                    _texto(
                      'O usuário deverá utilizar o aplicativo de forma '
                          'responsável e de acordo com sua finalidade, respeitando '
                          'a legislação aplicável e os direitos de terceiros.',
                    ),

                    _texto(
                      'É proibido utilizar o aplicativo para atividades ilícitas, '
                          'fraudulentas, para tentativa de acesso não autorizado a '
                          'contas ou sistemas, ou para qualquer finalidade que possa '
                          'prejudicar o funcionamento do serviço ou outros usuários.',
                    ),

                    _titulo('5. Informações inseridas pelo usuário'),

                    _texto(
                      'O usuário é responsável pelas informações que inserir '
                          'no aplicativo, incluindo os dados relacionados aos '
                          'animais, registros produtivos, reprodutivos, sanitários '
                          'e demais informações utilizadas para o gerenciamento '
                          'do rebanho.',
                    ),

                    _texto(
                      'O usuário deverá buscar manter os registros corretos e '
                          'atualizados para que as informações apresentadas pelo '
                          'sistema correspondam aos dados fornecidos.',
                    ),

                    _titulo('6. Funcionalidades e informações do sistema'),

                    _texto(
                      'O aplicativo disponibiliza funcionalidades destinadas '
                          'ao cadastro, organização, acompanhamento e consulta de '
                          'informações relacionadas ao rebanho leiteiro.',
                    ),

                    _texto(
                      'Determinadas funcionalidades podem realizar cálculos, '
                          'organizar informações, apresentar alertas ou auxiliar '
                          'o usuário no acompanhamento de atividades relacionadas '
                          'ao rebanho.',
                    ),

                    _titulo('7. Alertas, cálculos e recomendações'),

                    _texto(
                      'Os cálculos, alertas, previsões, informações e '
                          'recomendações apresentados pelo aplicativo possuem '
                          'finalidade de apoio ao gerenciamento do rebanho.',
                    ),

                    _texto(
                      'Esses recursos não constituem diagnóstico veterinário, '
                          'prescrição, tratamento, garantia de resultado ou '
                          'substituição da avaliação de profissional habilitado.',
                    ),

                    _texto(
                      'Em situações que envolvam saúde, reprodução, manejo '
                          'sanitário ou qualquer outra questão que exija avaliação '
                          'profissional, o usuário deverá buscar orientação de '
                          'profissional devidamente habilitado.',
                    ),

                    _titulo('8. Funcionamento offline'),

                    _texto(
                      'O aplicativo poderá disponibilizar determinadas '
                          'funcionalidades mesmo quando o dispositivo estiver '
                          'sem conexão com a internet.',
                    ),

                    _texto(
                      'Informações registradas durante períodos sem conexão '
                          'poderão permanecer temporariamente armazenadas no '
                          'dispositivo até que seja possível realizar a '
                          'sincronização.',
                    ),

                    _texto(
                      'A sincronização depende da disponibilidade de conexão '
                          'e dos serviços utilizados pelo aplicativo.',
                    ),

                    _titulo('9. Google Agenda'),

                    _texto(
                      'O aplicativo poderá disponibilizar uma integração '
                          'opcional com o Google Agenda para facilitar a criação '
                          'de lembretes relacionados às atividades registradas '
                          'no sistema.',
                    ),

                    _texto(
                      'A utilização do Google Agenda é opcional e não é '
                          'necessária para utilizar as demais funcionalidades '
                          'do Meu Rebanho Leiteiro.',
                    ),

                    _texto(
                      'O usuário não precisa possuir uma Conta Google para '
                          'criar ou utilizar sua conta no Meu Rebanho Leiteiro. '
                          'Caso opte pela integração com o Google Agenda, poderá '
                          'ser direcionado ao serviço do Google para realizar '
                          'a autenticação e confirmar o evento.',
                    ),

                    _texto(
                      'O Meu Rebanho Leiteiro não solicita nem armazena a '
                          'senha da Conta Google do usuário.',
                    ),

                    _titulo('10. Serviços de terceiros'),

                    _texto(
                      'O aplicativo utiliza serviços de terceiros para '
                          'determinadas funcionalidades, incluindo serviços '
                          'relacionados à autenticação, armazenamento, '
                          'sincronização e integração com serviços externos.',
                    ),

                    _texto(
                      'Os serviços de terceiros possuem seus próprios termos '
                          'e políticas. A utilização desses serviços poderá estar '
                          'sujeita às condições estabelecidas pelos respectivos '
                          'provedores.',
                    ),

                    _titulo('11. Disponibilidade do aplicativo'),

                    _texto(
                      'O aplicativo poderá passar por atualizações, '
                          'manutenções, correções ou alterações destinadas a '
                          'melhorar seu funcionamento e segurança.',
                    ),

                    _texto(
                      'Embora sejam adotadas medidas para manter o aplicativo '
                          'disponível, não é possível garantir funcionamento '
                          'ininterrupto ou ausência absoluta de falhas, especialmente '
                          'quando houver dependência de conexão com a internet, '
                          'serviços de terceiros ou condições do dispositivo.',
                    ),

                    _titulo('12. Dados e privacidade'),

                    _texto(
                      'O tratamento de dados pessoais realizado pelo '
                          'Meu Rebanho Leiteiro é explicado em sua Política de '
                          'Privacidade, que integra estes Termos de Uso para fins '
                          'de compreensão das condições de utilização do aplicativo.',
                    ),

                    _texto(
                      'Ao utilizar o aplicativo, o usuário declara estar '
                          'ciente das informações apresentadas na Política de '
                          'Privacidade.',
                    ),

                    _titulo('13. Propriedade intelectual'),

                    _texto(
                      'A estrutura, identidade visual, código-fonte, elementos '
                          'gráficos, textos e demais componentes desenvolvidos '
                          'especificamente para o Meu Rebanho Leiteiro estão '
                          'sujeitos à legislação aplicável de propriedade '
                          'intelectual.',
                    ),

                    _texto(
                      'O usuário não poderá copiar, modificar, distribuir, '
                          'comercializar ou utilizar indevidamente os elementos '
                          'do aplicativo para finalidade não autorizada, '
                          'ressalvadas as hipóteses permitidas pela legislação.',
                    ),

                    _titulo('14. Responsabilidade do usuário'),

                    _texto(
                      'O usuário é responsável pela utilização de sua conta, '
                          'pelas informações inseridas no sistema e pelas decisões '
                          'tomadas a partir dessas informações.',
                    ),

                    _texto(
                      'O aplicativo possui finalidade de apoio à organização '
                          'e gerenciamento do rebanho e não garante resultados '
                          'produtivos, reprodutivos, sanitários ou econômicos.',
                    ),

                    _titulo('15. Segurança da conta'),

                    _texto(
                      'O usuário deverá adotar medidas adequadas para proteger '
                          'seus dados de acesso, incluindo a utilização de senha '
                          'segura e a não divulgação de suas credenciais.',
                    ),

                    _texto(
                      'Caso identifique acesso não autorizado ou suspeite de '
                          'comprometimento de sua conta, o usuário deverá buscar '
                          'orientação pelo canal de atendimento disponibilizado '
                          'pelo aplicativo.',
                    ),

                    _titulo('16. Encerramento da conta'),

                    _texto(
                      'O usuário poderá solicitar o encerramento de sua conta '
                          'observadas as funcionalidades disponibilizadas pelo '
                          'aplicativo e as condições previstas na Política de '
                          'Privacidade.',
                    ),

                    _texto(
                      'O encerramento da conta poderá resultar na perda de '
                          'acesso às informações armazenadas no sistema.',
                    ),

                    _titulo('17. Alterações dos Termos'),

                    _texto(
                      'Estes Termos de Uso poderão ser atualizados para '
                          'refletir alterações nas funcionalidades do aplicativo, '
                          'nos serviços utilizados ou nas exigências legais '
                          'aplicáveis.',
                    ),

                    _texto(
                      'Quando houver alterações relevantes, uma nova versão '
                          'dos Termos poderá ser apresentada ao usuário para '
                          'leitura e concordância, quando necessário.',
                    ),

                    _titulo('18. Legislação aplicável'),

                    _texto(
                      'A utilização do aplicativo deverá observar a legislação '
                          'brasileira aplicável, incluindo, quando pertinente, '
                          'a Lei nº 13.709/2018 (Lei Geral de Proteção de Dados '
                          'Pessoais - LGPD) e demais normas aplicáveis.',
                    ),

                    _titulo('19. Contato'),

                    _texto(
                      'Dúvidas, solicitações ou comunicações relacionadas '
                          'a estes Termos de Uso poderão ser encaminhadas por '
                          'meio do canal oficial de atendimento disponibilizado '
                          'pelo responsável pelo aplicativo.',
                    ),

                    const SizedBox(height: 8),

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
                      ? 'LI E CONCORDO'
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