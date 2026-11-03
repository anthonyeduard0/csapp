// lib/web/web_financial_screen.dart
// Dashboard Financeiro Web: Fila de KPIs no topo + Grid de 2 Colunas (7:5) ocupando toda a área útil.

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
  List<AlunoComMensalidades> _alunosComHistorico = [];
  bool _isLoadingHistory = false;
  bool _isCreatingBatchPix = false;

  /// null = Todos os alunos; caso contrário, índice em `_dashboardData.alunos`.
  int? _selectedAlunoIndex;

  /// IDs das faturas selecionadas para pagamento em lote.
  final Set<String> _selectedInvoiceIds = {};

  @override
  void initState() {
    super.initState();
    _dashboardData = DashboardData.fromJson(widget.responseData);
    _fetchCompleteInvoices();
  }

  Future<void> _fetchCompleteInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    if (mounted) {
      setState(() => _isLoadingHistory = true);
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/mensalidades/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        final historico = body
            .map((dynamic item) => AlunoComMensalidades.fromJson(item))
            .toList();

        // Sincroniza mensalidades pendentes nos alunos do dashboard
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

        final updatedDashboard =
            _dashboardData.copyWith(alunos: updatedAlunos);

        setState(() {
          _alunosComHistorico = historico;
          _dashboardData = updatedDashboard;
          _selectedInvoiceIds.removeWhere((id) => ! _todasPendentesAtuais.any((m) => m.id == id));
        });
        widget.onDataReloaded?.call(updatedDashboard);
      }
    } catch (_) {
      // Mantém os dados já presentes em _dashboardData silenciosamente
    } finally {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Future<void> _reloadData() async {
    await _fetchCompleteInvoices();
  }

  List<Aluno> get _alunosFiltrados {
    if (_selectedAlunoIndex == null ||
        _selectedAlunoIndex! < 0 ||
        _selectedAlunoIndex! >= _dashboardData.alunos.length) {
      return _dashboardData.alunos;
    }
    return [_dashboardData.alunos[_selectedAlunoIndex!]];
  }

  List<Mensalidade> get _todasPendentesAtuais {
    final list = <Mensalidade>[];
    for (final aluno in _dashboardData.alunos) {
      list.addAll(aluno.mensalidadesPendentes);
    }
    list.sort((a, b) => a.dataVencimento.compareTo(b.dataVencimento));
    return list;
  }

  List<_FaturaComAluno> get _faturasPendentesFiltradas {
    final items = <_FaturaComAluno>[];
    for (final aluno in _alunosFiltrados) {
      for (final m in aluno.mensalidadesPendentes) {
        items.add(_FaturaComAluno(aluno: aluno, mensalidade: m));
      }
    }
    items.sort((a, b) =>
        a.mensalidade.dataVencimento.compareTo(b.mensalidade.dataVencimento));
    return items;
  }

  List<Mensalidade> get _mensalidadesPagasFiltradas {
    if (_alunosComHistorico.isEmpty) return [];
    final nomesAtivos = _alunosFiltrados
        .map((a) => a.nomeCompleto.trim().toLowerCase())
        .toSet();
    final pagas = <Mensalidade>[];
    for (final alunoHist in _alunosComHistorico) {
      if (nomesAtivos.contains(alunoHist.nomeCompleto.trim().toLowerCase())) {
        pagas.addAll(
          alunoHist.mensalidades.where((m) => m.status == 'PAGA'),
        );
      }
    }
    return pagas;
  }

  int get _totalMensalidadesAnoFiltradas {
    final pendentesCount = _faturasPendentesFiltradas.length;
    final pagasCount = _mensalidadesPagasFiltradas.length;
    final soma = pendentesCount + pagasCount;
    if (soma > 0) return soma;
    return (_alunosFiltrados.isNotEmpty ? _alunosFiltrados.length * 12 : 12);
  }

  double get _totalSelecionado {
    double total = 0.0;
    for (final item in _faturasPendentesFiltradas) {
      if (_selectedInvoiceIds.contains(item.mensalidade.id)) {
        total += item.mensalidade.valorFinal;
      }
    }
    return total;
  }

  void _onToggleInvoiceSelection(bool? isSelected, Mensalidade mensalidade) {
    final pendentesOrdenadas =
        _faturasPendentesFiltradas.map((e) => e.mensalidade).toList();

    if (isSelected == true) {
      Mensalidade? maisAntigaNaoSelecionada;
      for (final fatura in pendentesOrdenadas) {
        if (!_selectedInvoiceIds.contains(fatura.id)) {
          maisAntigaNaoSelecionada = fatura;
          break;
        }
      }
      if (maisAntigaNaoSelecionada != null &&
          mensalidade.mesReferencia
              .isAfter(maisAntigaNaoSelecionada.mesReferencia)) {
        final mesFormatado = capitalize(DateFormat('MMMM \'de\' yyyy', 'pt_BR')
            .format(maisAntigaNaoSelecionada.mesReferencia));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Por favor, selecione ou pague a fatura mais antiga ($mesFormatado) primeiro.',
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }
    }

    setState(() {
      if (isSelected == true) {
        _selectedInvoiceIds.add(mensalidade.id);
      } else {
        // Ao desmarcar uma fatura anterior, desmarca também as posteriores para manter a ordem cronológica
        _selectedInvoiceIds.remove(mensalidade.id);
        for (final fatura in pendentesOrdenadas) {
          if (fatura.mesReferencia.isAfter(mensalidade.mesReferencia)) {
            _selectedInvoiceIds.remove(fatura.id);
          }
        }
      }
    });
  }

  void _toggleSelectAll() {
    final pendentes =
        _faturasPendentesFiltradas.map((e) => e.mensalidade).toList();
    final allSelected = pendentes.isNotEmpty &&
        pendentes.every((m) => _selectedInvoiceIds.contains(m.id));

    setState(() {
      if (allSelected) {
        _selectedInvoiceIds.clear();
      } else {
        for (final m in pendentes) {
          _selectedInvoiceIds.add(m.id);
        }
      }
    });
  }

  Future<void> _pagarFaturaIndividual(Mensalidade mensalidade) async {
    final pendentes =
        _faturasPendentesFiltradas.map((e) => e.mensalidade).toList();
    if (pendentes.isNotEmpty &&
        mensalidade.id != pendentes.first.id &&
        mensalidade.mesReferencia.isAfter(pendentes.first.mesReferencia)) {
      final mesFormatado = capitalize(DateFormat('MMMM \'de\' yyyy', 'pt_BR')
          .format(pendentes.first.mesReferencia));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Por favor, pague a fatura mais antiga ($mesFormatado) primeiro.'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          mensalidadeId: mensalidade.id,
          valor: mensalidade.valorFinal.toStringAsFixed(2),
          mesReferencia:
              DateFormat('MM/yyyy').format(mensalidade.mesReferencia),
        ),
      ),
    );
    if (result == true) {
      _reloadData();
    }
  }

  Future<void> _pagarLoteSelecionado() async {
    if (_selectedInvoiceIds.isEmpty || _isCreatingBatchPix) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessão expirada. Faça login novamente.')),
      );
      return;
    }

    setState(() => _isCreatingBatchPix = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/pagamento/criar-pix-lote/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'mensalidade_ids': _selectedInvoiceIds.toList()}),
      );

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        final pixData = jsonDecode(utf8.decode(response.bodyBytes));
        final valorTotal = _totalSelecionado.toStringAsFixed(2);
        final qtd = _selectedInvoiceIds.length;

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              mensalidadeId: 'lote_${DateTime.now().millisecondsSinceEpoch}',
              valor: valorTotal,
              mesReferencia: '$qtd ${qtd == 1 ? 'fatura' : 'faturas'}',
              initialPixData: pixData,
            ),
          ),
        );

        if (result == true) {
          _selectedInvoiceIds.clear();
          _reloadData();
        }
      } else {
        final error =
            jsonDecode(utf8.decode(response.bodyBytes))['error'] ??
                'Erro ao gerar Pix em lote.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $error'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de conexão: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingBatchPix = false);
      }
    }
  }

  void _abrirHistoricoCompleto() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceHistoryScreen(
          responsavelCpf: _dashboardData.cpfResponsavel,
        ),
      ),
    ).then((v) {
      if (v == true) _reloadData();
    });
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pendentes = _faturasPendentesFiltradas;
    final pagas = _mensalidadesPagasFiltradas;
    final totalAno = _totalMensalidadesAnoFiltradas;

    final double totalEmAbertoValor = pendentes.fold(
      0.0,
      (sum, item) => sum + item.mensalidade.valorFinal,
    );
    final int qtdAtrasadas = pendentes
        .where((item) => item.mensalidade.status == 'ATRASADA')
        .length;
    final Mensalidade? proximaMensalidade =
        pendentes.isNotEmpty ? pendentes.first.mensalidade : null;

    return RefreshIndicator(
      onRefresh: _reloadData,
      color: primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeBanner(isDark, pendentes.length, pagas.length),
            const SizedBox(height: 24),

            // 1. TOPO: FILA DE KPIs OCUPANDO 100% DA LARGURA
            _buildKpiRow(
              isDark: isDark,
              totalEmAbertoValor: totalEmAbertoValor,
              qtdPendentes: pendentes.length,
              qtdAtrasadas: qtdAtrasadas,
              proximaMensalidade: proximaMensalidade,
              qtdPagas: pagas.length,
              totalAno: totalAno,
            ),
            const SizedBox(height: 24),

            // 2. CORPO PRINCIPAL EM GRID DE 2 COLUNAS (flex 7 : flex 5)
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 820;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: _buildLeftColumn(
                          context: context,
                          isDark: isDark,
                          pendentes: pendentes,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 5,
                        child: _buildRightColumn(
                          context: context,
                          isDark: isDark,
                          pendentes: pendentes,
                          pagas: pagas,
                          totalAno: totalAno,
                          totalEmAbertoValor: totalEmAbertoValor,
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLeftColumn(
                      context: context,
                      isDark: isDark,
                      pendentes: pendentes,
                    ),
                    const SizedBox(height: 24),
                    _buildRightColumn(
                      context: context,
                      isDark: isDark,
                      pendentes: pendentes,
                      pagas: pagas,
                      totalAno: totalAno,
                      totalEmAbertoValor: totalEmAbertoValor,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(bool isDark, int qtdAbertas, int qtdPagas) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
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
            color: primaryColor.withAlpha(55),
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
              color: Colors.white.withAlpha(28),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bem-vindo(a), ${_dashboardData.nomeResponsavel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Painel de controle financeiro escolar • Gerencie mensalidades, vencimentos e pagamentos via Pix em tempo real.',
                  style: TextStyle(
                    color: Colors.white.withAlpha(210),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: _abrirHistoricoCompleto,
            icon: const Icon(Icons.receipt_long_rounded,
                color: Colors.white, size: 18),
            label: const Text(
              'Histórico Completo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white.withAlpha(20),
              side: const BorderSide(color: Colors.white38),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow({
    required bool isDark,
    required double totalEmAbertoValor,
    required int qtdPendentes,
    required int qtdAtrasadas,
    required Mensalidade? proximaMensalidade,
    required int qtdPagas,
    required int totalAno,
  }) {
    final formatadorMoeda =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final String proximoVencTexto = proximaMensalidade != null
        ? DateFormat('dd/MM/yyyy').format(proximaMensalidade.dataVencimento)
        : 'Em dia';
    final String proximoVencSub = proximaMensalidade != null
        ? 'Ref: ${capitalize(DateFormat('MMMM/yyyy', 'pt_BR').format(proximaMensalidade.mesReferencia))}'
        : 'Nenhum vencimento pendente';

    final Aluno? alunoRef =
        _alunosFiltrados.isNotEmpty ? _alunosFiltrados.first : null;
    final String statusMatricula =
        alunoRef != null ? alunoRef.statusMatricula : 'Ativa';
    final String validadeSub = alunoRef != null
        ? '${alunoRef.serieAno} • Validade: ${alunoRef.validadeMatriculaFormatada ?? 'Anual'}'
        : '${_dashboardData.alunos.length} aluno(s) vinculado(s)';

    final cards = [
      _buildKpiCard(
        isDark: isDark,
        title: 'Total em Aberto',
        value: formatadorMoeda.format(totalEmAbertoValor),
        subtitle: qtdPendentes == 0
            ? 'Nenhuma fatura pendente'
            : '$qtdPendentes ${qtdPendentes == 1 ? 'fatura aberta' : 'faturas abertas'}${qtdAtrasadas > 0 ? ' ($qtdAtrasadas em atraso)' : ''}',
        icon: Icons.monetization_on_rounded,
        accent: qtdAtrasadas > 0
            ? const Color(0xFFEF4444)
            : (qtdPendentes > 0
                ? const Color(0xFFF59E0B)
                : const Color(0xFF10B981)),
      ),
      _buildKpiCard(
        isDark: isDark,
        title: 'Próximo Vencimento',
        value: proximoVencTexto,
        subtitle: proximoVencSub,
        icon: Icons.event_rounded,
        accent: proximaMensalidade?.status == 'ATRASADA'
            ? const Color(0xFFEF4444)
            : const Color(0xFF3B82F6),
      ),
      _buildKpiCard(
        isDark: isDark,
        title: 'Mensalidades Quitadas',
        value: _isLoadingHistory && _alunosComHistorico.isEmpty
            ? '...'
            : '$qtdPagas de $totalAno',
        subtitle: totalAno > 0
            ? '${((qtdPagas / totalAno) * 100).clamp(0, 100).toStringAsFixed(0)}% do ciclo letivo quitado'
            : 'Histórico sincronizado',
        icon: Icons.task_alt_rounded,
        accent: const Color(0xFF10B981),
      ),
      _buildKpiCard(
        isDark: isDark,
        title: 'Status da Matrícula',
        value: statusMatricula,
        subtitle: validadeSub,
        icon: Icons.verified_rounded,
        accent: const Color(0xFF6366F1),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
              const SizedBox(width: 16),
              Expanded(child: cards[2]),
              const SizedBox(width: 16),
              Expanded(child: cards[3]),
            ],
          );
        }
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 16),
                Expanded(child: cards[1]),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: 16),
                Expanded(child: cards[3]),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required bool isDark,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isDark ? Colors.black.withAlpha(45) : Colors.black.withAlpha(8),
            blurRadius: 14,
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
                  color: accent.withAlpha(isDark ? 35 : 22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // COLUNA ESQUERDA (flex: 7): Seletor de Aluno + Ação em Lote + Lista de Faturas
  // ===========================================================================

  Widget _buildLeftColumn({
    required BuildContext context,
    required bool isDark,
    required List<_FaturaComAluno> pendentes,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_dashboardData.alunos.length > 1) ...[
          _buildAlunoSelectorBar(isDark),
          const SizedBox(height: 20),
        ],
        if (pendentes.isNotEmpty) ...[
          _buildBatchActionBar(isDark, pendentes),
          const SizedBox(height: 20),
        ],
        _buildPendingInvoicesSection(context, isDark, pendentes),
      ],
    );
  }

  Widget _buildAlunoSelectorBar(bool isDark) {
    return _buildCard(
      isDark: isDark,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people_alt_rounded,
                size: 18,
                color: isDark ? const Color(0xFF60A5FA) : primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Filtrar por Aluno Vinculado',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildAlunoFilterChip(
                label: 'Todos (${_dashboardData.alunos.length})',
                subtitle: 'Visão consolidada',
                isSelected: _selectedAlunoIndex == null,
                isDark: isDark,
                onTap: () => setState(() {
                  _selectedAlunoIndex = null;
                  _selectedInvoiceIds.clear();
                }),
              ),
              ...List.generate(_dashboardData.alunos.length, (index) {
                final aluno = _dashboardData.alunos[index];
                return _buildAlunoFilterChip(
                  label: aluno.nomeCompleto,
                  subtitle: aluno.serieAno,
                  isSelected: _selectedAlunoIndex == index,
                  isDark: isDark,
                  onTap: () => setState(() {
                    _selectedAlunoIndex = index;
                    _selectedInvoiceIds.clear();
                  }),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlunoFilterChip({
    required String label,
    required String subtitle,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeColor = isDark ? const Color(0xFF3B82F6) : primaryColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withAlpha(isDark ? 45 : 20)
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : (isDark ? Colors.white12 : Colors.grey.shade200),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.school_outlined,
                size: 16,
                color: isSelected
                    ? (isDark ? const Color(0xFF60A5FA) : primaryColor)
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? (isDark ? Colors.white : primaryColor)
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBatchActionBar(
      bool isDark, List<_FaturaComAluno> pendentes) {
    final formatadorMoeda =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final allSelected = pendentes.isNotEmpty &&
        pendentes
            .every((item) => _selectedInvoiceIds.contains(item.mensalidade.id));
    final selectedCount = _selectedInvoiceIds.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selectedCount > 0
              ? (isDark ? const Color(0xFF3B82F6) : primaryColor)
              : (isDark ? Colors.white10 : Colors.grey.shade200),
          width: selectedCount > 0 ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isDark ? Colors.black.withAlpha(45) : Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _toggleSelectAll,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    allSelected
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    allSelected ? 'Desmarcar todas' : 'Selecionar todas',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: selectedCount > 0
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? const Color(0xFF3B82F6)
                                  : primaryColor)
                              .withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$selectedCount ${selectedCount == 1 ? 'selecionada' : 'selecionadas'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? const Color(0xFF60A5FA) : primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Total: ${formatadorMoeda.format(_totalSelecionado)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Selecione uma ou mais faturas na ordem cronológica para pagar em lote via Pix.',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed:
                selectedCount > 0 && !_isCreatingBatchPix
                    ? _pagarLoteSelecionado
                    : null,
            icon: _isCreatingBatchPix
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.pix_rounded, size: 18),
            label: Text(
              selectedCount > 0
                  ? 'Pagar Selecionadas ($selectedCount)'
                  : 'Pagar em Lote',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF3B82F6) : primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  isDark ? const Color(0xFF334155) : Colors.grey.shade200,
              disabledForegroundColor:
                  isDark ? Colors.grey.shade500 : Colors.grey.shade500,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingInvoicesSection(
    BuildContext context,
    bool isDark,
    List<_FaturaComAluno> pendentes,
  ) {
    return _buildCard(
      isDark: isDark,
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
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Faturas Pendentes e em Atraso',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : primaryColor,
                      ),
                    ),
                    Text(
                      pendentes.isEmpty
                          ? 'Todas as mensalidades estão em dia'
                          : 'Clique em uma fatura para selecionar ou pague individualmente via Pix',
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: pendentes.isEmpty
                      ? Colors.green.withAlpha(30)
                      : Colors.orange.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${pendentes.length} ${pendentes.length == 1 ? 'fatura' : 'faturas'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: pendentes.isEmpty
                        ? (isDark
                            ? const Color(0xFF4ADE80)
                            : Colors.green.shade700)
                        : (isDark
                            ? const Color(0xFFFBBF24)
                            : Colors.orange.shade800),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (pendentes.isEmpty)
            _buildAllPaidEmptyState(isDark)
          else
            Column(
              children: pendentes
                  .map((item) => _buildDetailedPendingInvoiceCard(
                        item: item,
                        isDark: isDark,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAllPaidEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF064E3B).withAlpha(80)
                  : Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_user_rounded,
              size: 48,
              color: isDark ? const Color(0xFF4ADE80) : Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tudo em dia!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nenhuma mensalidade pendente ou atrasada para o filtro selecionado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _abrirHistoricoCompleto,
            icon: const Icon(Icons.history_rounded, size: 18),
            label: const Text('Consultar Faturas Quitadas'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? const Color(0xFF60A5FA) : primaryColor,
              side: BorderSide(
                color: isDark ? const Color(0xFF60A5FA) : primaryColor,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedPendingInvoiceCard({
    required _FaturaComAluno item,
    required bool isDark,
  }) {
    final mensalidade = item.mensalidade;
    final aluno = item.aluno;
    final isSelected = _selectedInvoiceIds.contains(mensalidade.id);
    final isAtrasada = mensalidade.status == 'ATRASADA';

    final formatadorMoeda =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final mesAno = capitalize(
        DateFormat('MMMM \'de\' yyyy', 'pt_BR').format(mensalidade.mesReferencia));
    final vencimentoStr =
        DateFormat('dd/MM/yyyy').format(mensalidade.dataVencimento);

    final statusColor = isAtrasada
        ? (isDark ? const Color(0xFFF87171) : Colors.red.shade800)
        : (isDark ? const Color(0xFFFBBF24) : Colors.orange.shade800);
    final statusBg = isAtrasada
        ? (isDark ? const Color(0xFF7F1D1D).withAlpha(90) : Colors.red.shade50)
        : (isDark
            ? const Color(0xFF78350F).withAlpha(90)
            : Colors.orange.shade50);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF1E3A8A).withAlpha(55) : const Color(0xFFF0F7FF))
            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? (isDark ? const Color(0xFF60A5FA) : primaryColor)
              : (isDark ? Colors.white12 : Colors.grey.shade200),
          width: isSelected ? 1.8 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onToggleInvoiceSelection(!isSelected, mensalidade),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: (val) =>
                          _onToggleInvoiceSelection(val, mensalidade),
                      activeColor:
                          isDark ? const Color(0xFF3B82F6) : primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Mensalidade de $mesAno',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : primaryColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isAtrasada
                                          ? Icons.warning_amber_rounded
                                          : Icons.schedule_rounded,
                                      size: 13,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isAtrasada ? 'EM ATRASO' : 'PENDENTE',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 16,
                            runSpacing: 4,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person_outline_rounded,
                                    size: 14,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${aluno.nomeCompleto} (${aluno.serieAno})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.event_rounded,
                                    size: 14,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Vencimento: $vencimentoStr',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isAtrasada
                                          ? statusColor
                                          : (isDark
                                              ? Colors.grey.shade300
                                              : Colors.grey.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatadorMoeda.format(mensalidade.valorFinal),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _pagarFaturaIndividual(mensalidade),
                          icon: const Icon(Icons.pix_rounded, size: 16),
                          label: const Text(
                            'Pagar com Pix',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? const Color(0xFF3B82F6)
                                : primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isAtrasada) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                    ),
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 8,
                      children: [
                        _buildMiniBreakdown(
                          'Valor Nominal',
                          formatadorMoeda.format(mensalidade.valorNominal),
                          isDark,
                        ),
                        _buildMiniBreakdown(
                          'Multa (2%)',
                          formatadorMoeda.format(mensalidade.multa),
                          isDark,
                        ),
                        _buildMiniBreakdown(
                          'Juros (${mensalidade.diasAtraso} dias)',
                          formatadorMoeda.format(mensalidade.juros),
                          isDark,
                        ),
                      ],
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

  Widget _buildMiniBreakdown(String label, String value, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // COLUNA DIREITA (flex: 5): Quitação Anual + Encargos + Atalho Histórico
  // ===========================================================================

  Widget _buildRightColumn({
    required BuildContext context,
    required bool isDark,
    required List<_FaturaComAluno> pendentes,
    required List<Mensalidade> pagas,
    required int totalAno,
    required double totalEmAbertoValor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnnualProgressCard(
          isDark: isDark,
          qtdPagas: pagas.length,
          qtdPendentes: pendentes.length,
          totalAno: totalAno,
          pagasList: pagas,
          totalEmAbertoValor: totalEmAbertoValor,
        ),
        const SizedBox(height: 20),
        _buildImportantRulesCard(isDark),
        const SizedBox(height: 20),
        _buildHistoryShortcutCard(isDark),
      ],
    );
  }

  Widget _buildAnnualProgressCard({
    required bool isDark,
    required int qtdPagas,
    required int qtdPendentes,
    required int totalAno,
    required List<Mensalidade> pagasList,
    required double totalEmAbertoValor,
  }) {
    final formatadorMoeda =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final double progress =
        totalAno > 0 ? (qtdPagas / totalAno).clamp(0.0, 1.0) : 0.0;
    final double totalQuitadoValor =
        pagasList.fold(0.0, (sum, m) => sum + m.valorFinal);

    return _buildCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(isDark ? 35 : 22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumo de Quitação Anual',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : primaryColor,
                      ),
                    ),
                    Text(
                      'Progresso das mensalidades do ano letivo',
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
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor:
                  isDark ? const Color(0xFF0F172A) : Colors.grey.shade200,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProgressStatBox(
                  isDark: isDark,
                  label: 'Quitadas',
                  value: '$qtdPagas faturas',
                  subvalue: formatadorMoeda.format(totalQuitadoValor),
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProgressStatBox(
                  isDark: isDark,
                  label: 'Em Aberto',
                  value: '$qtdPendentes faturas',
                  subvalue: formatadorMoeda.format(totalEmAbertoValor),
                  color: qtdPendentes > 0
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStatBox({
    required bool isDark,
    required String label,
    required String value,
    required String subvalue,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subvalue,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportantRulesCard(bool isDark) {
    return _buildCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withAlpha(isDark ? 35 : 20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Informações Importantes e Encargos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRuleItem(
            isDark: isDark,
            icon: Icons.bolt_rounded,
            iconColor: const Color(0xFF10B981),
            title: 'Baixa Automática via Pix',
            description:
                'Pagamentos realizados com QR Code ou Pix Copia e Cola têm confirmação automática em poucos segundos.',
          ),
          const SizedBox(height: 12),
          _buildRuleItem(
            isDark: isDark,
            icon: Icons.percent_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: 'Multa e Juros por Atraso',
            description:
                'Após a data de vencimento, incide multa contratual de 2% sobre o valor nominal acrescida de juros moratórios diários.',
          ),
          const SizedBox(height: 12),
          _buildRuleItem(
            isDark: isDark,
            icon: Icons.sort_rounded,
            iconColor: const Color(0xFF6366F1),
            title: 'Ordem Cronológica de Quitação',
            description:
                'As mensalidades em aberto devem ser quitadas da mais antiga para a mais recente, individualmente ou em lote.',
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryShortcutCard(bool isDark) {
    return _buildCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acesso Rápido e Atendimento',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : primaryColor,
            ),
          ),
          const SizedBox(height: 14),
          Material(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _abrirHistoricoCompleto,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryColor, accentColor],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ver Histórico Completo de Faturas',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : primaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Acesse recibos, faturas pagas e seleção em lote',
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
                      size: 16,
                      color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Divider(
            height: 1,
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            'Canais Oficiais Colégio Santo Antônio',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
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

  Widget _buildCard({
    required bool isDark,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
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
      child: child,
    );
  }
}

class _FaturaComAluno {
  final Aluno aluno;
  final Mensalidade mensalidade;

  const _FaturaComAluno({
    required this.aluno,
    required this.mensalidade,
  });
}

String capitalize(String s) =>
    s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '';
