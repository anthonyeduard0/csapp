// Arquivo: lib/screens/dashboard_screen.dart
// Substitua o conteúdo do seu arquivo por este código atualizado.

import 'package:flutter/material.dart';
import 'package:csapp/screens/payment_screen.dart';
import 'package:csapp/screens/invoice_history_screen.dart'; // Importe a nova tela
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http; // Importe o http
import 'dart:convert'; // Importe o convert

// --- Modelos de Dados (sem alteração) ---
class DashboardData {
  final String nomeResponsavel;
  final String cpfResponsavel; // Adicionado para passar para a próxima tela
  final List<Aluno> alunos;
  DashboardData({
    required this.nomeResponsavel,
    required this.cpfResponsavel,
    required this.alunos,
  });
  factory DashboardData.fromJson(Map<String, dynamic> json) {
    var alunosList = json['alunos'] as List;
    List<Aluno> alunos = alunosList.map((i) => Aluno.fromJson(i)).toList();
    return DashboardData(
      nomeResponsavel: json['nome_completo'],
      cpfResponsavel: json['cpf'], // Pega o CPF da resposta
      alunos: alunos,
    );
  }
}

class Aluno {
  final String nomeCompleto;
  final String serieAno;
  final List<Mensalidade> mensalidadesPendentes;
  Aluno(
      {required this.nomeCompleto,
      required this.serieAno,
      required this.mensalidadesPendentes});
  factory Aluno.fromJson(Map<String, dynamic> json) {
    var mensalidadesList = json['mensalidades_pendentes'] as List;
    List<Mensalidade> mensalidades =
        mensalidadesList.map((i) => Mensalidade.fromJson(i)).toList();
    return Aluno(
      nomeCompleto: json['nome_completo'],
      serieAno: json['serie_ano'],
      mensalidadesPendentes: mensalidades,
    );
  }
}

class Mensalidade {
  final String id;
  final DateTime mesReferencia;
  final double valorNominal;
  final String status;
  Mensalidade(
      {required this.id,
      required this.mesReferencia,
      required this.valorNominal,
      required this.status});
  factory Mensalidade.fromJson(Map<String, dynamic> json) {
    return Mensalidade(
      id: json['id'],
      mesReferencia: DateTime.parse(json['mes_referencia']),
      valorNominal: double.parse(json['valor_nominal']),
      status: json['status'],
    );
  }
}

// --- TELA TRANSFORMADA EM STATEFULWIDGET ---
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
    // Carrega os dados iniciais recebidos do login
    _dashboardDataFuture = Future.value(DashboardData.fromJson(widget.responseData));
  }

  // Função para recarregar os dados do dashboard a partir da API
  Future<void> _reloadData() async {
    final cpf = DashboardData.fromJson(widget.responseData).cpfResponsavel;
    final url = Uri.parse('https://csa-url-app.onrender.com/api/login/');
    
    try {
      // Simula o login novamente para obter os dados mais recentes
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        // A senha não é necessária aqui, mas a API pode exigir.
        // O ideal seria ter um endpoint de "refresh" que não pedisse a senha.
        // Por simplicidade, vamos apenas recarregar os dados do login.
        // NOTA: Para um app real, armazene a senha de forma segura ou use tokens.
        body: jsonEncode(<String, String>{'cpf': cpf, 'senha': ''}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _dashboardDataFuture = Future.value(DashboardData.fromJson(responseData));
        });
      } else {
         // Se o "re-login" falhar, recarrega com os dados antigos para não quebrar a tela
         setState(() {
            _dashboardDataFuture = Future.value(DashboardData.fromJson(widget.responseData));
         });
      }
    } catch (e) {
      print("Erro ao recarregar dados: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E3A8A);
    const Color accentColor = Color(0xFF8B5CF6);
    const Color lightBackgroundColor = Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: lightBackgroundColor,
      body: FutureBuilder<DashboardData>(
        future: _dashboardDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Erro ao carregar dados.'));
          }

          final dashboardData = snapshot.data!;
          Mensalidade? proximaMensalidade;
          if (dashboardData.alunos.isNotEmpty &&
              dashboardData.alunos.first.mensalidadesPendentes.isNotEmpty) {
            proximaMensalidade = dashboardData.alunos.first.mensalidadesPendentes.first;
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                toolbarHeight: 80,
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Olá,', style: TextStyle(fontSize: 16)),
                    Text(
                      dashboardData.nomeResponsavel,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings, size: 28),
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
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
                      const SizedBox(height: 24),
                      ...dashboardData.alunos.map((aluno) => _buildAlunoCard(context, aluno)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFaturaCard(BuildContext context, Mensalidade? mensalidade, String cpf, Color primaryColor) {
    final formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    if (mensalidade == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'Tudo em dia! Nenhuma mensalidade pendente.',
            style: TextStyle(fontSize: 16, color: Colors.green),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shadowColor: Colors.grey.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Próxima mensalidade', style: TextStyle(color: Colors.grey)),
                  Text(
                    formatadorMoeda.format(mensalidade.valorNominal),
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Vence em ${DateFormat('dd/MM/yyyy').format(mensalidade.mesReferencia)}'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InvoiceHistoryScreen(responsavelCpf: cpf),
                        ),
                      );
                    },
                    child: const Text('Ver todas as faturas'),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                // Navega para a tela de pagamento e ESPERA o resultado
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      mensalidadeId: mensalidade.id,
                      valor: mensalidade.valorNominal.toStringAsFixed(2),
                      mesReferencia: DateFormat('MM/yyyy').format(mensalidade.mesReferencia),
                    ),
                  ),
                );
                // Quando voltar da tela de pagamento, recarrega os dados
                _reloadData();
              },
              icon: const Icon(Icons.pix),
              label: const Text('Pagar Pix'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildAlunoCard(BuildContext context, Aluno aluno) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.2),
          child: const Icon(Icons.person, color: Color(0xFF8B5CF6)),
        ),
        title: Text(aluno.nomeCompleto, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(aluno.serieAno),
      ),
    );
  }
}
