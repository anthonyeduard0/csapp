// Arquivo: lib/screens/settings_screen.dart
// VERSÃO FINAL: Redesenhada com novo estilo e lógica atualizada.
// ATUALIZADO: Gradiente de cores alterado para consistência visual.
// MODIFICADO: Removida a seção de Notificações.
// SINCRONIZADO: Texto dos Termos de Uso atualizado.
// ATUALIZADO: Adicionados 'const' para resolver avisos de lint.

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
                        // --- SEÇÃO DE NOTIFICAÇÕES REMOVIDA ---
                        
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
              decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(16)),
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
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 10)], // Aviso de const literal
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
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16), // Aviso de const
              ],
            ),
          ),
        ),
      ),
    );
  }
}