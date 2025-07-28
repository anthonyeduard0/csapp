import 'package:flutter/material.dart';
import 'package:csapp/screens/payment_screen.dart';
import 'package:intl/intl.dart'; // Para formatação de data e moeda

// --- Modelos de Dados (sem alteração) ---
class DashboardData {
  final String nomeResponsavel;
  final List<Aluno> alunos;
  DashboardData({required this.nomeResponsavel, required this.alunos});
  factory DashboardData.fromJson(Map<String, dynamic> json) {
    var alunosList = json['alunos'] as List;
    List<Aluno> alunos = alunosList.map((i) => Aluno.fromJson(i)).toList();
    return DashboardData(
      nomeResponsavel: json['nome_completo'],
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
// --- Fim dos Modelos de Dados ---


class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic> responseData;

  const DashboardScreen({super.key, required this.responseData});

  @override
  Widget build(BuildContext context) {
    final dashboardData = DashboardData.fromJson(responseData);
    // Define a paleta de cores baseada na sua logo
    const Color primaryColor = Color(0xFF1E3A8A); // Azul escuro
    const Color accentColor = Color(0xFF8B5CF6); // Roxo/Violeta
    const Color lightBackgroundColor = Color(0xFFF3F4F6); // Um cinza bem claro

    // Encontra a próxima mensalidade a ser paga (a mais antiga pendente)
    Mensalidade? proximaMensalidade;
    if (dashboardData.alunos.isNotEmpty &&
        dashboardData.alunos.first.mensalidadesPendentes.isNotEmpty) {
      proximaMensalidade = dashboardData.alunos.first.mensalidadesPendentes.first;
    }

    return Scaffold(
      backgroundColor: lightBackgroundColor,
      appBar: AppBar(
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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Card Principal de Fatura ---
          _buildFaturaCard(context, proximaMensalidade, primaryColor, accentColor),
          const SizedBox(height: 24),

          // --- Grade de Ações Rápidas ---
          _buildAcoesGrid(context, lightBackgroundColor),
          const SizedBox(height: 24),

          // --- Card de Informações do Aluno ---
          ...dashboardData.alunos.map((aluno) => _buildAlunoCard(context, aluno)),
        ],
      ),
    );
  }

  // Widget para o card principal de fatura
  Widget _buildFaturaCard(BuildContext context, Mensalidade? mensalidade, Color primaryColor, Color accentColor) {
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
            // Lado Esquerdo: Valor e Vencimento
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
                    onPressed: () { /* TODO: Navegar para tela de histórico */ },
                    child: const Text('Ver todas as faturas'),
                  ),
                ],
              ),
            ),
            // Lado Direito: Botão de Pagar
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      mensalidadeId: mensalidade.id,
                      valor: mensalidade.valorNominal.toStringAsFixed(2),
                      mesReferencia: DateFormat('MM/yyyy').format(mensalidade.mesReferencia),
                    ),
                  ),
                );
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

  // Widget para a grade de botões de ação
  Widget _buildAcoesGrid(BuildContext context, Color backgroundColor) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildGridItem(context, icon: Icons.receipt_long, label: 'Histórico', onTap: () {}),
        _buildGridItem(context, icon: Icons.support_agent, label: 'Suporte', onTap: () {}),
        _buildGridItem(context, icon: Icons.info_outline, label: 'Avisos', onTap: () {}),
      ],
    );
  }

  // Widget para cada item da grade
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

  // Widget para o card de informações do aluno
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
