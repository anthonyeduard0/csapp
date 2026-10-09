// Arquivo: lib/screens/settings_screen.dart
// VERSÃO FINAL: Redesenhada com novo estilo e lógica atualizada.
// ATUALIZADO: Gradiente de cores alterado para consistência visual.
// MODIFICADO: Removida a seção de Notificações.
// SINCRONIZADO: Texto dos Termos de Uso atualizado.
// ATUALIZADO: Adicionados 'const' para resolver avisos de lint.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:educsa/providers/theme_provider.dart';
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
      // --- TEXTO SINCRONIZADO ---
      content = '''
TERMOS DE USO DO APLICATIVO EDUCSA

Última atualização: 14 de setembro de 2025

Bem-vindo(a) ao EduCSA! Por favor, leia atentamente os seguintes Termos de Uso ("Termos") antes de utilizar nossa plataforma.

Ao clicar em "Li e aceito os Termos" ou ao acessar e utilizar os serviços oferecidos pelo aplicativo EduCSA ("Plataforma"), você ("Usuário") reconhece que leu, compreendeu e concorda em ficar vinculado a estes Termos e à nossa Política de Privacidade.

1. VISÃO GERAL E ACEITAÇÃO

1.1. A plataforma digital EduCSA (aplicativo móvel e portal web) é um serviço de propriedade e operado pelo Colégio Santo Antônio, sociedade empresária inscrita no CNPJ sob o nº 10.894.861/0001-14, doravante denominada "Instituição".

1.2. O objetivo da Plataforma é servir como um canal oficial de comunicação e gestão de informações acadêmicas e financeiras entre a Instituição e sua comunidade, incluindo, mas não se limitando a, educadores, alunos e seus respectivos pais ou responsáveis legais ("Usuários").

1.3. A aceitação destes Termos é requisito indispensável para a utilização da Plataforma. Se você não concordar com qualquer uma das disposições aqui presentes, não deverá utilizar os serviços.

2. CADASTRO E ELEGIBILIDADE

2.1. O acesso à Plataforma requer um cadastro prévio, que será disponibilizado pela Instituição aos responsáveis legais dos alunos devidamente matriculados.

2.2. O Usuário deve be uma pessoa física com plena capacidade civil. Menores de 18 anos devem ser representados ou assistidos por seus pais ou responsáveis legais, que serão os titulares da conta e responsáveis por todos os atos praticados por meio dela.

2.3. O Usuário compromete-se a fornecer informações verdadeiras, precisas, atuais e completas no momento do cadastro, e a mantê-las atualizadas. A Instituição não se responsabiliza pela veracidade dos dados fornecidos, sendo esta uma responsabilidade exclusiva do Usuário.

2.4. O acesso à conta é pessoal e intransferível, protegido por um CPF e uma senha. O Usuário é o único responsável pela confidencialidade e segurança de suas credenciais de acesso e por todas as atividades que ocorram em sua conta. A Instituição deve ser notificada imediatamente sobre qualquer uso não autorizado.

3. FUNCIONALIDADES E SERVIÇOS

3.1. A Plataforma oferece, entre outras, as seguintes funcionalidades:
a) Acesso a informações financeiras, como boletos de mensalidades, histórico de pagamentos e situação de débitos.
b) Realização de pagamentos de mensalidades através de um gateway de pagamento terceirizado.
c) Acesso ao calendário escolar, com eventos, feriados e datas importantes.
d) Canal de comunicação oficial entre a Instituição e os responsáveis.

4. PAGAMENTOS E TRANSAÇÕES FINANCEIRAS

4.1. Os pagamentos de mensalidades e outras taxas escolares realizados através da Plataforma são processados por uma empresa terceirizada (gateway de pagamento). Ao realizar uma transação, o Usuário concorda com os termos de serviço do respectivo gateway.

4.2. A Instituição não armazena dados de cartões de crédito ou outras informações financeiras sensíveis do Usuário. A responsabilidade pela segurança da transação é do gateway de pagamento.

4.3. Em caso de atraso no pagamento, serão aplicados multa e juros moratórios conforme o contrato de prestação de serviços educacionais firmado entre o Usuário e a Instituição. Tais valores serão calculados e exibidos automaticamente na Plataforma.

5. CONDIÇÕES DE USO E CONDUTA

5.1. O Usuário concorda em utilizar a Plataforma apenas para os fins a que se destina e em conformidade com a lei, a moral e os bons costumes.

5.2. É estritamente proibido ao Usuário:
a) Utilizar a Plataforma para qualquer finalidade ilícita, difamatória, ofensiva, ou que viole os direitos de terceiros.
b) Publicar ou transmitir qualquer conteúdo que contenha vírus, malware ou outro componente de software malicioso.
c) Tentar obter acesso não autorizado a sistemas, contas ou dados de outros Usuários.
d) Divulgar conteúdo que promova violência, discriminação de qualquer natureza (racial, sexual, religiosa, etc.) ou que atente contra os direitos humanos.
e) Utilizar a Plataforma para fins comerciais, como publicidade ou spam, sem a autorização prévia e expressa da Instituição.

6. PROPRIEDADE INTELECTUAL

6.1. Todos os direitos de propriedade intelectual relacionados à Plataforma, incluindo o nome "EduCSA", logotipos, software, design, textos, gráficos e outros conteúdos, são de propriedade exclusiva da Instituição ou de seus licenciantes. A utilização da Plataforma não concede ao Usuário qualquer direito de propriedade sobre esses elementos.

7. LIMITAÇÃO DE RESPONSABILIDADE

7.1. A Instituição envidará seus melhores esforços para manter a Plataforma disponível e funcional. No entanto, não garante o acesso e uso contínuo ou ininterrupto, que pode ser eventualmente afetado por falhas técnicas, manutenção ou circunstâncias fora de seu controle.

7.2. A Instituição atua como facilitadora da comunicação e da gestão financeira. Não se responsabiliza pelo conteúdo gerado pelos Usuários ou pela veracidade das informações trocadas entre eles.

7.3. A Instituição não será responsável por quaisquer danos, prejuízos ou perdas sofridas pelo Usuário em razão de falhas na internet, no sistema ou no servidor, ou decorrentes de condutas de terceiros, como ataques de hackers.

8. SUSPENSÃO E CANCELAMENTO DA CONTA

8.1. A Instituição reserva-se o direito de suspender ou cancelar, a qualquer momento e sem aviso prévio, o acesso do Usuário à Plataforma em caso de violação destes Termos, da Política de Privacidade ou da legislação aplicável.

8.2. O acesso à Plataforma está intrinsecamente ligado ao vínculo do aluno com a Instituição. Em caso de rescisão do contrato de prestação de serviços educacionais, o acesso do Usuário à Plataforma poderá ser desativado.

9. DISPOSIÇÕES GERAIS

9.1. Modificações nos Termos: A Instituição poderá alterar estes Termos a qualquer momento. As alterações entrarão em vigor na data de sua publicação na Plataforma. O uso continuado do serviço após a publicação constituirá aceitação dos novos Termos.

9.2. Legislação e Foro: Estes Termos são regidos pelas leis da República Federativa do Brasil. Fica eleito o foro da comarca de Agrestina, Estado de Pernambuco, para dirimir quaisquer controvérsias oriundas deste documento, com renúncia expressa a qualquer outro, por mais privilegiado que seja.

9.3. Contato: Em caso de dúvidas sobre estes Termos de Uso, entre em contato conosco através dos canais oficiais de atendimento do Colégio Santo Antônio.
''';
    } else {
      title = "Políticas de Privacidade";
      // O texto da política de privacidade permanece o mesmo
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (kIsWeb) {
      return _buildWebLayout(context, themeProvider, isDark);
    }
    return _buildMobileLayout(context, isDark);
  }

  // --- LAYOUT WEB PADRONIZADO ---
  Widget _buildWebLayout(
      BuildContext context, ThemeProvider themeProvider, bool isDark) {
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B0F19) : const Color(0xFFF0F4FF),
      body: Column(
        children: [
          _buildWebTopBar(context, isDark),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWebWelcomeBanner(isDark),
                      const SizedBox(height: 28),
                      _buildWebAppearanceCard(themeProvider, isDark),
                      const SizedBox(height: 24),
                      _buildWebLegalCard(context, isDark),
                      const SizedBox(height: 28),
                      _buildWebFooter(isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTopBar(BuildContext context, bool isDark) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withAlpha(8),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 25 : 10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Tooltip(
              message: 'Voltar',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : primaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configurações',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : primaryColor,
                ),
              ),
              Text(
                'Ajustes de preferências e termos',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Botão de alternância rápida de tema (idêntico ao WebShell)
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              final isThemeDark = themeProvider.isDarkMode;
              return Container(
                decoration: BoxDecoration(
                  color:
                      isDark ? const Color(0xFF334155) : const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Tooltip(
                  message: isThemeDark
                      ? 'Alternar para tema claro'
                      : 'Alternar para tema escuro',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => themeProvider.toggleTheme(!isThemeDark),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          isThemeDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: isThemeDark
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF1D449B),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Tooltip(
              message: 'Versão 1.0.1',
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: isDark ? Colors.white70 : primaryColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebWelcomeBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0F172A), Color(0xFF1E3A8A)]
              : const [primaryColor, accentColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configurações da Conta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Personalize sua experiência visual no EduCSA e acesse os termos legais.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebAppearanceCard(
      ThemeProvider themeProvider, bool isDark) {
    return _buildWebCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : primaryColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.palette_rounded,
                  color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Aparência',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : primaryColor,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : primaryColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Web',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Personalize a exibição do EduCSA alternando entre tema claro e escuro.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 18),
          // Apenas o slider - redundância de cards removida
          _buildThemeSliderTile(themeProvider, isDark),
        ],
      ),
    );
  }

  Widget _buildThemeSliderTile(ThemeProvider themeProvider, bool isDark) {
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF8B5CF6).withAlpha(30)
                  : const Color(0xFFF59E0B).withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDarkMode ? Icons.nightlight_round : Icons.wb_sunny_rounded,
              color: isDarkMode
                  ? const Color(0xFFA78BFA)
                  : const Color(0xFFD97706),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDarkMode ? 'Modo Escuro Ativo' : 'Modo Claro Ativo',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDarkMode
                      ? 'Interface adaptada para ambientes escuros e com menos reflexos'
                      : 'Interface padrão com visual claro e alto contraste',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isDarkMode,
            activeThumbColor: const Color(0xFF3B82F6),
            activeTrackColor: const Color(0xFF1D449B),
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWebLegalCard(BuildContext context, bool isDark) {
    return _buildWebCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : primaryColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.description_rounded,
                  color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Documentos Legais',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Consulte os termos de serviço e a política de privacidade da plataforma.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 18),
          _buildWebOptionTile(
            isDark: isDark,
            icon: Icons.article_rounded,
            title: 'Termos de Uso',
            subtitle: 'Leia os termos e condições de prestação de serviços',
            onTap: () => _showLegalScreen(context, "terms"),
          ),
          const SizedBox(height: 12),
          _buildWebOptionTile(
            isDark: isDark,
            icon: Icons.privacy_tip_rounded,
            title: 'Políticas de Privacidade',
            subtitle: 'Entenda como seus dados e os dos alunos são tratados e protegidos',
            onTap: () => _showLegalScreen(context, "privacy"),
          ),
        ],
      ),
    );
  }

  Widget _buildWebOptionTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155)
                        : primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebCard({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withAlpha(50) : Colors.black.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildWebFooter(bool isDark) {
    return Center(
      child: Text(
        'EduCSA Web • Colégio Santo Antônio • Versão 1.0.1',
        style: TextStyle(
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
          fontSize: 12,
        ),
      ),
    );
  }

  // --- LAYOUT MOBILE ORIGINAL INTACTO ---
  Widget _buildMobileLayout(BuildContext context, bool isDark) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0F172A), Color(0xFF1E3A8A)]
                : const [primaryColor, accentColor],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildMobileHeader(context),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : backgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Legal",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? const Color(0xFF60A5FA) : primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildMobileOptionTile(
                          isDark: isDark,
                          icon: Icons.description_rounded,
                          title: 'Termos de Uso',
                          subtitle: 'Leia os termos de serviço',
                          onTap: () => _showLegalScreen(context, "terms"),
                        ),
                        _buildMobileOptionTile(
                          isDark: isDark,
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

  Widget _buildMobileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configurações',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Ajustes e informações',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color? color,
    bool isDark = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: Colors.white12) : null,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withAlpha(40) : const Color(0x1A000000),
            blurRadius: 10,
          ),
        ],
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
                Icon(
                  icon,
                  color:
                      color ?? (isDark ? const Color(0xFF60A5FA) : primaryColor),
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              color ?? (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isDark ? Colors.grey.shade500 : Colors.grey,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}