// lib/web/web_profile_screen.dart
// Tela de perfil web: layout em grid com card do responsável e cards de alunos/opções.

import 'package:flutter/material.dart';
import 'package:educsa/screens/main_screen.dart';
import 'package:educsa/screens/login_screen.dart';
import 'package:educsa/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  late DashboardData _dashboardData;

  @override
  void initState() {
    super.initState();
    _dashboardData = DashboardData.fromJson(widget.responseData);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Profile card
                SizedBox(width: 280, child: _buildProfileCard()),
                const SizedBox(width: 24),
                // Right: Students + options
                Expanded(
                  child: Column(
                    children: [
                      _buildAlunosSection(isDark),
                      const SizedBox(height: 20),
                      _buildOptionsSection(context, isDark),
                      const SizedBox(height: 20),
                      _buildVersionBadge(),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                _buildProfileCard(),
                const SizedBox(height: 20),
                _buildAlunosSection(isDark),
                const SizedBox(height: 20),
                _buildOptionsSection(context, isDark),
                const SizedBox(height: 20),
                _buildVersionBadge(),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, accentColor],
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
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: Colors.white.withAlpha(40),
            child: Text(
              _dashboardData.nomeResponsavel.isNotEmpty
                  ? _dashboardData.nomeResponsavel[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _dashboardData.nomeResponsavel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          const Text(
            'Responsável',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _buildProfileInfoRow(Icons.email_rounded, _dashboardData.email),
          if (_dashboardData.telefone != null &&
              _dashboardData.telefone!.isNotEmpty)
            _buildProfileInfoRow(
                Icons.phone_rounded, _dashboardData.telefone!),
        ],
      ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style:
                    const TextStyle(color: Colors.white, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlunosSection(bool isDark) {
    return _buildSection(
      isDark: isDark,
      title: 'Alunos Vinculados',
      icon: Icons.school_rounded,
      child: Column(
        children: _dashboardData.alunos
            .map((aluno) => _buildAlunoCard(aluno, isDark))
            .toList(),
      ),
    );
  }

  Widget _buildAlunoCard(Aluno aluno, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isDark
                    ? const Color(0xFF3B82F6).withAlpha(40)
                    : primaryColor.withAlpha(20),
                child: Text(
                  aluno.nomeCompleto.isNotEmpty
                      ? aluno.nomeCompleto[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  aluno.nomeCompleto,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : primaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.class_rounded, 'Série/Ano', aluno.serieAno, isDark),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.check_circle_rounded,
            'Status',
            aluno.statusMatricula,
            isDark,
            valueColor: isDark ? const Color(0xFF4ADE80) : Colors.green.shade700,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.event_available_rounded,
            'Validade',
            aluno.validadeMatriculaFormatada ?? 'N/A',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark,
      {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: valueColor ?? (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsSection(BuildContext context, bool isDark) {
    return _buildSection(
      isDark: isDark,
      title: 'Opções',
      icon: Icons.settings_rounded,
      child: Column(
        children: [
          _buildOptionTile(
            context: context,
            icon: Icons.settings_rounded,
            title: 'Configurações',
            subtitle: 'Tema claro/escuro, termos e privacidade',
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const SettingsScreen()),
            ),
          ),
          const SizedBox(height: 8),
          _buildOptionTile(
            context: context,
            icon: Icons.logout_rounded,
            title: 'Sair',
            subtitle: 'Encerrar sua sessão atual',
            color: Colors.red.shade700,
            isDark: isDark,
            onTap: () async {
              final navigator = Navigator.of(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_cpf');
              await prefs.remove('user_password');
              if (!mounted) return;
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color? color,
    bool isDark = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: color ?? (isDark ? const Color(0xFF60A5FA) : primaryColor),
                  size: 20,
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
                          color: color ?? (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
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
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
    bool isDark = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildVersionBadge() {
    return Text(
      'Versão do Aplicativo 1.0.1',
      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
    );
  }
}
