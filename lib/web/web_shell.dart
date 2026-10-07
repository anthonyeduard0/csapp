// lib/web/web_shell.dart
// Layout principal da interface web: sidebar lateral fixa + área de conteúdo.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:educsa/providers/theme_provider.dart';
import 'package:educsa/screens/main_screen.dart';
import 'web_financial_screen.dart';
import 'web_calendar_screen.dart';
import 'web_profile_screen.dart';

class WebShell extends StatefulWidget {
  final Map<String, dynamic> responseData;
  const WebShell({super.key, required this.responseData});

  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  int _selectedIndex = 0;
  late DashboardData _dashboardData;

  static const Color primaryColor = Color(0xFF1D449B);

  @override
  void initState() {
    super.initState();
    _dashboardData = DashboardData.fromJson(widget.responseData);
  }

  void _updateDashboard(DashboardData data) {
    setState(() {
      _dashboardData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF0F4FF),
      body: Row(
        children: [
          _buildSidebar(isDark),
          Expanded(
            child: _buildContentArea(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool isDark) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF0F172A), Color(0xFF111827), Color(0xFF0B0F19)]
              : const [primaryColor, Color(0xFF1A3580), Color(0xFF152D6E)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 20,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSidebarHeader(),
          const SizedBox(height: 8),
          _buildNavDivider('MENU'),
          _buildNavItem(
            icon: Icons.monetization_on_rounded,
            label: 'Financeiro',
            index: 0,
          ),
          _buildNavItem(
            icon: Icons.calendar_today_rounded,
            label: 'Calendário',
            index: 1,
          ),
          _buildNavItem(
            icon: Icons.person_rounded,
            label: 'Perfil',
            index: 2,
          ),
          const Spacer(),
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Image(
              image: AssetImage('assets/images/Logocsa.png'),
              height: 48,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'EduCSA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const Text(
            'Colégio Santo Antônio',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavDivider(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(color: Colors.white.withAlpha(50), width: 1)
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _selectedIndex = index),
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.white.withAlpha(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withAlpha(40)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: isActive ? Colors.white : Colors.white60,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white60,
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (isActive) ...[
                    const Spacer(),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withAlpha(40),
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dashboardData.nomeResponsavel.split(' ').first,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Responsável',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea(bool isDark) {
    return Column(
      children: [
        _buildTopBar(isDark),
        Expanded(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              WebFinancialScreen(
                responseData: widget.responseData,
                onDataReloaded: _updateDashboard,
              ),
              const WebCalendarScreen(),
              WebProfileScreen(
                responseData: widget.responseData,
                onLogout: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(bool isDark) {
    final pageTitles = ['Financeiro', 'Calendário Escolar', 'Perfil'];
    final pageSubtitles = [
      'Gerencie suas mensalidades',
      'Acompanhe os eventos importantes',
      'Suas informações e configurações',
    ];

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
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pageTitles[_selectedIndex],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1D449B),
                ),
              ),
              Text(
                pageSubtitles[_selectedIndex],
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFF1D449B),
                  child: Text(
                    _dashboardData.nomeResponsavel.isNotEmpty
                        ? _dashboardData.nomeResponsavel[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Olá, ${_dashboardData.nomeResponsavel.split(' ').first}!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF1D449B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Botão de alternância rápida de tema
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              final isThemeDark = themeProvider.isDarkMode;
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF0F4FF),
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
                  color: isDark ? Colors.white70 : const Color(0xFF1D449B),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
