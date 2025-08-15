// Arquivo: lib/screens/main_screen.dart
// VERSÃO CORRIGIDA: Barra de navegação restaurada ao estilo original.

import 'package:flutter/material.dart';
import 'package:educsa/screens/profile_screen.dart';
import 'package:educsa/screens/payment_screen.dart';
import 'package:educsa/screens/invoice_history_screen.dart';
import 'package:educsa/screens/calendar_screen.dart';
import 'package:intl/intl.dart';

// --- MODELOS DE DADOS (Sem alterações) ---
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
  Mensalidade({ required this.id, required this.mesReferencia, required this.valorNominal, required this.valorFinal, required this.status, required this.dataVencimento, required this.multa, required this.juros, required this.diasAtraso });
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
  final List<Mensalidade> mensalidades;
  AlunoComMensalidades({required this.nomeCompleto, required this.mensalidades});
  factory AlunoComMensalidades.fromJson(Map<String, dynamic> json) {
    var mensalidadesList = json['mensalidades'] as List;
    List<Mensalidade> mensalidades = mensalidadesList.map((i) => Mensalidade.fromJson(i)).toList();
    mensalidades.sort((a, b) => b.dataVencimento.compareTo(a.dataVencimento));
    return AlunoComMensalidades(
      nomeCompleto: json['nome_completo'],
      mensalidades: mensalidades,
    );
  }
}
class DashboardData {
  final String nomeResponsavel;
  final String cpfResponsavel;
  final String email;
  final String? telefone;
  final String? fotoPerfilUrl;
  final List<Aluno> alunos;
  DashboardData({ required this.nomeResponsavel, required this.cpfResponsavel, required this.email, this.telefone, this.fotoPerfilUrl, required this.alunos });
  factory DashboardData.fromJson(Map<String, dynamic> json) {
    var alunosList = json['alunos'] as List;
    List<Aluno> alunos = alunosList.map((i) => Aluno.fromJson(i)).toList();
    return DashboardData(
      nomeResponsavel: json['nome_completo'],
      cpfResponsavel: json['cpf'],
      email: json['email'],
      telefone: json['telefone'],
      fotoPerfilUrl: json['foto_perfil_url'],
      alunos: alunos,
    );
  }
  DashboardData copyWith({
    String? nomeResponsavel,
    String? cpfResponsavel,
    String? email,
    String? telefone,
    String? fotoPerfilUrl,
    List<Aluno>? alunos,
  }) {
    return DashboardData(
      nomeResponsavel: nomeResponsavel ?? this.nomeResponsavel,
      cpfResponsavel: cpfResponsavel ?? this.cpfResponsavel,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      fotoPerfilUrl: fotoPerfilUrl ?? this.fotoPerfilUrl,
      alunos: alunos ?? this.alunos,
    );
  }
}

// --- TELA PRINCIPAL COM BARRA DE NAVEGAÇÃO ---
class MainScreen extends StatefulWidget {
  final Map<String, dynamic> responseData;
  const MainScreen({super.key, required this.responseData});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      FinancialScreen(responseData: widget.responseData),
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
    const Color primaryColor = Color(0xFF1E3A8A);
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      // --- BARRA DE NAVEGAÇÃO RESTAURADA ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.monetization_on_outlined),
              activeIcon: Icon(Icons.monetization_on),
              label: 'Financeiro',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Calendário',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey[600],
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          iconSize: 26,
          selectedFontSize: 14,
          unselectedFontSize: 12,
          showUnselectedLabels: true, // Garante que os nomes sempre apareçam
        ),
      ),
    );
  }
}


// --- WIDGET DA PÁGINA FINANCEIRO (ANTIGO DASHBOARD) ---
class FinancialScreen extends StatefulWidget {
  final Map<String, dynamic> responseData;
  const FinancialScreen({required this.responseData, super.key});
  @override
  State<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends State<FinancialScreen> {
  Future<DashboardData>? _dashboardDataFuture;

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = Future.value(DashboardData.fromJson(widget.responseData));
  }

