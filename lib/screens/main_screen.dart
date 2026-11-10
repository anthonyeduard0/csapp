// Arquivo: lib/screens/main_screen.dart
// CORRIGIDO (BUG DE RENDERIZAÇÃO): Removido 'Flexible' de dentro da Column no _buildHeader, que causava a tela em branco.
// CORREÇÃO (HÍBRIDA): Removido FittedBox do título "Próxima Fatura" e aplicado maxLines: 2.
// CORREÇÃO (HÍBRIDA): Mantido FittedBox para o valor em R$.
// ATUALIZADO: Fontes levemente aumentadas.
//
// +++ ÚLTIMA CORREÇÃO (BUG) +++
// Corrigido o 'factory DashboardData.fromJson' para usar o parâmetro 'nomeResponsavel' em vez de 'nomeCompleto'.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:educsa/screens/profile_screen.dart';
import 'package:educsa/screens/payment_screen.dart';
import 'package:educsa/screens/invoice_history_screen.dart';
import 'package:educsa/screens/calendar_screen.dart';
import 'package:educsa/web/web_shell.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:educsa/api_config.dart'; // Importação adicionada
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; 
import 'package:url_launcher/url_launcher.dart'; 

class Mensalidade {
  final String id;
  final DateTime mesReferencia;
  final double valorNominal;
  final double valorFinal;
  final String status;
  final DateTime dataVencimento;
  final double multa;
  final double juros;
  final int diasAtraso;

  Mensalidade({
    required this.id,
    required this.mesReferencia,
    required this.valorNominal,
    required this.valorFinal,
    required this.status,
    required this.dataVencimento,
    required this.multa,
    required this.juros,
    required this.diasAtraso,
  });

  factory Mensalidade.fromJson(Map<String, dynamic> json) {
    return Mensalidade(
      id: json['id'],
      mesReferencia: DateTime.parse(json['mes_referencia']),
      valorNominal: double.tryParse(json['valor_nominal'].toString()) ?? 0.0,
      valorFinal: double.tryParse(json['valor_final'].toString()) ?? 0.0,
      status: json['status'],
      dataVencimento: DateTime.parse(json['data_vencimento']),
      multa: double.tryParse(json['multa'].toString()) ?? 0.0,
      juros: double.tryParse(json['juros'].toString()) ?? 0.0,
      diasAtraso: json['dias_atraso'] ?? 0,
    );
  }
}

class Aluno {
  final String nomeCompleto;
  final String serieAno;
  final String statusMatricula;
  final String? validadeMatriculaFormatada;
  final List<Mensalidade> mensalidadesPendentes;
  Aluno({ required this.nomeCompleto, required this.serieAno, required this.statusMatricula, this.validadeMatriculaFormatada, required this.mensalidadesPendentes });
  factory Aluno.fromJson(Map<String, dynamic> json) {
    var mensalidadesList = json['mensalidades_pendentes'] as List;
    List<Mensalidade> mensalidades = mensalidadesList.map((i) => Mensalidade.fromJson(i)).toList();
    return Aluno(
      nomeCompleto: json['nome_completo'],
      serieAno: json['serie_ano'],
      statusMatricula: json['status_matricula'] ?? 'Indefinido',
      validadeMatriculaFormatada: json['validade_matricula_formatada'],
      mensalidadesPendentes: mensalidades,
    );
  }
}

class AlunoComMensalidades {
  final String nomeCompleto;
  final String? serieAno;
  final List<Mensalidade> mensalidades;
  AlunoComMensalidades({required this.nomeCompleto, this.serieAno, required this.mensalidades});
  factory AlunoComMensalidades.fromJson(Map<String, dynamic> json) {
    var mensalidadesList = json['mensalidades'] as List;
    List<Mensalidade> mensalidades = mensalidadesList.map((i) => Mensalidade.fromJson(i)).toList();
    mensalidades.sort((a, b) => b.dataVencimento.compareTo(a.dataVencimento));
    return AlunoComMensalidades(
      nomeCompleto: json['nome_completo'],
      serieAno: json['serie_ano'] as String?,
      mensalidades: mensalidades,
    );
  }
}

class DashboardData {
  final String nomeResponsavel;
  final String cpfResponsavel;
  final String email;
  final String? telefone;
  final List<Aluno> alunos;
  
