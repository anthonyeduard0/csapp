// lib/web/web_profile_screen.dart
// Tela de Perfil e Configurações Web: Layout em 2 Colunas (flex 5 : flex 7) ocupando toda a área útil.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:educsa/api_config.dart';
import 'package:educsa/providers/theme_provider.dart';
import 'package:educsa/screens/login_screen.dart';
import 'package:educsa/screens/main_screen.dart';

class WebProfileScreen extends StatefulWidget {
  final Map<String, dynamic> responseData;
  final VoidCallback? onLogout;

  const WebProfileScreen({
    super.key,
    required this.responseData,
    this.onLogout,
  });

  @override
  State<WebProfileScreen> createState() => _WebProfileScreenState();
}

class _WebProfileScreenState extends State<WebProfileScreen> {
  static const Color primaryColor = Color(0xFF1D449B);
  static const Color accentColor = Color(0xFF25B6E8);

  static const String _termsOfUseUrl =
      'https://gist.githubusercontent.com/anthonyeduard0/0b02af52257c33aee17c52b2872b19a4/raw/0ecf2b0a2491ff082e5649bc2d20a269643f374f/termos-de-uso.md';
  static const String _privacyPolicyUrl =
      'https://gist.githubusercontent.com/anthonyeduard0/05ddce8404f3af175acff888101994c2/raw/fe2abf43c91983fe78ff053c626b2f3f1c6bfb6c/politica_de_privacidade.md';

  late DashboardData _dashboardData;
  List<AlunoComMensalidades> _alunosHistorico = [];

  @override
  void initState() {
    super.initState();
    _dashboardData = DashboardData.fromJson(widget.responseData);
    _fetchStudentInvoicesDetails();
  }

