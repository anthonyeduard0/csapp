import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:educsa/providers/theme_provider.dart';
import 'package:educsa/screens/main_screen.dart'
    show Mensalidade, AlunoComMensalidades, capitalize;

/// Versão Desktop/Tablet (largura >= 768px) da tela "Minhas Faturas".
///
/// É um widget de apresentação: todo o estado (seleção, aba ativa, fetch e
/// pagamento) vive em `InvoiceHistoryScreen`, que repassa os dados e callbacks.
/// Assim, redimensionar a janela do navegador não perde seleção nem estado.
class WebInvoiceHistoryScreen extends StatelessWidget {
  /// Snapshot do carregamento das faturas (loading / erro / dados).
  final AsyncSnapshot<List<AlunoComMensalidades>> snapshot;

  /// Todas as faturas já carregadas (ordenadas por mês de referência).
  final List<Mensalidade> allInvoices;

  /// IDs das faturas selecionadas e total correspondente.
  final Set<String> selectedInvoiceIds;
  final double totalSelecionado;

  /// 0 = "Em aberto", 1 = "Pagas".
  final int tabIndex;
  final ValueChanged<int> onTabChanged;

  final Future<void> Function() onRefresh;
  final VoidCallback onBack;
  final void Function(bool? isSelected, Mensalidade mensalidade)
      onInvoiceSelected;
  final void Function(BuildContext context, Mensalidade mensalidade)
      onPayIndividual;
  final void Function(BuildContext context) onPaySelected;
  final void Function(List<Mensalidade> pendentes) onSelectAll;
  final VoidCallback onClearSelection;

  const WebInvoiceHistoryScreen({
    super.key,
    required this.snapshot,
    required this.allInvoices,
    required this.selectedInvoiceIds,
    required this.totalSelecionado,
    required this.tabIndex,
    required this.onTabChanged,
    required this.onRefresh,
    required this.onBack,
    required this.onInvoiceSelected,
    required this.onPayIndividual,
    required this.onPaySelected,
    required this.onSelectAll,
    required this.onClearSelection,
  });

