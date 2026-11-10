// Arquivo: lib/screens/profile_screen.dart
// Tela de Perfil Mobile: mesma identidade visual e estrutura de cards da versão Web
// (lib/web/web_profile_screen.dart), em uma única coluna vertical rolável.

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

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> responseData;
  const ProfileScreen({super.key, required this.responseData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late DashboardData _dashboardData;
  List<AlunoComMensalidades> _alunosHistorico = [];

  static const Color primaryColor = Color(0xFF1D449B);
  static const Color accentColor = Color(0xFF25B6E8);
  static const Color backgroundColor = Color(0xFFF8FAFC);

  static const String _termsOfUseUrl =
      'https://gist.githubusercontent.com/anthonyeduard0/0b02af52257c33aee17c52b2872b19a4/raw/0ecf2b0a2491ff082e5649bc2d20a269643f374f/termos-de-uso.md';
  static const String _privacyPolicyUrl =
      'https://gist.githubusercontent.com/anthonyeduard0/05ddce8404f3af175acff888101994c2/raw/fe2abf43c91983fe78ff053c626b2f3f1c6bfb6c/politica_de_privacidade.md';

  @override
  void initState() {
    super.initState();
    _dashboardData = DashboardData.fromJson(widget.responseData);
    _fetchStudentInvoicesDetails();
  }

  /// Busca o histórico completo de mensalidades para extrair
  /// Dia de Vencimento e Valor Nominal (igual à versão Web).
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

  // Função para recarregar os dados do servidor
  Future<void> _reloadData() async {
    final prefs = await SharedPreferences.getInstance();
    final cpf = prefs.getString('user_cpf');
    final password = prefs.getString('user_password');
    if (cpf == null || password == null) return;

    final url = Uri.parse('${ApiConfig.baseUrl}/login/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'cpf': cpf, 'password': password}),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            _dashboardData = DashboardData.fromJson(responseData);
          });
        }
        await _fetchStudentInvoicesDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao recarregar o perfil. Verifique sua conexão.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _launchTermsOfUse() async {
    final Uri url = Uri.parse(_termsOfUseUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o link dos termos.')),
      );
    }
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse(_privacyPolicyUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o link da política.')),
      );
    }
  }

  Future<void> _handleLogout() async {
    final navigator = Navigator.of(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_cpf');
    await prefs.remove('user_password');
    await prefs.remove('auth_token');
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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reloadData,
          color: isDark ? const Color(0xFF60A5FA) : primaryColor,
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildResponsavelCard(isDark),
                const SizedBox(height: 20),
                _buildAlunosPanel(isDark),
                const SizedBox(height: 20),
                _buildPreferencesLegalSessionCard(context, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // CARD 1: Responsável Financeiro
  // ===========================================================================

  Widget _buildResponsavelCard(bool isDark) {
    final String telefone = (_dashboardData.telefone != null &&
            _dashboardData.telefone!.trim().isNotEmpty)
        ? _dashboardData.telefone!
        : 'Não cadastrado';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
                radius: 32,
                backgroundColor: Colors.white.withAlpha(38),
                child: Text(
                  _getInitials(_dashboardData.nomeResponsavel),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        fontSize: 19,
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
          const SizedBox(height: 18),
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
  // CARD 2: Alunos Vinculados e Dados de Matrícula
  // ===========================================================================

  Widget _buildAlunosPanel(bool isDark) {
    final int total = _dashboardData.alunos.length;
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
          '$total ${total == 1 ? 'aluno' : 'alunos'}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFF60A5FA) : primaryColor,
          ),
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < total; i++)
            _buildRichAlunoCard(
              _dashboardData.alunos[i],
              isDark,
              isLast: i == total - 1,
            ),
        ],
      ),
    );
  }

  Widget _buildRichAlunoCard(Aluno aluno, bool isDark, {required bool isLast}) {
    final formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final todasMensalidades = _getMensalidadesDoAluno(aluno);
    final pendentes = aluno.mensalidadesPendentes;

    // Extrai Dia de Vencimento e Valor Nominal da Mensalidade (igual à Web)
    final Mensalidade? refMensalidade = todasMensalidades.isNotEmpty
        ? todasMensalidades.first
        : (pendentes.isNotEmpty ? pendentes.first : null);

    final String diaVencimentoStr = refMensalidade != null
        ? 'Todo dia ${refMensalidade.dataVencimento.day.toString().padLeft(2, '0')}'
        : 'Todo dia 10';
    final String valorNominalStr = refMensalidade != null
        ? formatadorMoeda.format(refMensalidade.valorNominal)
        : 'Conforme contrato';

    final accent = isDark ? const Color(0xFF60A5FA) : primaryColor;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topo: Avatar + Nome + Série
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isDark
                    ? const Color(0xFF3B82F6).withAlpha(40)
                    : primaryColor.withAlpha(20),
                child: Text(
                  _getInitials(aluno.nomeCompleto),
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aluno.nomeCompleto,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Série / Ano: ${aluno.serieAno}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Badge de status da matrícula
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withAlpha(isDark ? 35 : 22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withAlpha(80)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 14, color: Color(0xFF10B981)),
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
          const SizedBox(height: 14),
          Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
          const SizedBox(height: 14),

          // 4 indicadores empilhados de forma limpa
          _buildDataMetricBox(
            isDark: isDark,
            icon: Icons.class_rounded,
            label: 'Série / Ano',
            value: aluno.serieAno,
          ),
          const SizedBox(height: 10),
          _buildDataMetricBox(
            isDark: isDark,
            icon: Icons.event_available_rounded,
            label: 'Validade da Matrícula',
            value: aluno.validadeMatriculaFormatada ?? 'Anual Vigente',
          ),
          const SizedBox(height: 10),
          _buildDataMetricBox(
            isDark: isDark,
            icon: Icons.calendar_today_rounded,
            label: 'Dia de Vencimento',
            value: diaVencimentoStr,
          ),
          const SizedBox(height: 10),
          _buildDataMetricBox(
            isDark: isDark,
            icon: Icons.payments_rounded,
            label: 'Valor Nominal da Mensalidade',
            value: valorNominalStr,
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
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF3B82F6) : primaryColor).withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isDark ? const Color(0xFF60A5FA) : primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CARD 3: Preferências, Jurídico e Sessão
  // ===========================================================================

  Widget _buildPreferencesLegalSessionCard(BuildContext context, bool isDark) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return _buildSectionCard(
      isDark: isDark,
      title: 'Preferências, Jurídico e Sessão',
      subtitle: 'Aparência, documentos oficiais e controle de acesso',
      icon: Icons.tune_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Switch de Modo Escuro (ThemeProvider)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
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
                    isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: isDarkMode
                        ? const Color(0xFFA78BFA)
                        : const Color(0xFFD97706),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
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
                  onChanged: (value) => themeProvider.toggleTheme(value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Termos de Uso (Gist externo)
          _buildActionTile(
            isDark: isDark,
            icon: Icons.article_rounded,
            title: 'Termos de Uso',
            subtitle: 'Condições gerais de utilização do EduCSA',
            trailingIcon: Icons.open_in_new,
            onTap: _launchTermsOfUse,
          ),
          const SizedBox(height: 12),

          // 3. Política de Privacidade (Gist externo)
          _buildActionTile(
            isDark: isDark,
            icon: Icons.privacy_tip_rounded,
            title: 'Política de Privacidade',
            subtitle: 'Diretrizes de proteção de dados e LGPD',
            trailingIcon: Icons.open_in_new,
            onTap: _launchPrivacyPolicy,
          ),
          const SizedBox(height: 16),

          Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
          const SizedBox(height: 16),

          // 4. Sair da Conta (Logout)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                'Sair da Conta (Logout)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
              'EduCSA • Colégio Santo Antônio • Versão 1.0.1',
              textAlign: TextAlign.center,
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
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                const SizedBox(width: 12),
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
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withAlpha(50) : Colors.black.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [primaryColor, accentColor]),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : primaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(height: 8),
                      trailing,
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