  DashboardData({ 
    required this.nomeResponsavel, 
    required this.cpfResponsavel, 
    required this.email, 
    this.telefone, 
    required this.alunos 
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    var alunosList = json['alunos'] as List;
    List<Aluno> alunos = alunosList.map((i) => Aluno.fromJson(i)).toList();
    return DashboardData(
      // +++ CORREÇÃO DO BUG AQUI +++
      nomeResponsavel: json['nome_completo'], // Estava 'nomeCompleto:'
      cpfResponsavel: json['cpf'],
      email: json['email'],
      telefone: json['telefone'],
      alunos: alunos,
    );
  }
  
  DashboardData copyWith({
    String? nomeResponsavel,
    String? cpfResponsavel,
    String? email,
    String? telefone,
    List<Aluno>? alunos,
  }) {
    return DashboardData(
      nomeResponsavel: nomeResponsavel ?? this.nomeResponsavel,
      cpfResponsavel: cpfResponsavel ?? this.cpfResponsavel,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      alunos: alunos ?? this.alunos,
    );
  }
}

class MainScreen extends StatefulWidget {
  final Map<String, dynamic> responseData;
  const MainScreen({super.key, required this.responseData});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  final GlobalKey<_FinancialScreenState> _financialScreenKey = GlobalKey<_FinancialScreenState>();

  @override
  void initState() {
    super.initState();
    _pages = [
      FinancialScreen(key: _financialScreenKey, responseData: widget.responseData),
      const CalendarScreen(),
      ProfileScreen(responseData: widget.responseData),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // +++ DETECÇÃO WEB: usa WebShell com sidebar em vez do layout mobile +++
    if (kIsWeb) {
      final screenWidth = MediaQuery.of(context).size.width;
      if (screenWidth >= 800) {
        return WebShell(responseData: widget.responseData);
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    const Color primaryColor = Color(0xFF1E3A8A);
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: isDark
              ? const Border(top: BorderSide(color: Colors.white10, width: 1))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 60 : 26),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem( icon: Icon(Icons.monetization_on_outlined), activeIcon: Icon(Icons.monetization_on), label: 'Financeiro', ),
            BottomNavigationBarItem( icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Calendário', ),
            BottomNavigationBarItem( icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil', ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: isDark ? const Color(0xFF60A5FA) : primaryColor,
          unselectedItemColor: isDark ? const Color(0xFF94A3B8) : Colors.grey[600],
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          iconSize: 26,
          selectedFontSize: 15, // Fonte aumentada
          unselectedFontSize: 13, // Fonte aumentada
          showUnselectedLabels: true,
        ),
      ),
    );
  }
}

class FinancialScreen extends StatefulWidget {
  final Map<String, dynamic> responseData;
  const FinancialScreen({required this.responseData, super.key});
  @override
  State<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends State<FinancialScreen> {
  Future<DashboardData>? _dashboardDataFuture;
  int? _selectedAlunoIndex;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();


  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = Future.value(DashboardData.fromJson(widget.responseData));
  }

