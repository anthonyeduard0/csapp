// Arquivo: lib/screens/settings_screen.dart
// VERSÃO FINAL: Redesenhada com novo estilo e lógica atualizada.
// ATUALIZADO: Gradiente de cores alterado para consistência visual.

import 'package:flutter/material.dart';
import 'package:educsa/screens/legal_screen.dart'; // Importa a tela de documentos legais

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Cores do tema
  static const Color primaryColor = Color(0xFF1D449B);
  static const Color accentColor = Color(0xFF25B6E8);
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
Política de Privacidade do Aplicativo EduCSA
Última atualização: 02 de setembro de 2025

Bem-vindo à Política de Privacidade do aplicativo EduCSA ("Aplicativo"), de propriedade e operado pelo Colégio Santo Antônio, inscrito no CNPJ sob o nº 10.894.861/0001-14 ("Instituição", "nós", "nosso").

Esta Política de Privacidade descreve como coletamos, usamos, armazenamos, compartilhamos e protegemos suas informações pessoais. Ao usar nosso Aplicativo, você concorda com a coleta e uso de informações de acordo com esta política.

1. Informações que Coletamos
Coletamos informações que você nos fornece diretamente para garantir o funcionamento do Aplicativo e a comunicação efetiva entre a comunidade escolar.

a) Informações de Cadastro do Responsável:

Dados de Identificação: Nome completo, CPF, endereço de e-mail e número de telefone.

Dados de Acesso: Senha de acesso (armazenada de forma criptografada).

b) Informações dos Alunos:

Dados de Identificação: Nome completo do aluno e sua respectiva série/ano.

Vínculo: As informações do aluno são sempre vinculadas ao seu responsável legal cadastrado.

c) Informações Financeiras:

Dados de Pagamento: Para processar os pagamentos de mensalidades via PIX, coletamos informações do pagador (nome, CPF) e dados da transação, que são gerenciados e processados de forma segura pelo nosso parceiro de pagamentos, o Mercado Pago. Nós não armazenamos dados bancários ou de cartão de crédito em nossos servidores.

d) Informações de Uso e Dispositivo:

Foto de Perfil: Opcionalmente, você pode nos fornecer uma foto de perfil para personalizar sua conta.

Interações: Podemos registrar quando você aceita os Termos de Uso e a data de aceite.

2. Como Usamos Suas Informações
As informações coletadas são utilizadas para as seguintes finalidades:

Fornecer e Gerenciar Nossos Serviços: Autenticar seu acesso, identificar você e seus alunos vinculados, e exibir as informações financeiras e acadêmicas pertinentes.

Processamento de Pagamentos: Facilitar a geração de cobranças e o processamento de pagamentos das mensalidades.

Comunicação: Enviar notificações sobre o status de mensalidades, eventos do calendário escolar e outras informações operacionais importantes.

Melhoria do Aplicativo: Analisar como os usuários interagem com o aplicativo para identificar problemas, melhorar a experiência de uso e desenvolver novas funcionalidades.

Segurança: Proteger a segurança da sua conta e da nossa plataforma, prevenindo fraudes e atividades não autorizadas.

Suporte ao Usuário: Responder às suas solicitações e solucionar problemas através do nosso e-mail de contato.

3. Compartilhamento de Informações
Nós não vendemos suas informações pessoais. Suas informações podem ser compartilhadas apenas nas seguintes circunstâncias:

Provedores de Serviço: Compartilhamos informações com empresas que nos auxiliam a operar, como nosso provedor de pagamentos (Mercado Pago) para processar transações. Esses parceiros são obrigados a manter a confidencialidade e segurança dos seus dados.

Obrigações Legais: Poderemos divulgar suas informações se formos obrigados por lei, intimação ou outro processo legal, ou se acreditarmos de boa-fé que a divulgação é necessária para proteger nossos direitos, sua segurança ou a segurança de outros.

4. Armazenamento e Segurança dos Dados
A segurança dos seus dados é nossa prioridade. Adotamos medidas técnicas e administrativas para proteger suas informações contra perda, roubo, uso indevido, acesso não autorizado, divulgação, alteração e destruição. Todas as senhas são armazenadas utilizando criptografia avançada.

Suas informações são armazenadas em servidores seguros e o acesso a elas é restrito. No entanto, lembre-se que nenhum método de transmissão pela internet ou armazenamento eletrônico é 100% seguro.

5. Seus Direitos como Titular dos Dados
De acordo com a Lei Geral de Proteção de Dados (LGPD), você tem o direito de:

Acessar seus dados pessoais.

Corrigir dados incompletos, inexatos ou desatualizados.

Solicitar a anonimização, bloqueio ou eliminação de dados desnecessários ou excessivos.

Solicitar a portabilidade dos seus dados a outro fornecedor de serviço.

Obter informações sobre as entidades com as quais compartilhamos seus dados.

Revogar o consentimento a qualquer momento.

Para exercer seus direitos, entre em contato conosco pelo e-mail: csaagrestina@gmail.com.

6. Retenção de Dados
Manteremos suas informações pessoais armazenadas enquanto você mantiver um vínculo ativo com nossa instituição (por exemplo, enquanto for responsável por um aluno matriculado). Após o término do vínculo, os dados poderão ser armazenados pelo período necessário para cumprir com obrigações legais ou regulatórias.

7. Alterações nesta Política de Privacidade
Podemos atualizar nossa Política de Privacidade periodicamente. Notificaremos você sobre quaisquer alterações, publicando a nova política nesta página e, se a alteração for significativa, enviaremos uma notificação através do aplicativo. Recomendamos que você revise esta política periodicamente.

8. Contato
Se você tiver alguma dúvida sobre esta Política de Privacidade ou sobre o tratamento dos seus dados, entre em contato conosco:

Colégio Santo Antônio
E-mail: csaagrestina@gmail.com
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
