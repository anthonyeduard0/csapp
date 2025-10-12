// Arquivo: lib/screens/terms_acceptance_screen.dart
// ATUALIZADO: Revertido para o fundo branco e melhorado o estilo.

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:educsa/screens/main_screen.dart';
import 'package:educsa/screens/legal_screen.dart';
import 'package:flutter/gestures.dart';

class TermsAcceptanceWrapper extends StatelessWidget {
  final Map<String, dynamic> responseData;
  const TermsAcceptanceWrapper({super.key, required this.responseData});

  @override
  Widget build(BuildContext context) {
    final bool termosAceitos = responseData['termos_aceitos'] ?? false;

    if (termosAceitos) {
      return MainScreen(responseData: responseData);
    } else {
      return _TermsAcceptancePage(responseData: responseData);
    }
  }
}

class _TermsAcceptancePageState extends State<_TermsAcceptancePage> {
  bool _isLoading = false;
  bool _termsAccepted = false;

  Future<void> _acceptTerms() async {
    setState(() {
      _isLoading = true;
    });

    final cpf = widget.responseData['cpf'];
    final url =
        Uri.parse('https://csa-url-app.onrender.com/api/aceitar-termos/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'cpf': cpf}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(responseData: widget.responseData),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erro ao aceitar os termos. Tente novamente.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showLegalScreen(String type) {
    String title = "";
    String content = "";

    if (type == "terms") {
      title = "Termos de Uso";
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

2.2. O Usuário deve ser uma pessoa física com plena capacidade civil. Menores de 18 anos devem ser representados ou assistidos por seus pais ou responsáveis legais, que serão os titulares da conta e responsáveis por todos os atos praticados por meio dela.

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
      title = "Política de Privacidade";
      content = '''
POLÍTICA DE PRIVACIDADE E SEGURANÇA

1.  A Política de Privacidade e Segurança do EduCSA garante segurança e privacidade de identidade aos usuários que forneçam suas informações ao sistema (web e mobile) e site. Dados pessoais cadastrados são protegidos por sistemas avançados de criptografia.
2.  A plataforma pertencente ao Colégio Santo Antônio adota os níveis legalmente requeridos quanto à segurança na proteção de dados, com respectiva utilização de todos os meios e medidas técnicas para inibição da perda, mau uso, alteração, acesso não autorizado ou subtração indevida dos dados pessoais recolhidos. Não obstante, o usuário deve estar ciente de que as medidas de segurança relativas à Internet não são integralmente infalíveis.
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
    const Color primaryColor = Color(0xFF1E3A8A);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.policy_outlined,
                        size: 80, color: primaryColor),
                    const SizedBox(height: 24),
                    const Text(
                      'Termos e Privacidade',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Para continuar, você precisa ler e aceitar nossos Termos de Uso e Políticas de Privacidade.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Checkbox(
                          value: _termsAccepted,
                          onChanged: (bool? value) {
                            setState(() {
                              _termsAccepted = value ?? false;
                            });
                          },
                          activeColor: primaryColor,
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 14),
                              children: [
                                const TextSpan(text: 'Eu li e aceito os '),
                                TextSpan(
                                  text: 'Termos de Uso',
                                  style: const TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => _showLegalScreen("terms"),
                                ),
                                const TextSpan(text: ' e a '),
                                TextSpan(
                                  text: 'Política de Privacidade',
                                  style: const TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => _showLegalScreen("privacy"),
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _termsAccepted ? _acceptTerms : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                disabledBackgroundColor: Colors.grey.shade300,
                              ),
                              child: const Text('CONTINUAR',
                                  style: TextStyle(fontSize: 16)),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TermsAcceptancePage extends StatefulWidget {
  final Map<String, dynamic> responseData;
  const _TermsAcceptancePage({required this.responseData});

  @override
  State<_TermsAcceptancePage> createState() => _TermsAcceptancePageState();
}