  static const Color primaryColor = Color(0xFF1D449B);
  static const Color accentColor = Color(0xFF25B6E8);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mensalidadesEmAberto = allInvoices
        .where((m) => m.status == 'PENDENTE' || m.status == 'ATRASADA')
        .toList();
    final historicoFaturas = allInvoices
        .where((m) => m.status == 'PAGA' || m.status == 'CANCELADA')
        .toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF0F4FF),
      body: Column(
        children: [
          _buildTopBar(context, isDark),
          Expanded(
            child: RefreshIndicator(
              onRefresh: onRefresh,
              color: primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeBanner(
                          isDark: isDark,
                          totalAbertas: mensalidadesEmAberto.length,
                          totalPagas: historicoFaturas.length,
                        ),
                        const SizedBox(height: 28),
                        _buildTabsCard(
                          isDark: isDark,
                          totalAbertas: mensalidadesEmAberto.length,
                          totalPagas: historicoFaturas.length,
                          pendentes: mensalidadesEmAberto,
                        ),
                        const SizedBox(height: 24),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          _buildLoadingState(isDark)
                        else if (snapshot.hasError)
                          _buildErrorState(snapshot.error.toString(), isDark)
                        else if (!snapshot.hasData || snapshot.data!.isEmpty)
                          _buildEmptyState(isDark)
                        else
                          _buildTabContent(
                            context: context,
                            isDark: isDark,
                            abertas: mensalidadesEmAberto,
                            pagas: historicoFaturas,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: (selectedInvoiceIds.isNotEmpty && tabIndex == 0)
          ? _buildPaymentBar(context, isDark)
          : null,
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDark) {
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
              message: 'Voltar para o Financeiro',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onBack,
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
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Minhas Faturas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : primaryColor,
                  ),
                ),
                Text(
                  'Histórico completo e gestão de mensalidades',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
              message: 'Atualizar faturas',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onRefresh,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: isDark ? Colors.white70 : primaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String text,
    required Color dotColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner({
    required bool isDark,
    required int totalAbertas,
    required int totalPagas,
  }) {
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
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Central de Faturas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Consulte todas as mensalidades, verifique vencimentos e realize pagamentos.',
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatChip(
                text: '$totalAbertas em aberto',
                dotColor: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 10),
              _buildStatChip(
                text: '$totalPagas quitadas',
                dotColor: const Color(0xFF4ADE80),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabsCard({
    required bool isDark,
    required int totalAbertas,
    required int totalPagas,
    required List<Mensalidade> pendentes,
  }) {
    final isAbertas = tabIndex == 0;
    final allSelected = pendentes.isNotEmpty &&
        pendentes.every((m) => selectedInvoiceIds.contains(m.id));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withAlpha(50) : Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabButton(
            isDark: isDark,
            title: 'Em aberto',
            count: totalAbertas,
            isSelected: isAbertas,
            badgeColor: isDark ? const Color(0xFFEF4444) : Colors.red.shade600,
            onTap: () => onTabChanged(0),
          ),
          const SizedBox(width: 10),
          _buildTabButton(
            isDark: isDark,
            title: 'Pagas',
            count: totalPagas,
            isSelected: !isAbertas,
            badgeColor:
                isDark ? const Color(0xFF22C55E) : Colors.green.shade600,
            onTap: () => onTabChanged(1),
          ),
          const Spacer(),
          if (isAbertas && pendentes.isNotEmpty)
            Flexible(
              child: TextButton.icon(
                onPressed: () {
                  if (allSelected) {
                    onClearSelection();
                  } else {
                    onSelectAll(pendentes);
                  }
                },
                icon: Icon(
                  allSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
                  size: 18,
                  color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                ),
                label: Text(
                  allSelected ? 'Desmarcar todas' : 'Selecionar todas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required bool isDark,
    required String title,
    required int count,
    required bool isSelected,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? const Color(0xFF334155)
                    : primaryColor.withAlpha(20))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                    width: 1.5,
                  )
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : primaryColor)
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(isSelected ? 230 : 50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent({
    required BuildContext context,
    required bool isDark,
    required List<Mensalidade> abertas,
    required List<Mensalidade> pagas,
  }) {
    final isAbertas = tabIndex == 0;
    final listParaExibir = isAbertas ? abertas : pagas.reversed.toList();

    if (listParaExibir.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
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
                isAbertas ? Icons.verified_user_rounded : Icons.history_rounded,
                size: 48,
                color: isDark ? const Color(0xFF4ADE80) : Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isAbertas ? 'Tudo em dia!' : 'Nenhuma fatura paga no histórico',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isAbertas
                  ? 'Você não possui nenhuma fatura pendente de pagamento.'
                  : 'Quando suas faturas forem quitadas, elas aparecerão aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: listParaExibir
          .map((fatura) => _buildInvoiceCard(
                context,
                fatura,
                isPending: isAbertas,
                isDark: isDark,
              ))
          .toList(),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'PAGA':
        return {
          'text': 'PAGO',
          'color': Colors.green.shade800,
          'bgColor': Colors.green.shade100,
          'icon': Icons.check_circle_rounded
        };
      case 'ATRASADA':
        return {
          'text': 'EM ATRASO',
          'color': Colors.red.shade800,
          'bgColor': Colors.red.shade100,
          'icon': Icons.warning_rounded
        };
      case 'PENDENTE':
        return {
          'text': 'PENDENTE',
          'color': Colors.orange.shade800,
          'bgColor': Colors.orange.shade100,
          'icon': Icons.schedule_rounded
        };
      case 'CANCELADA':
        return {
          'text': 'CANCELADA',
          'color': Colors.grey.shade700,
          'bgColor': Colors.grey.shade300,
          'icon': Icons.cancel_rounded
        };
      default:
        return {
          'text': status,
          'color': Colors.black,
          'bgColor': Colors.grey.shade200,
          'icon': Icons.help_outline_rounded
        };
    }
  }

  /// Retorna o aluno dono da fatura somente quando há mais de 1 aluno vinculado.
  AlunoComMensalidades? _alunoDaFatura(Mensalidade mensalidade) {
    final alunos = snapshot.data;
    if (alunos == null || alunos.length <= 1) return null;
    for (final aluno in alunos) {
      if (aluno.mensalidades.any((m) => m.id == mensalidade.id)) return aluno;
    }
    return null;
  }

  Widget _buildInvoiceCard(
    BuildContext context,
    Mensalidade mensalidade, {
    required bool isPending,
    required bool isDark,
  }) {
    final bool isSelected = selectedInvoiceIds.contains(mensalidade.id);
    final formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formatadorMesAno = DateFormat('MMMM \'de\' yyyy', 'pt_BR');
    final formatadorVencimento = DateFormat('dd/MM/yyyy');
    final mesFormatado =
        capitalize(formatadorMesAno.format(mensalidade.mesReferencia));
    final bool isJaneiro = mensalidade.mesReferencia.month == 1;
    final AlunoComMensalidades? alunoDaFatura = _alunoDaFatura(mensalidade);
    final String anoRef = DateFormat('yyyy').format(mensalidade.mesReferencia);
    final String tituloFatura = isJaneiro
        ? 'Renovação de Matrícula (Janeiro/$anoRef)'
        : 'Mensalidade de $mesFormatado';
    final statusInfo = _getStatusInfo(mensalidade.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark
            ? (isSelected ? const Color(0xFF1E293B) : const Color(0xFF111827))
            : (isSelected ? const Color(0xFFF0F7FF) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? (isDark ? const Color(0xFF60A5FA) : primaryColor)
              : (isDark ? Colors.white10 : Colors.grey.shade200),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? (isDark
                    ? const Color(0xFF60A5FA).withAlpha(40)
                    : primaryColor.withAlpha(30))
                : (isDark ? Colors.black.withAlpha(40) : Colors.black.withAlpha(8)),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isPending
              ? () => onInvoiceSelected(!isSelected, mensalidade)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                if (isPending) ...[
                  Transform.scale(
                    scale: 1.15,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (bool? val) =>
                          onInvoiceSelected(val, mensalidade),
                      activeColor: primaryColor,
                      checkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155)
                        : primaryColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isJaneiro) ...[
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E3A8A)
                                    : const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF3B82F6)
                                      : const Color(0xFF93C5FD),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.school_rounded,
                                    size: 12,
                                    color: isDark
                                        ? const Color(0xFF93C5FD)
                                        : const Color(0xFF1D4ED8),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'MATRÍCULA',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      color: isDark
                                          ? const Color(0xFF93C5FD)
                                          : const Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          Expanded(
                            child: Text(
                              tituloFatura,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : primaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (isJaneiro) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Efetiva a renovação de matrícula online',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (alunoDaFatura != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 15,
                              color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                (alunoDaFatura.serieAno != null &&
                                        alunoDaFatura.serieAno!.isNotEmpty)
                                    ? '${alunoDaFatura.nomeCompleto} • ${alunoDaFatura.serieAno}'
                                    : alunoDaFatura.nomeCompleto,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF60A5FA)
                                      : primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: isDark ? Colors.grey.shade400 : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Vencimento: ${formatadorVencimento.format(mensalidade.dataVencimento)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (mensalidade.status == 'ATRASADA') ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '• ${mensalidade.diasAtraso} dias em atraso',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusInfo['bgColor'],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusInfo['icon'],
                        size: 14,
                        color: statusInfo['color'],
                      ),
                      const SizedBox(width: 5),
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
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Valor final',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      formatadorMoeda.format(mensalidade.valorFinal),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                if (isPending) ...[
                  const SizedBox(width: 20),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryColor, accentColor],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withAlpha(60),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => onPayIndividual(context, mensalidade),
                      icon: const Icon(Icons.pix, color: Colors.white, size: 16),
                      label: const Text(
                        'Pagar Pix',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentBar(BuildContext context, bool isDark) {
    final formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withAlpha(8),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 80 : 25),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
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
                  Icons.checklist_rounded,
                  color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${selectedInvoiceIds.length} fatura(s) selecionada(s)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      formatadorMoeda.format(totalSelecionado),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onClearSelection,
                child: Text(
                  'Limpar seleção',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryColor, accentColor],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withAlpha(80),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => onPaySelected(context),
                  icon: const Icon(Icons.pix, color: Colors.white, size: 18),
                  label: Text(
                    'Pagar com Pix (${selectedInvoiceIds.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _buildLoadingState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
      ),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Carregando suas faturas...',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF450A0A).withAlpha(80) : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFFDC2626).withAlpha(60)
              : Colors.red.shade200,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
          const SizedBox(height: 14),
          Text(
            'Erro ao carregar faturas: $error',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? const Color(0xFFFCA5A5) : Colors.red.shade700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white : primaryColor,
              side: BorderSide(color: isDark ? Colors.white30 : primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded,
              size: 56,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Nenhuma fatura encontrada',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

