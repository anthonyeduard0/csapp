// lib/web/web_financial_screen.dart
// Tela financeira para web: layout limpo em 2 colunas (6:4) com fatura em destaque.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:educsa/api_config.dart';
import 'package:educsa/screens/invoice_history_screen.dart';
import 'package:educsa/screens/main_screen.dart';
import 'package:educsa/screens/payment_screen.dart';

class WebFinancialScreen extends StatefulWidget {
  final Map<String, dynamic> responseData;
  final void Function(DashboardData)? onDataReloaded;

  const WebFinancialScreen({
    super.key,
    required this.responseData,
    this.onDataReloaded,
  });

  @override
  State<WebFinancialScreen> createState() => _WebFinancialScreenState();
}

class _WebFinancialScreenState extends State<WebFinancialScreen> {
  static const Color primaryColor = Color(0xFF1D449B);
  static const Color accentColor = Color(0xFF25B6E8);

  late DashboardData _dashboardData;
  int _selectedAlunoIndex = 0;

  @override
  void initState() {
    super.initState();
    _dashboardData = DashboardData.fromJson(widget.responseData);
    _selectDefaultAlunoWithPendingInvoice();
  }

  void _selectDefaultAlunoWithPendingInvoice() {
    for (int i = 0; i < _dashboardData.alunos.length; i++) {
      if (_dashboardData.alunos[i].mensalidadesPendentes.isNotEmpty) {
        _selectedAlunoIndex = i;
        return;
      }
    }
    _selectedAlunoIndex = 0;
  }