  Future<void> _fetchStudentInvoicesDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/mensalidades/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (mounted && response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _alunosHistorico = body
              .map((dynamic item) => AlunoComMensalidades.fromJson(item))
              .toList();
        });
      }
    } catch (_) {
      // Fallback silencioso usando mensalidadesPendentes do aluno
    }
  }

  Future<void> _launchTermsOfUse() async {
    final Uri url = Uri.parse(_termsOfUseUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não foi possível abrir o link dos termos.')),
      );
    }
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse(_privacyPolicyUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não foi possível abrir o link da política.')),
      );
    }
  }

  Future<void> _handleLogout() async {
    final navigator = Navigator.of(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_cpf');
    await prefs.remove('user_password');
    await prefs.remove('auth_token');
    widget.onLogout?.call();
    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  String _getInitials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  List<Mensalidade> _getMensalidadesDoAluno(Aluno aluno) {
    final match = _alunosHistorico.where(
      (h) =>
          h.nomeCompleto.trim().toLowerCase() ==
          aluno.nomeCompleto.trim().toLowerCase(),
    );
    if (match.isNotEmpty && match.first.mensalidades.isNotEmpty) {
      return match.first.mensalidades;
    }
    return aluno.mensalidadesPendentes;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 820;
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coluna Esquerda (flex: 5) -> Card do Responsável + Preferências/Jurídico/Sessão
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildResponsavelCard(isDark),
                      const SizedBox(height: 24),
                      _buildPreferencesLegalSessionCard(context, isDark),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Coluna Direita (flex: 7) -> Painel de Alunos Vinculados e Dados de Matrícula
                Expanded(
                  flex: 7,
                  child: _buildAlunosPanel(context, isDark),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResponsavelCard(isDark),
              const SizedBox(height: 24),
              _buildAlunosPanel(context, isDark),
              const SizedBox(height: 24),
              _buildPreferencesLegalSessionCard(context, isDark),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // COLUNA ESQUERDA 1: Card do Responsável Financeiro
  // ===========================================================================

  Widget _buildResponsavelCard(bool isDark) {
    final String telefone =
        (_dashboardData.telefone != null &&
                _dashboardData.telefone!.trim().isNotEmpty)
            ? _dashboardData.telefone!
            : 'Não cadastrado';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0F172A), Color(0xFF1E3A8A)]
              : const [primaryColor, accentColor],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white.withAlpha(38),
                child: Text(
                  _getInitials(_dashboardData.nomeResponsavel),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(28),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Responsável Financeiro',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _dashboardData.nomeResponsavel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildResponsavelInfoTile(
            icon: Icons.badge_rounded,
            label: 'CPF',
            value: _dashboardData.cpfResponsavel,
          ),
          const SizedBox(height: 10),
          _buildResponsavelInfoTile(
            icon: Icons.email_rounded,
            label: 'E-mail',
            value: _dashboardData.email,
          ),
          const SizedBox(height: 10),
          _buildResponsavelInfoTile(
            icon: Icons.phone_rounded,
            label: 'Telefone',
            value: telefone,
          ),
        ],
      ),
    );
  }

  Widget _buildResponsavelInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // COLUNA ESQUERDA 2: Card de Preferências, Jurídico e Sessão
  // ===========================================================================

  Widget _buildPreferencesLegalSessionCard(BuildContext context, bool isDark) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return _buildSectionCard(
      isDark: isDark,
      title: 'Preferências, Jurídico e Sessão',
      subtitle: 'Aparência do painel, documentos oficiais e controle de acesso',
      icon: Icons.tune_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Switch de Modo Escuro (ThemeProvider)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
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
                    isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: isDarkMode
                        ? const Color(0xFFA78BFA)
                        : const Color(0xFFD97706),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modo Escuro',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isDarkMode
                            ? 'Ativado • Conforto visual para baixa luz'
                            : 'Desativado • Tema claro padrão ativo',
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
                Switch.adaptive(
                  value: isDarkMode,
                  activeThumbColor: const Color(0xFF3B82F6),
                  activeTrackColor: const Color(0xFF1D449B),
                  onChanged: (value) => themeProvider.toggleTheme(value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Botão Termos de Uso (Gist externo com Icons.open_in_new)
          _buildActionTile(
            isDark: isDark,
            icon: Icons.article_rounded,
            title: 'Termos de Uso',
            subtitle: 'Condições gerais de utilização do portal EduCSA',
            trailingIcon: Icons.open_in_new,
            onTap: _launchTermsOfUse,
          ),
          const SizedBox(height: 12),

          // 3. Botão Política de Privacidade (Gist externo com Icons.open_in_new)
          _buildActionTile(
            isDark: isDark,
            icon: Icons.privacy_tip_rounded,
            title: 'Política de Privacidade',
            subtitle: 'Diretrizes de proteção de dados e LGPD',
            trailingIcon: Icons.open_in_new,
            onTap: _launchPrivacyPolicy,
          ),
          const SizedBox(height: 16),

          Divider(
            height: 1,
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
          const SizedBox(height: 16),

          // 4. Botão Sair da Conta (Logout)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                'Sair da Conta (Logout)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    isDark ? const Color(0xFFF87171) : Colors.red.shade700,
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFFF87171).withAlpha(120)
                      : Colors.red.shade300,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'EduCSA Web • Colégio Santo Antônio • Versão 1.0.1',
              style: TextStyle(
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required IconData trailingIcon,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
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
                  trailingIcon,
                  color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // COLUNA DIREITA (flex: 7): Painel de Alunos Vinculados e Dados de Matrícula
  // ===========================================================================

  Widget _buildAlunosPanel(BuildContext context, bool isDark) {
    return _buildSectionCard(
      isDark: isDark,
      title: 'Alunos Vinculados e Dados de Matrícula',
      subtitle: 'Informações acadêmicas e parâmetros contratuais',
      icon: Icons.school_rounded,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF3B82F6) : primaryColor).withAlpha(25),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${_dashboardData.alunos.length} ${_dashboardData.alunos.length == 1 ? 'aluno' : 'alunos'}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFF60A5FA) : primaryColor,
          ),
        ),
      ),
      child: Column(
        children: _dashboardData.alunos
            .map((aluno) => _buildRichAlunoCard(context, aluno, isDark))
            .toList(),
      ),
    );
  }

  Widget _buildRichAlunoCard(BuildContext context, Aluno aluno, bool isDark) {
    final formatadorMoeda =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final todasMensalidades = _getMensalidadesDoAluno(aluno);
    final pendentes = aluno.mensalidadesPendentes;

    // Extrai Dia de Vencimento e Valor Nominal da Mensalidade
    final Mensalidade? refMensalidade = todasMensalidades.isNotEmpty
        ? todasMensalidades.first
        : (pendentes.isNotEmpty ? pendentes.first : null);

    final String diaVencimentoStr = refMensalidade != null
        ? 'Todo dia ${refMensalidade.dataVencimento.day.toString().padLeft(2, '0')}'
        : 'Todo dia 10';
    final String valorNominalStr = refMensalidade != null
        ? formatadorMoeda.format(refMensalidade.valorNominal)
        : 'Conforme contrato';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topo: Avatar + Nome + Série + Badge Status da Matrícula
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: isDark
                    ? const Color(0xFF3B82F6).withAlpha(40)
                    : primaryColor.withAlpha(20),
                child: Text(
                  _getInitials(aluno.nomeCompleto),
                  style: TextStyle(
                    color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aluno.nomeCompleto,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Série / Ano: ${aluno.serieAno}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(isDark ? 35 : 22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981).withAlpha(80),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Matrícula ${aluno.statusMatricula}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          Divider(
            height: 1,
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
          const SizedBox(height: 18),

          // Grade de Parâmetros da Matrícula (4 indicadores)
          LayoutBuilder(
            builder: (context, boxConstraints) {
              final items = [
                _buildDataMetricBox(
                  isDark: isDark,
                  icon: Icons.class_rounded,
                  label: 'Série / Ano',
                  value: aluno.serieAno,
                ),
                _buildDataMetricBox(
                  isDark: isDark,
                  icon: Icons.event_available_rounded,
                  label: 'Validade da Matrícula',
                  value: aluno.validadeMatriculaFormatada ?? 'Anual Vigente',
                ),
                _buildDataMetricBox(
                  isDark: isDark,
                  icon: Icons.calendar_today_rounded,
                  label: 'Dia de Vencimento',
                  value: diaVencimentoStr,
                ),
                _buildDataMetricBox(
                  isDark: isDark,
                  icon: Icons.payments_rounded,
                  label: 'Valor Nominal da Mensalidade',
                  value: valorNominalStr,
                ),
              ];

              if (boxConstraints.maxWidth >= 520) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: items[0]),
                        const SizedBox(width: 12),
                        Expanded(child: items[1]),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: items[2]),
                        const SizedBox(width: 12),
                        Expanded(child: items[3]),
                      ],
                    ),
                  ],
                );
              }
              return Column(
                children: items
                    .map((w) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: w,
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataMetricBox({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF3B82F6) : primaryColor)
                  .withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isDark ? const Color(0xFF60A5FA) : primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isDark ? Colors.black.withAlpha(50) : Colors.black.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryColor, accentColor],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : primaryColor,
                      ),
                    ),
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
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
