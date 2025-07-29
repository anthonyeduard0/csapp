// Arquivo: lib/screens/dashboard_screen.dart
// VERSÃO COMPLETA COM PUXAR PARA ATUALIZAR E NOVO DESIGN

import 'package:flutter/material.dart';
import 'package:csapp/screens/login_screen.dart';
import 'package:csapp/screens/payment_screen.dart';
import 'package:csapp/screens/invoice_history_screen.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// (As classes de modelo de dados continuam aqui, sem alterações)
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
  final List<Mensalidade> mensalidadesPendentes;
  Aluno({ required this.nomeCompleto, required this.serieAno, required this.mensalidadesPendentes });
  factory Aluno.fromJson(Map<String, dynamic> json) {
    var mensalidadesList = json['mensalidades_pendentes'] as List;
    List<Mensalidade> mensalidades = mensalidadesList.map((i) => Mensalidade.fromJson(i)).toList();
    return Aluno(
      nomeCompleto: json['nome_completo'],
      serieAno: json['serie_ano'],
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
  final List<Aluno> alunos;
  DashboardData({ required this.nomeResponsavel, required this.cpfResponsavel, required this.alunos });
  factory DashboardData.fromJson(Map<String, dynamic> json) {
    var alunosList = json['alunos'] as List;
    List<Aluno> alunos = alunosList.map((i) => Aluno.fromJson(i)).toList();
    return DashboardData(
      nomeResponsavel: json['nome_completo'],
      cpfResponsavel: json['cpf'],
      alunos: alunos,
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> responseData;
  const DashboardScreen({super.key, required this.responseData});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<DashboardData>? _dashboardDataFuture;

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = Future.value(DashboardData.fromJson(widget.responseData));
  }

  Future<void> _reloadData() async {
    final cpf = DashboardData.fromJson(widget.responseData).cpfResponsavel;
    final url = Uri.parse('https://csa-url-app.onrender.com/api/login/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'cpf': cpf, 'senha': ''}),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            _dashboardDataFuture = Future.value(DashboardData.fromJson(responseData));
          });
        }
      }
    } catch (e) {
      print("Erro ao recarregar dados: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E3A8A);
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
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
          if (dashboardData.alunos.isNotEmpty &&
              dashboardData.alunos.first.mensalidadesPendentes.isNotEmpty) {
            proximaMensalidade = dashboardData.alunos.first.mensalidadesPendentes.first;
          }
          
          // --- ADICIONADO O REFRESHINDICATOR ---
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
                  leadingWidth: 64,
                  leading: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset('assets/images/logo.jpg'),
                  ),
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Bem-vindo(a),', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300)),
                      Text(
                        dashboardData.nomeResponsavel,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.exit_to_app),
                      tooltip: 'Sair',
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (Route<dynamic> route) => false,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildFaturaCard(context, proximaMensalidade, dashboardData.cpfResponsavel, primaryColor),
                        const SizedBox(height: 24),
                        _buildAcoesGrid(context, dashboardData.cpfResponsavel),
                        // --- CARD DO ALUNO REMOVIDO DAQUI ---
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

  // (O resto do código, como _buildFaturaCard, _buildDetalheRow, etc., continua o mesmo)
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
    bool estaAtrasada = mensalidade.diasAtraso > 0;
    return Column(
      children: [
        Card(
          elevation: 4,
          shadowColor: Colors.grey.withOpacity(0.3),
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
                    if (estaAtrasada)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'EM ATRASO',
                          style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold, fontSize: 12),
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
                if (estaAtrasada) ...[
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
            side: BorderSide(color: primaryColor.withOpacity(0.5)),
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

  Widget _buildAcoesGrid(BuildContext context, String cpf) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildGridItem(context, icon: Icons.receipt_long, label: 'Histórico', onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InvoiceHistoryScreen(responsavelCpf: cpf),
            ),
          );
        }),
        _buildGridItem(context, icon: Icons.support_agent, label: 'Suporte', onTap: () {}),
        _buildGridItem(context, icon: Icons.info_outline, label: 'Avisos', onTap: () {}),
      ],
    );
  }

  Widget _buildGridItem(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: const Color(0xFF1E3A8A)),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
