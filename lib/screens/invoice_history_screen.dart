import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro de autenticação.')));
      return;
    }

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

  @override
  Widget build(BuildContext context) {
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
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  ),
                  child: RefreshIndicator(
                    onRefresh: _refreshData,
                    color: primaryColor,
                    child: FutureBuilder<List<AlunoComMensalidades>>(
                      future: _historyFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) return _buildLoadingState();
                        if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
                        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState();
                        
                        final mensalidadesEmAberto = _allInvoices.where((m) => m.status == 'PENDENTE' || m.status == 'ATRASADA').toList();
                        final historicoFaturas = _allInvoices.where((m) => m.status == 'PAGA' || m.status == 'CANCELADA').toList();
                        
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildInvoiceList(mensalidadesEmAberto, isPending: true),
                              _buildInvoiceList(historicoFaturas, isPending: false),
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
      bottomNavigationBar: _selectedInvoiceIds.isNotEmpty ? _buildPaymentFooter(context) : null,
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