  Future<void> _reloadData() async {
    setState(() {
      _dashboardDataFuture = Future.value(DashboardData.fromJson(widget.responseData));
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E3A8A);
    const Color accentColor = Color(0xFF8B5CF6);
    const Color backgroundColor = Color(0xFFF8FAFC);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ primaryColor, accentColor ],
          ),
        ),
        child: SafeArea(
          bottom: false, // SafeArea não precisa de padding inferior com a nav bar fixa
          child: FutureBuilder<DashboardData>(
            future: _dashboardDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Center(child: Text('Erro ao carregar dados: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
              }
              final dashboardData = snapshot.data!;
              Mensalidade? proximaMensalidade;
              for (var aluno in dashboardData.alunos) {
                if (aluno.mensalidadesPendentes.isNotEmpty) {
                    proximaMensalidade = aluno.mensalidadesPendentes.first;
                    break; 
                }
              }

              return Column(
                children: [
                  _buildHeader(dashboardData),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: RefreshIndicator(
                        onRefresh: _reloadData,
                        color: primaryColor,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24.0),
                          child: _buildFaturaCard(context, proximaMensalidade, dashboardData.cpfResponsavel),
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
            backgroundImage: data.fotoPerfilUrl != null ? NetworkImage(data.fotoPerfilUrl!) : null,
            child: data.fotoPerfilUrl == null ? const Icon(Icons.person, size: 30, color: Colors.white) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bem-vindo(a),', style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text(
                  data.nomeResponsavel,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
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
      case 'PAGA': return {'text': 'PAGO', 'color': Colors.green.shade800, 'bgColor': Colors.green.shade100, 'icon': Icons.check_circle_rounded};
      case 'ATRASADA': return {'text': 'EM ATRASO', 'color': Colors.red.shade800, 'bgColor': Colors.red.shade100, 'icon': Icons.warning_rounded};
      case 'PENDENTE': return {'text': 'PENDENTE', 'color': Colors.orange.shade800, 'bgColor': Colors.orange.shade100, 'icon': Icons.schedule_rounded};
      case 'CANCELADA': return {'text': 'CANCELADA', 'color': Colors.grey.shade700, 'bgColor': Colors.grey.shade300, 'icon': Icons.cancel_rounded};
      default: return {'text': status, 'color': Colors.black, 'bgColor': Colors.grey.shade200, 'icon': Icons.help_outline_rounded};
    }
  }

  Widget _buildFaturaCard(BuildContext context, Mensalidade? mensalidade, String cpf) {
    const Color primaryColor = Color(0xFF1E3A8A);
    const Color accentColor = Color(0xFF8B5CF6);
    final formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    if (mensalidade == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10)],
        ),
        child: Column(
          children: [
            const Icon(Icons.verified_user_rounded, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Tudo em dia!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Nenhuma mensalidade pendente encontrada.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => InvoiceHistoryScreen(responsavelCpf: cpf)));
              },
              child: const Text('Ver histórico de faturas'),
            ),
          ],
        ),
      );
    }

    final statusInfo = _getStatusInfo(mensalidade.status);
    final mesFormatado = capitalize(DateFormat('MMMM', 'pt_BR').format(mensalidade.mesReferencia));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text('Próxima Fatura: $mesFormatado', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor))
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: statusInfo['bgColor'], borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Icon(statusInfo['icon'], size: 16, color: statusInfo['color']),
                        const SizedBox(width: 4),
                        Text(statusInfo['text'], style: TextStyle(color: statusInfo['color'], fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(formatadorMoeda.format(mensalidade.valorFinal), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              Text('Vencimento em ${DateFormat('dd/MM/yyyy').format(mensalidade.dataVencimento)}', style: const TextStyle(color: Colors.grey)),
              if (mensalidade.status == 'ATRASADA') ...[
                const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Divider()),
                _buildDetalheRow('Valor Original', formatadorMoeda.format(mensalidade.valorNominal)),
                const SizedBox(height: 4),
                _buildDetalheRow('Multa por atraso', formatadorMoeda.format(mensalidade.multa)),
                const SizedBox(height: 4),
                _buildDetalheRow('Juros (${mensalidade.diasAtraso} dias)', formatadorMoeda.format(mensalidade.juros)),
              ],
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [primaryColor, accentColor]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: primaryColor.withAlpha(76), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(
                      builder: (context) => PaymentScreen(
                        mensalidadeId: mensalidade.id,
                        valor: mensalidade.valorFinal.toStringAsFixed(2),
                        mesReferencia: DateFormat('MM/yyyy').format(mensalidade.mesReferencia),
                      ),
                    ));
                    _reloadData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pix, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Pagar com Pix', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => InvoiceHistoryScreen(responsavelCpf: cpf)));
          },
          icon: const Icon(Icons.receipt_long_outlined, size: 20),
          label: const Text('Ver todas as faturas'),
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            backgroundColor: Colors.white,
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDetalheRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

String capitalize(String s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '';