  Future<void> reloadData() async {
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
      if (mounted && response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _dashboardDataFuture = Future.value(DashboardData.fromJson(responseData));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao atualizar os dados. Verifique sua conexão.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
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
    const Color primaryColor = Color(0xFF1E3A8A);
    const Color backgroundColor = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0F172A), Color(0xFF1E3A8A)]
                : const [Color(0xFF1D449B), Color(0xFF25B6E8)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: FutureBuilder<DashboardData>(
            future: _dashboardDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              if (snapshot.hasError || !snapshot.hasData) {
                // Se o factory .fromJson falhar, o snapshot.error terá o erro.
                return Center(child: Text('Erro ao carregar dados: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
              }
              final dashboardData = snapshot.data!;
              // Aluno selecionado: por padrão, o primeiro com fatura pendente.
              int selectedIdx = _selectedAlunoIndex ?? 0;
              if (_selectedAlunoIndex == null) {
                final firstWithPending = dashboardData.alunos
                    .indexWhere((a) => a.mensalidadesPendentes.isNotEmpty);
                selectedIdx = firstWithPending >= 0 ? firstWithPending : 0;
              }
              if (selectedIdx >= dashboardData.alunos.length) selectedIdx = 0;

              Mensalidade? proximaMensalidade;
              if (dashboardData.alunos.isNotEmpty) {
                final alunoSel = dashboardData.alunos[selectedIdx];
                if (alunoSel.mensalidadesPendentes.isNotEmpty) {
                  proximaMensalidade = alunoSel.mensalidadesPendentes.first;
                }
              }

              return Column(
                children: [
                  _buildHeader(dashboardData),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : backgroundColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: RefreshIndicator(
                        key: _refreshIndicatorKey,
                        onRefresh: reloadData,
                        color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24.0),
                          child: Column( 
                            children: [
                              _buildFaturaCard(context, proximaMensalidade, dashboardData.cpfResponsavel, isDark),
                              if (dashboardData.alunos.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                _buildAlunosVinculadosCard(dashboardData.alunos, selectedIdx, isDark),
                              ],
                              const SizedBox(height: 24), 
                              _buildSocialMediaIcons(isDark), 
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(DashboardData data) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withAlpha(51),
            child: const Icon(Icons.person, size: 30, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bem-vindo(a),',
                  style: TextStyle(color: Colors.white70, fontSize: 15), // Fonte aumentada
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  data.nomeResponsavel,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), // Fonte aumentada
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2, 
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status, bool isDark) {
    switch (status) {
      case 'PAGA':
        final color = isDark ? const Color(0xFF4ADE80) : Colors.green.shade800;
        return {
          'text': 'PAGO',
          'color': color,
          'bgColor': isDark ? color.withAlpha(45) : Colors.green.shade100,
          'icon': Icons.check_circle_rounded,
        };
      case 'ATRASADA':
        final color = isDark ? const Color(0xFFF87171) : Colors.red.shade800;
        return {
          'text': 'EM ATRASO',
          'color': color,
          'bgColor': isDark ? color.withAlpha(45) : Colors.red.shade100,
          'icon': Icons.warning_rounded,
        };
      case 'PENDENTE':
        final color = isDark ? const Color(0xFFFBBF24) : Colors.orange.shade800;
        return {
          'text': 'PENDENTE',
          'color': color,
          'bgColor': isDark ? color.withAlpha(45) : Colors.orange.shade100,
          'icon': Icons.schedule_rounded,
        };
      case 'CANCELADA':
        final color = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700;
        return {
          'text': 'CANCELADA',
          'color': color,
          'bgColor': isDark ? color.withAlpha(45) : Colors.grey.shade300,
          'icon': Icons.cancel_rounded,
        };
      default:
        return {
          'text': status,
          'color': isDark ? Colors.white70 : Colors.black,
          'bgColor': isDark ? Colors.white10 : Colors.grey.shade200,
          'icon': Icons.help_outline_rounded,
        };
    }
  }

  Widget _buildFaturaCard(BuildContext context, Mensalidade? mensalidade, String cpf, bool isDark) {
    const Color primaryColor = Color(0xFF1D449B);
    const Color accentColor = Color(0xFF25B6E8);
    final formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    if (mensalidade == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isDark ? Border.all(color: Colors.white10) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 50 : 12),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.verified_user_rounded,
              size: 64,
              color: isDark ? const Color(0xFF4ADE80) : Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'Tudo em dia!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : primaryColor,
              ),
              textAlign: TextAlign.center,
            ), // Fonte aumentada
            const SizedBox(height: 8),
            Text(
              'Nenhuma mensalidade pendente encontrada.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
                fontSize: 17,
              ),
            ), // Fonte aumentada
            const SizedBox(height: 24),
            TextButton(
              onPressed: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => InvoiceHistoryScreen(responsavelCpf: cpf)));
                if (result == true) {
                  reloadData();
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: isDark ? const Color(0xFF60A5FA) : primaryColor,
              ),
              child: const Text('Ver histórico de faturas', style: TextStyle(fontSize: 16)), // Fonte aumentada
            ),
          ],
        ),
      );
    }

