// Arquivo: lib/screens/settings_screen.dart
// VERSÃO FINAL: Redesenhada com novo estilo e lógica atualizada.

import 'package:flutter/material.dart';
import 'package:educsa/screens/legal_screen.dart'; // Importa a tela de documentos legais

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Cores do tema
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color accentColor = Color(0xFF8B5CF6);
  static const Color backgroundColor = Color(0xFFF8FAFC);

  // Método para navegar para a tela de documentos legais
  void _showLegalScreen(BuildContext context, String type) {
    String title = "";
    String content = "";

    if (type == "terms") {
      title = "Termos de Uso";
      content = '''
TERMOS DE USO

VISÃO GERAL

1.  O EduCSA é uma plataforma digital (web e mobile) cujos direitos pertencem ao Colégio Santo Antônio. O objetivo principal é facilitar e melhorar a gestão da comunicação e do engajamento no ambiente educacional, auxiliando os usuários (educadores, responsáveis e alunos) em sua jornada.

CONSIDERAÇÕES GERAIS

2.  Os presentes Termos de Uso são aplicáveis aos serviços prestados pelo Colégio Santo Antônio (aqui referido como "Instituição"), sociedade empresária inscrita no CNPJ sob o nº [10.894.861/0001-14], em relação a seus usuários da plataforma (web e mobile), tanto educadores quanto responsáveis e alunos.
3.  Para que o usuário possa usufruir dos serviços ofertados pelo EduCSA, deverá ler minuciosamente e, por meio do clique no botão “LI E ACEITO OS TERMOS”, declarar que, antes mesmo de cadastrar-se, entendeu e aceitou os termos estabelecidos no presente documento, bem como na Política de Privacidade.
4.  Somente serão validados os cadastros na plataforma realizados por pessoas físicas que possuam plena capacidade civil, ou por aquelas que, não a possuindo plenamente, realizem o cadastro devidamente assistidas por seu responsável. Pessoas jurídicas poderão se cadastrar por meio de seus representantes legais, sem prejuízo das sanções civis previstas no Código Civil (Lei nº 10.406/2002).

CADASTRO

5.  O cadastro para utilização da plataforma deverá ser efetuado através do aplicativo EduCSA, com o devido preenchimento do formulário, apresentando os dados pertinentes e a respectiva autorização para uso destes, conforme disposições do documento “Política de Privacidade”, reservando-se à Instituição a faculdade de suspender ou cancelar cadastros de usuários que violem estes Termos de Uso.
6.  O cadastro é formal e materialmente válido apenas para usuários residentes e domiciliados em território brasileiro, tendo em vista que o serviço ofertado pelo EduCSA envolve apenas estabelecimentos do referido país.
7.  O usuário garante a veracidade e a exatidão dos dados pessoais que forneça no momento do cadastro, pelo que assume a sua inteira responsabilidade. A Instituição não se responsabiliza por incongruência dos dados pessoais introduzidos pelo usuário no referido cadastro.

CONDIÇÕES DE USO

8.  O EduCSA atua como intermediador na comunicação entre os usuários (educadores, responsáveis e alunos). Por essa razão, a Instituição não se responsabiliza pelas relações estabelecidas entre usuários, sendo da respectiva parte a inteira responsabilidade pelas informações inseridas na plataforma e por sua veracidade.
9.  É dever dos usuários, na utilização da plataforma, sempre seguir a boa-fé nas relações civis, respeitando a legislação vigente. Não é permitido:
    * Divulgar conteúdo ou praticar qualquer ato que infrinja ou viole os direitos de terceiros ou a lei;
    * Divulgar materiais ofensivos, pornográficos, ou que promovam ou façam apologia a terrorismo, violência ou qualquer forma de discriminação, seja racial, sexual, de origem, religiosa, ou que, mesmo de outras formas, atente contra direitos humanos;
    * Divulgar documentos de identificação ou informações financeiras confidenciais de terceiros.
10. O acesso à plataforma (web e mobile) depende de login e senha, que são pessoais e intransferíveis, sendo o usuário o único responsável por sua guarda e uso.
''';
    } else {
      title = "Políticas de Privacidade";
      content = '''
POLÍTICA DE PRIVACIDADE E SEGURANÇA

1.  A Política de Privacidade e Segurança do EduCSA garante segurança e privacidade de identidade aos usuários que forneçam suas informações ao sistema (web e mobile) e site. Dados pessoais cadastrados são protegidos por sistemas avançados de criptografia.
2.  A plataforma pertencente ao Colégio Santo Antônio adota os níveis legalmente requeridos quanto à segurança na proteção de dados, com respectiva utilização de todos os meios e medidas técnicas para inibição da perda, mau uso, alteração, acesso não autorizado ou subtração indevida dos dados pessoais recolhidos. Não obstante, o usuário deve estar ciente de que as medidas de segurança relativas à Internet não são integralmente infaliveis.
3.  A presente empresa reserva-se ao direito de modificar a Política para adaptá-la a alterações legislativas ou jurisprudenciais, ou àquelas relativas às práticas comerciais. Em qualquer caso, as mudanças serão anunciadas por meio do seu site ou aplicativo, sendo as mudanças introduzidas com uma antecedência razoável a sua colocação em prática.
4.  Importante salientar que o site poderá fornecer acesso a links para outros sites externos cujos conteúdos e Políticas de Privacidade, bem como segurança da informação, não são de responsabilidade do Colégio Santo Antônio. Dessa forma, recomenda-se aos usuários que, ao serem redirecionados para sites externos, consultem sempre as respectivas Políticas de Privacidade antes de fornecer seus dados.
5.  Nas hipóteses em que houver integração da plataforma pertencente ao Colégio Santo Antônio com outros servidores ou plataformas externas, por exemplo nas integrações com Google Calendar ou com Google Drive, os dados e/ou arquivos somente serão compartilhados com o prévio consentimento e a autorização do usuário. Além disso, os dados sensíveis informados para aquelas plataformas externas não serão mantidos pelo EduCSA, ocorrendo a integração apenas de dados ou arquivos previamente autorizados.
6.  Os usuários poderão exercer os direitos de acesso e de retificação dos seus dados, bem como têm reconhecido o direito de obterem informações através do e-mail [csaagrestina@gmail.com].

COLETA DAS INFORMAÇÕES

7.  Ao se cadastrar, os usuários determinam voluntariamente que desejam fornecer os seus dados pessoais requeridos.
8.  Os dados dos usuários também poderão ser coletados por meio da integração de plataformas externas com a plataforma pertencente ao CSApp, por meio da autorização e do consentimento do usuário em compartilhar, por exemplo, seus dados e arquivos constantes nas plataformas Google Drive, Google Calendar, dentre outros. Nesses casos, usaremos suas Credenciais Google (Google Credentials) para sua autenticação e, assim, possibilitar a integração das plataformas.
9.  Os dados recolhidos serão objeto de tratamento automatizado, sendo incorporados aos correspondentes registros eletrônicos de dados pessoais, dos quais o Colégio Santo Antônio será titular e responsável. As informações obtidas e utilizadas por esta fazem parte dessa Política.

UTILIZAÇÃO DAS INFORMAÇÕES

10. As informações pessoais fornecidas pelos usuários são utilizadas com o propósito básico de identificar o público usuário e seu respectivo perfil, para gestão (business intelligence), administração, atendimento, ampliação e melhorias nos produtos e serviços oferecidos; também para a adequação dos serviços às preferências e anseios dos usuários, para a criação de novos produtos e serviços e para o envio de informações operacionais e comerciais relativas aos produtos e serviços, por meios tradicionais e/ou eletrônicos.
11. Compromisso do Colégio Santo Antônio:
    a) corrigir prontamente quaisquer alterações relativas aos dados pessoais do usuário. Para tanto, este sempre deverá informar as mudanças nos respectivos dados;
    b) possibilitar ao usuário o cancelamento, a qualquer momento, do envio por e-mail de material informativo.
''';
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LegalScreen(title: title, content: content),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ primaryColor, accentColor ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Geral", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                        const SizedBox(height: 16),
                        _buildOptionTile(
                          icon: Icons.notifications_rounded,
                          title: 'Notificações',
                          subtitle: 'Gerencie os alertas do app',
                          onTap: () {
                            // Lógica para a tela de notificações pode ser adicionada aqui
                          },
                        ),
                        const SizedBox(height: 24),
                        const Text("Legal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                        const SizedBox(height: 16),
                        _buildOptionTile(
                          icon: Icons.description_rounded,
                          title: 'Termos de Uso',
                          subtitle: 'Leia os termos de serviço',
                          onTap: () => _showLegalScreen(context, "terms"),
                        ),
                        _buildOptionTile(
                          icon: Icons.privacy_tip_rounded,
                          title: 'Políticas de Privacidade',
                          subtitle: 'Entenda como usamos seus dados',
                          onTap: () => _showLegalScreen(context, "privacy"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Configurações', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Ajustes e informações', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({required IconData icon, required String title, required String subtitle, VoidCallback? onTap, Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: color ?? primaryColor, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
                      Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
