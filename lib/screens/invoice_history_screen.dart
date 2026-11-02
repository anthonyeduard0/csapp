import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:educsa/providers/theme_provider.dart';
import 'package:educsa/screens/payment_screen.dart';
import 'package:educsa/screens/main_screen.dart'; // Mantive caso precise do AlunoComMensalidades
import 'package:educsa/web/web_invoice_history_screen.dart';
import 'package:educsa/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Necessário para pegar o token

class InvoiceHistoryScreen extends StatefulWidget {
  // ATENÇÃO: O responsavelCpf não é mais usado na URL, mas pode ser útil manter
  // para exibição ou lógica interna se necessário.
  final String responsavelCpf;
  const InvoiceHistoryScreen({super.key, required this.responsavelCpf});
  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> with TickerProviderStateMixin {
  Future<List<AlunoComMensalidades>>? _historyFuture;
  final Set<String> _selectedInvoiceIds = {};
  double _totalSelecionado = 0.0;
  List<Mensalidade> _allInvoices = [];
  bool _didPay = false; 
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;

  static const Color primaryColor = Color(0xFF1D449B);
  static const Color accentColor = Color(0xFF25B6E8);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const double _desktopBreakpoint = 768; // largura mínima da versão Desktop/Tablet

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchInvoiceHistory();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      _historyFuture = _fetchInvoiceHistory();
      _selectedInvoiceIds.clear();
      _totalSelecionado = 0.0;
    });
  }

  Future<List<AlunoComMensalidades>> _fetchInvoiceHistory() async {
    // --- ATUALIZAÇÃO: Busca Token e Remove CPF da URL ---
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }

    // A URL agora não recebe mais ?cpf=...
    final url = Uri.parse('${ApiConfig.baseUrl}/mensalidades/');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', // Header de Autenticação
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        final data = body.map((dynamic item) => AlunoComMensalidades.fromJson(item)).toList();
        _allInvoices = data.expand((aluno) => aluno.mensalidades).toList();
        _allInvoices.sort((a, b) => a.mesReferencia.compareTo(b.mesReferencia));
        if (mounted) _fadeController.forward();
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Sessão inválida. Por favor, saia e entre novamente.');
      } else {
        throw Exception('Falha ao carregar o histórico de faturas.');
      }
    } catch (e) {
      throw Exception('Erro de conexão: ${e.toString()}');
    }
  }

  void _onInvoiceSelected(bool? isSelected, Mensalidade mensalidade) {
    // Lógica mantida...
    final mensalidadesEmAberto = _allInvoices.where((m) => m.status == 'PENDENTE' || m.status == 'ATRASADA').toList();
    if (isSelected == true) {
      Mensalidade? faturaMaisAntigaNaoSelecionada;
      for (final fatura in mensalidadesEmAberto) {
        if (!_selectedInvoiceIds.contains(fatura.id)) {
          faturaMaisAntigaNaoSelecionada = fatura;
          break;
        }
      }
      if (faturaMaisAntigaNaoSelecionada != null && mensalidade.mesReferencia.isAfter(faturaMaisAntigaNaoSelecionada.mesReferencia)) {
        final mesFormatado = DateFormat('MMMM \'de\' yyyy', 'pt_BR').format(faturaMaisAntigaNaoSelecionada.mesReferencia);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Por favor, pague ou selecione a fatura de ${capitalize(mesFormatado)} primeiro.'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        return;
      }
    }
    setState(() {
      if (isSelected == true) {
        _selectedInvoiceIds.add(mensalidade.id);
        _totalSelecionado += mensalidade.valorFinal;
      } else {
        _selectedInvoiceIds.remove(mensalidade.id);
        _totalSelecionado -= mensalidade.valorFinal;
      }
    });
  }

  Future<void> _pagarSelecionados(BuildContext context) async {
    if (!mounted) return;
    
    // --- ATUALIZAÇÃO: Busca Token para Pagamento em Lote ---
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro de autenticação.')));
      }
      return;
    }

    if (!context.mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final url = Uri.parse('${ApiConfig.baseUrl}/pagamento/criar-pix-lote/');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Header de Autenticação
        },
        body: jsonEncode({'mensalidade_ids': _selectedInvoiceIds.toList()}),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final pixData = jsonDecode(utf8.decode(response.bodyBytes));
        final result = await navigator.push(MaterialPageRoute(
          builder: (context) => PaymentScreen(
            mensalidadeId: 'lote_${DateTime.now().millisecondsSinceEpoch}',
            valor: _totalSelecionado.toStringAsFixed(2),
            mesReferencia: '${_selectedInvoiceIds.length} faturas',
            initialPixData: pixData,
          ),
        ));
        
        if (result == true) {
          _didPay = true;
          _refreshData();
        }
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Erro desconhecido';
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Erro: $error'), backgroundColor: Colors.red));
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Erro de conexão: $e')));
    }
  }

  Future<void> _pagarFaturaIndividual(BuildContext context, Mensalidade mensalidade) async {
    final mensalidadesEmAberto = _allInvoices
        .where((m) => m.status == 'PENDENTE' || m.status == 'ATRASADA')
        .toList();
    if (mensalidadesEmAberto.isNotEmpty &&
        mensalidade.id != mensalidadesEmAberto.first.id &&
        mensalidade.mesReferencia.isAfter(mensalidadesEmAberto.first.mesReferencia)) {
      final mesFormatado = capitalize(DateFormat('MMMM \'de\' yyyy', 'pt_BR')
          .format(mensalidadesEmAberto.first.mesReferencia));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Por favor, pague a fatura mais antiga ($mesFormatado) primeiro.'),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
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
      _didPay = true;
      _refreshData();
    }
  }

  void _selecionarTodasFaturas(List<Mensalidade> pendentes) {
    setState(() {
      _selectedInvoiceIds.clear();
      _totalSelecionado = 0.0;
      for (final fatura in pendentes) {
        _selectedInvoiceIds.add(fatura.id);
        _totalSelecionado += fatura.valorFinal;
      }
    });
  }

  void _limparSelecao() {
    setState(() {
      _selectedInvoiceIds.clear();
      _totalSelecionado = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // O FutureBuilder fica acima do LayoutBuilder para que ambos os layouts
    // (mobile e web) compartilhem exatamente o mesmo estado de carregamento.
    return FutureBuilder<List<AlunoComMensalidades>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= _desktopBreakpoint) {
              return WebInvoiceHistoryScreen(
                snapshot: snapshot,
                allInvoices: _allInvoices,
                selectedInvoiceIds: _selectedInvoiceIds,
                totalSelecionado: _totalSelecionado,
                tabIndex: _tabController.index,
                onTabChanged: (index) => _tabController.index = index,
                onRefresh: _refreshData,
                onBack: () => Navigator.pop(context, _didPay),
                onInvoiceSelected: _onInvoiceSelected,
                onPayIndividual: _pagarFaturaIndividual,
                onPaySelected: _pagarSelecionados,
                onSelectAll: _selecionarTodasFaturas,
                onClearSelection: _limparSelecao,
              );
            }
            return _buildMobileLayout(context, snapshot);
          },
        );
      },
    );
  }

  // ===========================================================================
  // LAYOUT MOBILE NATIVO (largura < 768px)
  // Construído para telas verticais estreitas (320px a 600px): sem Rows
  // sobrecarregadas, textos com Expanded/ellipsis e cards em "2 andares".
  // ===========================================================================

  Widget _buildMobileLayout(
      BuildContext context, AsyncSnapshot<List<AlunoComMensalidades>> snapshot) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mensalidadesEmAberto = _allInvoices
        .where((m) => m.status == 'PENDENTE' || m.status == 'ATRASADA')
        .toList();
    final historicoFaturas = _allInvoices
        .where((m) => m.status == 'PAGA' || m.status == 'CANCELADA')
        .toList();
    final isAbertas = _tabController.index == 0;

    Widget body;
    if (snapshot.connectionState == ConnectionState.waiting) {
      body = _buildMobileLoadingState(isDark);
    } else if (snapshot.hasError) {
      body = _buildMobileErrorState(snapshot.error.toString(), isDark);
    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
      body = _buildMobileEmptyState(isDark);
    } else {
      body = FadeTransition(
        opacity: _fadeAnimation,
        child: _buildMobileInvoiceList(
          isAbertas ? mensalidadesEmAberto : historicoFaturas.reversed.toList(),
          isPending: isAbertas,
          isDark: isDark,
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : backgroundColor,
      body: Column(
        children: [
          _buildMobileHeader(context, isDark),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: primaryColor,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _buildMobileHeroCard(
                    isDark: isDark,
                    totalAbertas: mensalidadesEmAberto.length,
                    totalPagas: historicoFaturas.length,
                  ),
                  const SizedBox(height: 16),
                  _buildMobileFilterBar(
                    isDark: isDark,
                    totalAbertas: mensalidadesEmAberto.length,
                    totalPagas: historicoFaturas.length,
                    pendentes: mensalidadesEmAberto,
                  ),
                  const SizedBox(height: 16),
                  body,
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: (_selectedInvoiceIds.isNotEmpty && isAbertas)
          ? _buildMobilePaymentFooter(isDark)
          : null,
    );
  }

  /// Header/AppBar mobile: título e subtítulo em `Expanded` (ellipsis) e
  /// botões compactos para nunca cortarem na direita.
  Widget _buildMobileHeader(BuildContext context, bool isDark) {
    final iconBg = isDark ? const Color(0xFF334155) : const Color(0xFFF0F4FF);
    const compact = BoxConstraints(minWidth: 40, minHeight: 40);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Voltar',
                onPressed: () => Navigator.pop(context, _didPay),
                constraints: compact,
                padding: EdgeInsets.zero,
                icon: Icon(Icons.arrow_back_rounded,
                    color: isDark ? Colors.white : primaryColor, size: 22),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  final isThemeDark = themeProvider.isDarkMode;
                  return IconButton(
                    tooltip: isThemeDark
                        ? 'Alternar para tema claro'
                        : 'Alternar para tema escuro',
                    onPressed: () => themeProvider.toggleTheme(!isThemeDark),
                    constraints: compact,
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      backgroundColor: iconBg,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(
                      isThemeDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: isThemeDark ? const Color(0xFFF59E0B) : primaryColor,
                      size: 20,
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Atualizar faturas',
                onPressed: _refreshData,
                constraints: compact,
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: iconBg,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(Icons.refresh_rounded,
                    color: isDark ? Colors.white70 : primaryColor, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Card "Central de Faturas" 100% em Column: topo (ícone + textos) e base
  /// (badges em Wrap) — as badges nunca dividem a Row com o título.
  Widget _buildMobileHeroCard({
    required bool isDark,
    required int totalAbertas,
    required int totalPagas,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0F172A), Color(0xFF1E3A8A)]
              : const [primaryColor, accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Central de Faturas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Consulte todas as mensalidades, verifique vencimentos e realize pagamentos.',
                      style: TextStyle(
                        color: Colors.white.withAlpha(210),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMobileStatChip('$totalAbertas em aberto', const Color(0xFFF59E0B)),
              _buildMobileStatChip('$totalPagas quitadas', const Color(0xFF4ADE80)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStatChip(String text, Color dotColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  /// Barra de filtros mobile em Column:
  /// linha 1 -> "Em aberto" / "Pagas" (50% cada); linha 2 -> "Selecionar todas".
  Widget _buildMobileFilterBar({
    required bool isDark,
    required int totalAbertas,
    required int totalPagas,
    required List<Mensalidade> pendentes,
  }) {
    final isAbertas = _tabController.index == 0;
    final allSelected = pendentes.isNotEmpty &&
        pendentes.every((m) => _selectedInvoiceIds.contains(m.id));
    final accent = isDark ? const Color(0xFF60A5FA) : primaryColor;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMobileTabButton(
                  isDark: isDark,
                  title: 'Em aberto',
                  count: totalAbertas,
                  isSelected: isAbertas,
                  badgeColor: isDark ? const Color(0xFFEF4444) : Colors.red.shade600,
                  onTap: () => _tabController.index = 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMobileTabButton(
                  isDark: isDark,
                  title: 'Pagas',
                  count: totalPagas,
                  isSelected: !isAbertas,
                  badgeColor: isDark ? const Color(0xFF22C55E) : Colors.green.shade600,
                  onTap: () => _tabController.index = 1,
                ),
              ),
            ],
          ),
          if (isAbertas && pendentes.isNotEmpty) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                if (allSelected) {
                  _limparSelecao();
                } else {
                  _selecionarTodasFaturas(pendentes);
                }
              },
              icon: Icon(
                allSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
                size: 18,
                color: accent,
              ),
              label: Text(
                allSelected ? 'Desmarcar todas' : 'Selecionar todas',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: accent.withAlpha(120)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileTabButton({
    required bool isDark,
    required String title,
    required int count,
    required bool isSelected,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    final accent = isDark ? const Color(0xFF60A5FA) : primaryColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF334155) : primaryColor.withAlpha(20))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
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
                const SizedBox(width: 6),
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
      ),
    );
  }

  Widget _buildMobileLoadingState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text('Carregando faturas...',
              style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildMobileErrorState(String error, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF450A0A).withAlpha(80) : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? const Color(0xFFDC2626).withAlpha(60) : Colors.red.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 44),
          const SizedBox(height: 12),
          Text(
            'Erro: $error',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: isDark ? const Color(0xFFFCA5A5) : Colors.red.shade700,
                fontSize: 14),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded,
              size: 56, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Nenhuma fatura encontrada',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInvoiceList(
    List<Mensalidade> mensalidades, {
    required bool isPending,
    required bool isDark,
  }) {
    if (mensalidades.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
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
                isPending ? Icons.verified_user_rounded : Icons.history_rounded,
                size: 44,
                color: isDark ? const Color(0xFF4ADE80) : Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isPending ? 'Tudo em dia!' : 'Nenhuma fatura paga',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isPending
                  ? 'Você não possui nenhuma fatura pendente.'
                  : 'Quando suas faturas forem quitadas, elas aparecerão aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: mensalidades
          .map((m) => _buildMobileInvoiceCard(m, isPending: isPending, isDark: isDark))
          .toList(),
    );
  }

  /// Status mobile: PENDENTE / PAGO / VENCIDA (+ CANCELADA).
  Map<String, dynamic> _getMobileStatusInfo(String status, bool isDark) {
    late final String text;
    late final Color color;
    late final IconData icon;
    switch (status) {
      case 'PAGA':
        text = 'PAGO';
        color = isDark ? const Color(0xFF4ADE80) : Colors.green.shade800;
        icon = Icons.check_circle_rounded;
        break;
      case 'ATRASADA':
        text = 'VENCIDA';
        color = isDark ? const Color(0xFFF87171) : Colors.red.shade800;
        icon = Icons.warning_rounded;
        break;
      case 'PENDENTE':
        text = 'PENDENTE';
        color = isDark ? const Color(0xFFFBBF24) : Colors.orange.shade800;
        icon = Icons.schedule_rounded;
        break;
      case 'CANCELADA':
        text = 'CANCELADA';
        color = isDark ? Colors.grey.shade400 : Colors.grey.shade700;
        icon = Icons.cancel_rounded;
        break;
      default:
        text = status;
        color = isDark ? Colors.white70 : Colors.black87;
        icon = Icons.help_outline_rounded;
    }
    return {
      'text': text,
      'color': color,
      'bgColor': color.withAlpha(isDark ? 45 : 30),
      'icon': icon,
    };
  }

  /// Card de fatura mobile em 2 andares:
  /// Andar 1: checkbox + ícone + (mês / vencimento); divisor; Andar 2: status + valor.
  Widget _buildMobileInvoiceCard(
    Mensalidade mensalidade, {
    required bool isPending,
    required bool isDark,
  }) {
    final bool isSelected = _selectedInvoiceIds.contains(mensalidade.id);
    final formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formatadorMesAno = DateFormat('MMMM \'de\' yyyy', 'pt_BR');
    final formatadorVencimento = DateFormat('dd/MM/yyyy');
    final mesFormatado = capitalize(formatadorMesAno.format(mensalidade.mesReferencia));
    final statusInfo = _getMobileStatusInfo(mensalidade.status, isDark);
    final accent = isDark ? const Color(0xFF60A5FA) : primaryColor;
    final mutedColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? (isSelected ? const Color(0xFF1E293B) : const Color(0xFF111827))
            : (isSelected ? const Color(0xFFF0F7FF) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? accent : (isDark ? Colors.white10 : Colors.grey.shade200),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? accent.withAlpha(40)
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
          onTap: isPending ? () => _onInvoiceSelected(!isSelected, mensalidade) : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ANDAR 1
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (isPending) ...[
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (bool? val) => _onInvoiceSelected(val, mensalidade),
                          activeColor: primaryColor,
                          checkColor: Colors.white,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF334155)
                            : primaryColor.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.receipt_long_rounded, color: accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mensalidade de $mesFormatado',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Vencimento: ${formatadorVencimento.format(mensalidade.dataVencimento)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: mutedColor),
                          ),
                          if (mensalidade.status == 'ATRASADA')
                            Text(
                              '${mensalidade.diasAtraso} dias em atraso',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                ),
                const SizedBox(height: 12),
                // ANDAR 2
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusInfo['bgColor'],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusInfo['icon'], size: 14, color: statusInfo['color']),
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
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Valor final',
                            style: TextStyle(fontSize: 11, color: mutedColor),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              formatadorMoeda.format(mensalidade.valorFinal),
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobilePaymentFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(isDark ? 80 : 26),
              blurRadius: 20,
              offset: const Offset(0, -8)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selectedInvoiceIds.length} fatura(s) selecionada(s)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                          .format(_totalSelecionado),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [primaryColor, accentColor]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: primaryColor.withAlpha(77),
                      blurRadius: 12,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _pagarSelecionados(context),
                icon: const Icon(Icons.pix, color: Colors.white, size: 18),
                label: const Text('Pagar',
                    style: TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String capitalize(String s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '';
