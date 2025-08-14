// Arquivo: lib/screens/main_screen.dart
// VERSÃO CORRIGIDA: Removida importação não utilizada.

import 'package:flutter/material.dart';
import 'package:educsa/screens/profile_screen.dart';
import 'package:educsa/screens/payment_screen.dart';
import 'package:educsa/screens/invoice_history_screen.dart';
import 'package:educsa/screens/calendar_screen.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// import 'dart:developer' as developer; // <-- LINHA REMOVIDA

// --- INÍCIO: MODELOS DE DADOS (Sem alterações) ---
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
// --- FIM: MODELOS DE DADOS ---


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
      _DashboardPage(responseData: widget.responseData),
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
        ),
      ),
    );
  }
}


// --- WIDGET DA PÁGINA FINANCEIRO (ANTIGO DASHBOARD) ---
class _DashboardPage extends StatefulWidget {
  final Map<String, dynamic> responseData;
  const _DashboardPage({required this.responseData});
  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  Future<DashboardData>? _dashboardDataFuture;

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = Future.value(DashboardData.fromJson(widget.responseData));
  }

  Future<void> _reloadData() async {
    final cpf = DashboardData.fromJson(widget.responseData).cpfResponsavel;
    setState(() {
       _dashboardDataFuture = _fetchDashboardData(cpf);
    });
  }

  Future<DashboardData> _fetchDashboardData(String cpf) async {
      final url = Uri.parse('https://csa-url-app.onrender.com/api/login/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'cpf': cpf, 'password': 'dummy_password_for_refresh'}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return DashboardData.fromJson(responseData);
      } else {
        return DashboardData.fromJson(widget.responseData);
      }
  }


  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E3A8A);
    
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: FutureBuilder<DashboardData>(
        future: _dashboardDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Erro ao carregar dados: ${snapshot.error}'));
          }
          final dashboardData = snapshot.data!;
          Mensalidade? proximaMensalidade;
          
          for (var aluno in dashboardData.alunos) {
            if (aluno.mensalidadesPendentes.isNotEmpty) {
                proximaMensalidade = aluno.mensalidadesPendentes.first;
                break; 
            }
          }
          
          return RefreshIndicator(
            onRefresh: _reloadData,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  toolbarHeight: 80,
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  leadingWidth: 80,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0), 
                    child: Image.asset('assets/images/logo.jpg', fit: BoxFit.contain),
                  ),
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Bem-vindo(a),', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300, color: Colors.white)),
                      Text(
                        dashboardData.nomeResponsavel,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  centerTitle: true,
                  actions: const [
                    SizedBox(width: 56)
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildFaturaCard(context, proximaMensalidade, dashboardData.cpfResponsavel, primaryColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'PAGA':
        return {'text': 'PAGO', 'color': Colors.green.shade800, 'bgColor': Colors.green.shade100};
      case 'ATRASADA':
        return {'text': 'EM ATRASO', 'color': Colors.red.shade800, 'bgColor': Colors.red.shade100};
      case 'PENDENTE':
        return {'text': 'PENDENTE', 'color': Colors.orange.shade800, 'bgColor': Colors.orange.shade100};
      case 'CANCELADA':
        return {'text': 'CANCELADA', 'color': Colors.grey.shade700, 'bgColor': Colors.grey.shade300};
      default:
        return {'text': status, 'color': Colors.black, 'bgColor': Colors.grey.shade200};
    }
  }

  Widget _buildFaturaCard(BuildContext context, Mensalidade? mensalidade, String cpf, Color primaryColor) {
    final formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    if (mensalidade == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text(
                'Tudo em dia! Nenhuma mensalidade pendente.',
                style: TextStyle(fontSize: 16, color: Colors.green),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InvoiceHistoryScreen(responsavelCpf: cpf),
                    ),
                  );
                },
                child: const Text('Ver histórico de faturas'),
              ),
            ],
          ),
        ),
      );
    }

    final statusInfo = _getStatusInfo(mensalidade.status);

    return Column(
      children: [
        Card(
          elevation: 4,
          shadowColor: Colors.grey.withAlpha(77),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mensalidade de ${DateFormat('MMMM', 'pt_BR').format(mensalidade.mesReferencia)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusInfo['bgColor'],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusInfo['text'],
                        style: TextStyle(color: statusInfo['color'], fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  formatadorMoeda.format(mensalidade.valorFinal),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
                Text(
                  'Vencimento em ${DateFormat('dd/MM/yyyy').format(mensalidade.dataVencimento)}',
                  style: const TextStyle(color: Colors.grey),
                ),
                if (mensalidade.status == 'ATRASADA') ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(),
                  ),
                  const Text(
                    'Detalhamento da Cobrança:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _buildDetalheRow('Valor Original', formatadorMoeda.format(mensalidade.valorNominal)),
                  const SizedBox(height: 4),
                  _buildDetalheRow('Multa por atraso', formatadorMoeda.format(mensalidade.multa)),
                  const SizedBox(height: 4),
                  _buildDetalheRow('Juros (${mensalidade.diasAtraso} dias)', formatadorMoeda.format(mensalidade.juros)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                            mensalidadeId: mensalidade.id,
                            valor: mensalidade.valorFinal.toStringAsFixed(2),
                            mesReferencia: DateFormat('MM/yyyy').format(mensalidade.mesReferencia),
                          ),
                        ),
                      );
                      _reloadData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Pagar com Pix', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InvoiceHistoryScreen(responsavelCpf: cpf),
              ),
            );
          },
          icon: const Icon(Icons.receipt_long_outlined, size: 20),
          label: const Text('Ver todas as faturas'),
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: BorderSide(color: primaryColor.withAlpha(128)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
