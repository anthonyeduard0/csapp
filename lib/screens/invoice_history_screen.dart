import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:educsa/providers/theme_provider.dart';
import 'package:educsa/screens/payment_screen.dart';
import 'package:educsa/screens/main_screen.dart'; // Mantive caso precise do AlunoComMensalidades
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
      
      if (response.statusCode == 201) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (kIsWeb) {
      return _buildWebLayout(context, isDark);
    }

    return _buildMobileLayout(context);
  }

  // --- LAYOUT WEB PADRONIZADO ---
  Widget _buildWebLayout(BuildContext context, bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF0F4FF),
      body: Column(
        children: [
          _buildWebTopBar(context, isDark),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: FutureBuilder<List<AlunoComMensalidades>>(
                      future: _historyFuture,
                      builder: (context, snapshot) {
                        final mensalidadesEmAberto = _allInvoices
                            .where((m) =>
                                m.status == 'PENDENTE' || m.status == 'ATRASADA')
                            .toList();
                        final historicoFaturas = _allInvoices
                            .where((m) =>
                                m.status == 'PAGA' || m.status == 'CANCELADA')
                            .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWebWelcomeBanner(
                              isDark: isDark,
                              totalAbertas: mensalidadesEmAberto.length,
                              totalPagas: historicoFaturas.length,
                            ),
                            const SizedBox(height: 28),
                            _buildWebTabsCard(
                              isDark: isDark,
                              totalAbertas: mensalidadesEmAberto.length,
                              totalPagas: historicoFaturas.length,
                              pendentes: mensalidadesEmAberto,
                            ),
                            const SizedBox(height: 24),
                            if (snapshot.connectionState ==
                                ConnectionState.waiting)
                              _buildWebLoadingState(isDark)
                            else if (snapshot.hasError)
                              _buildWebErrorState(
                                  snapshot.error.toString(), isDark)
                            else if (!snapshot.hasData || snapshot.data!.isEmpty)
                              _buildWebEmptyState(isDark)
                            else
                              _buildWebTabContent(
                                isDark: isDark,
                                abertas: mensalidadesEmAberto,
                                pagas: historicoFaturas,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          (_selectedInvoiceIds.isNotEmpty && _tabController.index == 0)
              ? _buildWebPaymentBar(context, isDark)
              : null,
    );
  }

  Widget _buildWebTopBar(BuildContext context, bool isDark) {
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
                  onTap: () => Navigator.pop(context, _didPay),
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
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Minhas Faturas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : primaryColor,
                ),
              ),
              Text(
                'Histórico completo e gestão de mensalidades',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey,
                ),
              ),
            ],
          ),
          const Spacer(),
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
                  onTap: _refreshData,
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

  Widget _buildWebWelcomeBanner({
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
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$totalAbertas em aberto',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$totalPagas quitadas',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebTabsCard({
    required bool isDark,
    required int totalAbertas,
    required int totalPagas,
    required List<Mensalidade> pendentes,
  }) {
    final isAbertas = _tabController.index == 0;
    final allSelected = pendentes.isNotEmpty &&
        pendentes.every((m) => _selectedInvoiceIds.contains(m.id));

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
          _buildWebTabButton(
            isDark: isDark,
            title: 'Em aberto',
            count: totalAbertas,
            isSelected: isAbertas,
            badgeColor: isDark ? const Color(0xFFEF4444) : Colors.red.shade600,
            onTap: () {
              setState(() {
                _tabController.index = 0;
              });
            },
          ),
          const SizedBox(width: 10),
          _buildWebTabButton(
            isDark: isDark,
            title: 'Pagas',
            count: totalPagas,
            isSelected: !isAbertas,
            badgeColor:
                isDark ? const Color(0xFF22C55E) : Colors.green.shade600,
            onTap: () {
              setState(() {
                _tabController.index = 1;
              });
            },
          ),
          const Spacer(),
          if (isAbertas && pendentes.isNotEmpty) ...[
            TextButton.icon(
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
                color: isDark ? const Color(0xFF60A5FA) : primaryColor,
              ),
              label: Text(
                allSelected ? 'Desmarcar todas' : 'Selecionar todas',
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
          ],
        ],
      ),
    );
  }

  Widget _buildWebTabButton({
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

  Widget _buildWebTabContent({
    required bool isDark,
    required List<Mensalidade> abertas,
    required List<Mensalidade> pagas,
  }) {
    final isAbertas = _tabController.index == 0;
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
                isAbertas
                    ? Icons.verified_user_rounded
                    : Icons.history_rounded,
                size: 48,
                color: isDark
                    ? const Color(0xFF4ADE80)
                    : Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isAbertas ? 'Tudo em dia!' : 'Nenhuma fatura paga no histórico',
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
          .map((fatura) => _buildWebInvoiceCard(
                fatura,
                isPending: isAbertas,
                isDark: isDark,
              ))
          .toList(),
    );
  }

  Widget _buildWebInvoiceCard(
    Mensalidade mensalidade, {
    required bool isPending,
    required bool isDark,
  }) {
    final bool isSelected = _selectedInvoiceIds.contains(mensalidade.id);
    final formatadorMoeda =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formatadorMesAno = DateFormat('MMMM \'de\' yyyy', 'pt_BR');
    final formatadorVencimento = DateFormat('dd/MM/yyyy');
    final mesFormatado =
        capitalize(formatadorMesAno.format(mensalidade.mesReferencia));
    final statusInfo = _getStatusInfo(mensalidade.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark
            ? (isSelected
                ? const Color(0xFF1E293B)
                : const Color(0xFF111827))
            : (isSelected
                ? const Color(0xFFF0F7FF)
                : Colors.white),
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
                : (isDark
                    ? Colors.black.withAlpha(40)
                    : Colors.black.withAlpha(8)),
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
              ? () => _onInvoiceSelected(!isSelected, mensalidade)
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
                          _onInvoiceSelected(val, mensalidade),
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
                      Text(
                        'Mensalidade de $mesFormatado',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: isDark ? Colors.grey.shade400 : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Vencimento: ${formatadorVencimento.format(mensalidade.dataVencimento)}',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          if (mensalidade.status == 'ATRASADA') ...[
                            const SizedBox(width: 8),
                            Text(
                              '• ${mensalidade.diasAtraso} dias em atraso',
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
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
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade500,
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
                      onPressed: () =>
                          _pagarFaturaIndividual(context, mensalidade),
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

  Widget _buildWebPaymentBar(BuildContext context, bool isDark) {
    final formatadorMoeda =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
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
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selectedInvoiceIds.length} fatura(s) selecionada(s)',
                    style: TextStyle(
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    formatadorMoeda.format(_totalSelecionado),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : primaryColor,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: _limparSelecao,
                child: Text(
                  'Limpar seleção',
                  style: TextStyle(
                    color:
                        isDark ? Colors.grey.shade400 : Colors.grey.shade600,
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
                  onPressed: () => _pagarSelecionados(context),
                  icon: const Icon(Icons.pix, color: Colors.white, size: 18),
                  label: Text(
                    'Pagar com Pix (${_selectedInvoiceIds.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
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

  Widget _buildWebLoadingState(bool isDark) {
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

  Widget _buildWebErrorState(String error, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color:
            isDark ? const Color(0xFF450A0A).withAlpha(80) : Colors.red.shade50,
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
            onPressed: _refreshData,
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

  Widget _buildWebEmptyState(bool isDark) {
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

  // --- LAYOUT MOBILE ORIGINAL INTACTO ---
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, accentColor],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildCustomTabs(),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30)),
                  ),
                  child: RefreshIndicator(
                    onRefresh: _refreshData,
                    color: primaryColor,
                    child: FutureBuilder<List<AlunoComMensalidades>>(
                      future: _historyFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildLoadingState();
                        }
                        if (snapshot.hasError) {
                          return _buildErrorState(snapshot.error.toString());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return _buildEmptyState();
                        }

                        final mensalidadesEmAberto = _allInvoices
                            .where((m) =>
                                m.status == 'PENDENTE' ||
                                m.status == 'ATRASADA')
                            .toList();
                        final historicoFaturas = _allInvoices
                            .where((m) =>
                                m.status == 'PAGA' ||
                                m.status == 'CANCELADA')
                            .toList();

                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildInvoiceList(mensalidadesEmAberto,
                                  isPending: true),
                              _buildInvoiceList(historicoFaturas,
                                  isPending: false),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          _selectedInvoiceIds.isNotEmpty ? _buildPaymentFooter(context) : null,
    );
  }

  // --- Widgets de UI mantidos iguais ao original ---
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context, _didPay),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          const Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox( 
                  fit: BoxFit.scaleDown,
                  child: Text('Minhas Faturas', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)) 
                ),
                Text('Gerencie seus pagamentos', style: TextStyle(color: Colors.white70, fontSize: 15)), 
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0x33000000), borderRadius: BorderRadius.circular(20)),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [ BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)) ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: primaryColor,
        unselectedLabelColor: Colors.white,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 17),
        tabs: const [
          Tab(
            child: FittedBox( 
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [ 
                  Icon(Icons.pending_actions_rounded, size: 20), 
                  SizedBox(width: 8), 
                  Text('Em aberto') 
                ]
              ),
            ),
          ),
          Tab(
            child: FittedBox( 
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [ 
                  Icon(Icons.check_circle_rounded, size: 20), 
                  SizedBox(width: 8), 
                  Text('Pagas') 
                ]
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center( child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor), strokeWidth: 3), SizedBox(height: 16), Text('Carregando faturas...', style: TextStyle(color: Colors.grey, fontSize: 17)), ], ), ); 
  }

  Widget _buildErrorState(String error) {
    return Center( child: Container( margin: const EdgeInsets.all(24), padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red.shade200)), child: Column( mainAxisSize: MainAxisSize.min, children: [ const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48), const SizedBox(height: 16), Text('Erro: $error', textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700, fontSize: 17)), ], ), ), );
  }
  
  Widget _buildEmptyState() {
    return const Center( child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey), SizedBox(height: 16), Text('Nenhuma fatura encontrada', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w500, color: Colors.grey)), ], ), );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'PAGA': return {'text': 'PAGO', 'color': Colors.green.shade800, 'bgColor': Colors.green.shade100, 'icon': Icons.check_circle_rounded};
      case 'ATRASADA': return {'text': 'EM ATRASO', 'color': Colors.red.shade800, 'bgColor': Colors.red.shade100, 'icon': Icons.warning_rounded};
      case 'PENDENTE': return {'text': 'PENDENTE', 'color': Colors.orange.shade800, 'bgColor': Colors.orange.shade100, 'icon': Icons.schedule_rounded};
      case 'CANCELADA': return {'text': 'CANCELADA', 'color': Colors.grey.shade700, 'bgColor': Colors.grey.shade300, 'icon': Icons.cancel_rounded};
      default: return {'text': status, 'color': Colors.black, 'bgColor': Colors.grey.shade200, 'icon': Icons.help_outline_rounded};
    }
  }

  Widget _buildInvoiceList(List<Mensalidade> mensalidades, {required bool isPending}) {
    if (mensalidades.isEmpty) {
      return LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryColor.withAlpha(26), accentColor.withAlpha(26)]), shape: BoxShape.circle),
                    child: Icon(isPending ? Icons.pending_actions_rounded : Icons.check_circle_rounded, size: 48, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 16),
                  Text(isPending ? 'Nenhuma fatura pendente' : 'Nenhuma fatura paga', style: TextStyle(fontSize: 17, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        );
      });
    }
    final listParaExibir = isPending ? mensalidades : mensalidades.reversed.toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      itemCount: listParaExibir.length,
      itemBuilder: (context, index) {
        return _buildInvoiceCard(listParaExibir[index], isPending: isPending);
      },
    );
  }

  Widget _buildInvoiceCard(Mensalidade mensalidade, {required bool isPending}) {
    final bool isSelected = _selectedInvoiceIds.contains(mensalidade.id);
    final formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formatadorMesAno = DateFormat('MMMM \'de\' yyyy', 'pt_BR');
    final formatadorVencimento = DateFormat('dd/MM/yyyy');
    final mesFormatado = capitalize(formatadorMesAno.format(mensalidade.mesReferencia));
    final statusInfo = _getStatusInfo(mensalidade.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? Border.all(color: primaryColor, width: 2) : Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [ BoxShadow(color: isSelected ? primaryColor.withAlpha(51) : Colors.grey.withAlpha(26), blurRadius: isSelected ? 12 : 8, offset: const Offset(0, 4)) ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isPending ? () => _onInvoiceSelected(!isSelected, mensalidade) : null,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (isPending)
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (bool? value) => _onInvoiceSelected(value, mensalidade),
                        activeColor: primaryColor,
                        checkColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryColor.withAlpha(26), accentColor.withAlpha(26)]), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.receipt_long_rounded, color: primaryColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              'Mensalidade de $mesFormatado', 
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: primaryColor), 
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text('Vencimento: ${formatadorVencimento.format(mensalidade.dataVencimento)}', style: const TextStyle(color: Colors.grey, fontSize: 15), softWrap: false), 
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                formatadorMoeda.format(mensalidade.valorFinal), 
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor), 
                                softWrap: false, 
                              )
                            )
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: statusInfo['bgColor'], borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusInfo['icon'], size: 16, color: statusInfo['color']),
                                const SizedBox(width: 4),
                                Text(statusInfo['text'], style: TextStyle(color: statusInfo['color'], fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        boxShadow: [ BoxShadow(color: Colors.black.withAlpha(26), blurRadius: 20, offset: const Offset(0, -8)) ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text('${_selectedInvoiceIds.length} fatura(s) selecionada(s)', style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
                  ),
                  const SizedBox(height: 4),
                  Text(NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(_totalSelecionado), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primaryColor)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [primaryColor, accentColor]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [ BoxShadow(color: primaryColor.withAlpha(77), blurRadius: 12, offset: const Offset(0, 6)) ],
              ),
              child: ElevatedButton(
                onPressed: () => _pagarSelecionados(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.payment_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Pagar', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)), 
                  ],
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