  Future<void> _reloadData() async {
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
        final historico = body
            .map((dynamic item) => AlunoComMensalidades.fromJson(item))
            .toList();

        final updatedAlunos = _dashboardData.alunos.map((aluno) {
          final match = historico.where(
            (h) =>
                h.nomeCompleto.trim().toLowerCase() ==
                aluno.nomeCompleto.trim().toLowerCase(),
          );
          if (match.isNotEmpty) {
            final pendentes = match.first.mensalidades
                .where((m) => m.status == 'PENDENTE' || m.status == 'ATRASADA')
                .toList()
              ..sort((a, b) => a.dataVencimento.compareTo(b.dataVencimento));
            return Aluno(
              nomeCompleto: aluno.nomeCompleto,
              serieAno: aluno.serieAno,
              statusMatricula: aluno.statusMatricula,
              validadeMatriculaFormatada: aluno.validadeMatriculaFormatada,
              mensalidadesPendentes: pendentes,
            );
          }
          return aluno;
        }).toList();

        final newDashboard = _dashboardData.copyWith(alunos: updatedAlunos);
        setState(() {
          _dashboardData = newDashboard;
          if (_selectedAlunoIndex >= _dashboardData.alunos.length) {
            _selectedAlunoIndex = 0;
          }
        });
        widget.onDataReloaded?.call(newDashboard);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao atualizar os dados.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link.')),
        );
      }
    }
  }

  Mensalidade? _getProximaMensalidade() {
    if (_dashboardData.alunos.isEmpty) return null;
    final idx = _selectedAlunoIndex.clamp(0, _dashboardData.alunos.length - 1);
    final alunoSelecionado = _dashboardData.alunos[idx];
    if (alunoSelecionado.mensalidadesPendentes.isNotEmpty) {
      return alunoSelecionado.mensalidadesPendentes.first;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final proximaMensalidade = _getProximaMensalidade();

    return RefreshIndicator(
      onRefresh: _reloadData,
      color: primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Banner Superior (Hero Card Azul com Gradiente)
            _buildWelcomeRow(),
            const SizedBox(height: 28),

            // 2. Corpo Principal em 2 Colunas (flex 6 : flex 4)
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Coluna Esquerda (flex: 6): Card "Próxima Fatura"
                      Expanded(
                        flex: 6,
                        child: _buildMainInvoiceCard(
                          context,
                          proximaMensalidade,
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Coluna Direita (flex: 4): Ações Rápidas + Alunos Vinculados + Fale Conosco
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            _buildQuickActionsCard(context),
                            const SizedBox(height: 20),
                            _buildAlunosCard(),
                            const SizedBox(height: 20),
                            _buildSocialCard(),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildMainInvoiceCard(context, proximaMensalidade),
                      const SizedBox(height: 20),
                      _buildQuickActionsCard(context),
                      const SizedBox(height: 20),
                      _buildAlunosCard(),
                      const SizedBox(height: 20),
                      _buildSocialCard(),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bem-vindo(a) de volta!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dashboardData.nomeResponsavel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Acompanhe a situação financeira dos seus alunos',
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
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

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'PAGA':
        return {
          'text': 'PAGO',
          'color': Colors.green.shade800,
          'bgColor': Colors.green.shade100,
          'icon': Icons.check_circle_rounded,
        };
      case 'ATRASADA':
        return {
          'text': 'ATRASADA',
          'color': Colors.red.shade800,
          'bgColor': Colors.red.shade100,
          'icon': Icons.warning_rounded,
        };
      case 'PENDENTE':
        return {
          'text': 'PENDENTE',
          'color': Colors.orange.shade800,
          'bgColor': Colors.orange.shade100,
          'icon': Icons.schedule_rounded,
        };
      default:
        return {
          'text': status,
          'color': Colors.black,
          'bgColor': Colors.grey.shade200,
          'icon': Icons.help_outline_rounded,
        };
    }
  }

  Widget _buildMainInvoiceCard(
      BuildContext context, Mensalidade? mensalidade) {
    final formatadorMoeda =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (mensalidade == null) {
      return _buildCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF064E3B).withAlpha(80)
                    : Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_user_rounded,
                size: 56,
                color:
                    isDark ? const Color(0xFF4ADE80) : Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tudo em dia!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Nenhuma mensalidade pendente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InvoiceHistoryScreen(
                    responsavelCpf: _dashboardData.cpfResponsavel,
                  ),
                ),
              ).then((v) {
                if (v == true) _reloadData();
              }),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Ver histórico'),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    isDark ? const Color(0xFF60A5FA) : primaryColor,
                side: BorderSide(
                  color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final statusInfo = _getStatusInfo(mensalidade.status);
    final mesFormatado = capitalize(
      DateFormat('MMMM', 'pt_BR').format(mensalidade.mesReferencia),
    );

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Próxima Fatura',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusInfo['bgColor'],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusInfo['icon'],
                      size: 14,
                      color: statusInfo['color'],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusInfo['text'],
                      style: TextStyle(
                        color: statusInfo['color'],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Mensalidade de $mesFormatado',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        primaryColor.withAlpha(45),
                        accentColor.withAlpha(35),
                      ]
                    : [
                        primaryColor.withAlpha(12),
                        accentColor.withAlpha(12),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Valor',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        formatadorMoeda.format(mensalidade.valorFinal),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Vencimento',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy')
                          .format(mensalidade.dataVencimento),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (mensalidade.status == 'ATRASADA') ...[
            const SizedBox(height: 16),
            _buildDetalheRow(
              'Valor Original',
              formatadorMoeda.format(mensalidade.valorNominal),
              isDark,
            ),
            const SizedBox(height: 6),
            _buildDetalheRow(
              'Multa',
              formatadorMoeda.format(mensalidade.multa),
              isDark,
            ),
            const SizedBox(height: 6),
            _buildDetalheRow(
              'Juros (${mensalidade.diasAtraso} dias)',
              formatadorMoeda.format(mensalidade.juros),
              isDark,
            ),
          ],
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(colors: [primaryColor, accentColor]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withAlpha(80),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      mensalidadeId: mensalidade.id,
                      valor: mensalidade.valorFinal.toStringAsFixed(2),
                      mesReferencia: DateFormat('MM/yyyy')
                          .format(mensalidade.mesReferencia),
                    ),
                  ),
                );
                if (result == true) _reloadData();
              },
              icon: const Icon(Icons.pix, color: Colors.white, size: 20),
              label: const Text(
                'Pagar com Pix',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalheRow(String label, String value, [bool isDark = false]) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.black54,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // COLUNA DIREITA: Ações Rápidas + Alunos Vinculados + Fale Conosco
  // ===========================================================================

  Widget _buildQuickActionsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ações Rápidas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF60A5FA) : primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.receipt_long_rounded,
            label: 'Ver todas as faturas',
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InvoiceHistoryScreen(
                  responsavelCpf: _dashboardData.cpfResponsavel,
                ),
              ),
            ).then((v) {
              if (v == true) _reloadData();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDark = false,
  }) {
    return Material(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F4FF),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : primaryColor,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: isDark ? Colors.grey.shade500 : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlunosCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasMultiple = _dashboardData.alunos.length > 1;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alunos Vinculados',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF60A5FA) : primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_dashboardData.alunos.length, (index) {
            final aluno = _dashboardData.alunos[index];
            final isSelected = hasMultiple && _selectedAlunoIndex == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: hasMultiple
                      ? () => setState(() => _selectedAlunoIndex = index)
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(
                              color: isDark
                                  ? const Color(0xFF60A5FA)
                                  : primaryColor,
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isDark
                              ? const Color(0xFF3B82F6).withAlpha(40)
                              : primaryColor.withAlpha(30),
                          child: Text(
                            aluno.nomeCompleto.isNotEmpty
                                ? aluno.nomeCompleto[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF60A5FA)
                                  : primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                aluno.nomeCompleto,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : primaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                aluno.serieAno,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: isDark
                                ? const Color(0xFF60A5FA)
                                : primaryColor,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSocialCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fale Conosco',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF60A5FA) : primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSocialButton(
                  icon: FontAwesomeIcons.whatsapp,
                  color: const Color(0xFF25D366),
                  label: 'WhatsApp',
                  url: 'https://wa.me/5581995602150',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSocialButton(
                  icon: FontAwesomeIcons.instagram,
                  color: const Color(0xFFE4405F),
                  label: 'Instagram',
                  url: 'https://instagram.com/csa_agrestina20',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSocialButton(
                  icon: FontAwesomeIcons.facebook,
                  color: const Color(0xFF1877F2),
                  label: 'Facebook',
                  url: 'https://facebook.com/CsaAgrestina',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required FaIconData icon,
    required Color color,
    required String label,
    required String url,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => _launchURL(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 28 : 18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            FaIcon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            color:
                isDark ? Colors.black.withAlpha(50) : Colors.black.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

String capitalize(String s) =>
    s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '';