    final statusInfo = _getStatusInfo(mensalidade.status, isDark);
    final mesFormatado = capitalize(DateFormat('MMMM', 'pt_BR').format(mensalidade.mesReferencia));
    final bool isJaneiro = mensalidade.mesReferencia.month == 1;
    final String anoRef = DateFormat('yyyy').format(mensalidade.mesReferencia);
    final String tituloFatura = isJaneiro ? 'Renovação de Matrícula' : 'Próxima Fatura: $mesFormatado';
    final String mesRefEnvio = isJaneiro
        ? 'Renovação de Matrícula (Janeiro/$anoRef)'
        : DateFormat('MM/yyyy').format(mensalidade.mesReferencia);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: isDark ? Border.all(color: Colors.white10) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 50 : 12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isJaneiro) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF93C5FD),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.school_rounded,
                                  size: 14,
                                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'MATRÍCULA',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Text(
                          tituloFatura,
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : primaryColor,
                          ),
                          maxLines: 2, 
                          overflow: TextOverflow.ellipsis, 
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: statusInfo['bgColor'], borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Icon(statusInfo['icon'], size: 16, color: statusInfo['color']),
                        const SizedBox(width: 4),
                        Text(statusInfo['text'], style: TextStyle(color: statusInfo['color'], fontWeight: FontWeight.bold, fontSize: 13)), // Fonte aumentada
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  formatadorMoeda.format(mensalidade.valorFinal), 
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF334155),
                  ),
                ),
              ),
              Text(
                'Vencimento em ${DateFormat('dd/MM/yyyy').format(mensalidade.dataVencimento)}',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
                  fontSize: 15,
                ),
              ), // Fonte aumentada
              if (isJaneiro) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF064E3B).withAlpha(80)
                        : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF059669).withAlpha(90)
                          : const Color(0xFF86EFAC),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'O pagamento desta parcela efetiva a renovação de matrícula online.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (mensalidade.status == 'ATRASADA') ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(color: isDark ? Colors.white10 : null),
                ),
                _buildDetalheRow('Valor Original', formatadorMoeda.format(mensalidade.valorNominal), isDark),
                const SizedBox(height: 4),
                _buildDetalheRow('Multa por atraso', formatadorMoeda.format(mensalidade.multa), isDark),
                const SizedBox(height: 4),
                _buildDetalheRow('Juros (${mensalidade.diasAtraso} dias)', formatadorMoeda.format(mensalidade.juros), isDark),
              ],
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration( gradient: const LinearGradient(colors: [primaryColor, accentColor]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: primaryColor.withAlpha(76), blurRadius: 12, offset: const Offset(0, 6))], ),
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(context, MaterialPageRoute(
                      builder: (context) => PaymentScreen(
                        mensalidadeId: mensalidade.id,
                        valor: mensalidade.valorFinal.toStringAsFixed(2),
                        mesReferencia: mesRefEnvio,
                      ),
                    ));
                    if (result == true) {
                      reloadData();
                    }
                  },
                  style: ElevatedButton.styleFrom( backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pix, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Pagar com Pix', style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold)), // Fonte aumentada
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => InvoiceHistoryScreen(responsavelCpf: cpf)));
            if (result == true) {
              reloadData();
            }
          },
          icon: const Icon(Icons.receipt_long_outlined, size: 20),
          label: const Text('Ver todas as faturas', style: TextStyle(fontSize: 16)), // Fonte aumentada
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? const Color(0xFF60A5FA) : primaryColor,
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            side: BorderSide(
              color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildAlunosVinculadosCard(List<Aluno> alunos, int selectedIdx, bool isDark) {
    const Color primaryColor = Color(0xFF1E3A8A);
    final Color accent = isDark ? const Color(0xFF60A5FA) : primaryColor;
    final bool hasMultiple = alunos.length > 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: Colors.white10) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alunos Vinculados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
          if (hasMultiple) ...[
            const SizedBox(height: 4),
            Text(
              'Toque em um aluno para ver as faturas dele.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...List.generate(alunos.length, (index) {
            final aluno = alunos[index];
            final bool isSelected = hasMultiple && selectedIdx == index;
            return Padding(
              padding: EdgeInsets.only(bottom: index == alunos.length - 1 ? 0 : 8),
              child: Material(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: hasMultiple
                      ? () => setState(() => _selectedAlunoIndex = index)
                      : null,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: isSelected ? Border.all(color: accent, width: 1.5) : null,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isDark
                              ? const Color(0xFF3B82F6).withAlpha(40)
                              : primaryColor.withAlpha(30),
                          child: Text(
                            aluno.nomeCompleto.isNotEmpty
                                ? aluno.nomeCompleto[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                aluno.nomeCompleto,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : primaryColor,
                                ),
                              ),
                              Text(
                                aluno.serieAno,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check_circle, size: 22, color: accent),
                        ],
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

  Widget _buildSocialMediaIcons(bool isDark) {
    return Column(
      children: [
        Text(
          'Fale Conosco',
          style: TextStyle(
            fontSize: 17, // Fonte aumentada
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialIcon(
              FontAwesomeIcons.whatsapp,
              const Color(0xFF25D366),
              'https://wa.me/5581995602150',
              isDark,
            ),
            const SizedBox(width: 24),
            _buildSocialIcon(
              FontAwesomeIcons.instagram,
              const Color(0xFFE4405F),
              'https://instagram.com/csa_agrestina20',
              isDark,
            ),
            const SizedBox(width: 24),
            _buildSocialIcon(
              FontAwesomeIcons.facebook,
              const Color(0xFF1877F2),
              'https://facebook.com/CsaAgrestina',
              isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIcon(FaIconData icon, Color color, String url, bool isDark) {
    return InkWell(
      onTap: () => _launchURL(url),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: BoxShape.circle,
          border: isDark ? Border.all(color: Colors.white10) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 40 : 15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FaIcon(icon, color: color, size: 28),
      ),
    );
  }

  Widget _buildDetalheRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Expanded( 
          child: Text(
            label, 
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : Colors.black54,
              fontSize: 17,
            ), // Fonte aumentada
          ),
        ),
        const SizedBox(width: 16), 
        Text(
          value, 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: isDark ? Colors.white : Colors.black87,
          ), // Fonte aumentada
          softWrap: false, 
        ),
      ],
    );
  }
}

String capitalize(String s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '';
