import 'package:flutter/material.dart';
import 'package:csapp/screens/payment_screen.dart';
import 'package:intl/intl.dart';

// --- Data Models (unchanged) ---
class DashboardData {
  final String nomeResponsavel;
  final String cpfResponsavel;
  final List<Aluno> alunos;
  DashboardData(
      {required this.nomeResponsavel,
      required this.alunos,
      required this.cpfResponsavel});
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

// COLE ESTE BLOCO CORRETO NO LUGAR DA CLASSE MENSALIDADE EXISTENTE

class Mensalidade {
  final String id;
  final DateTime mesReferencia; // O campo que estava faltando
  final double valorNominal;
  final String status;

  Mensalidade({
    required this.id,
    required this.mesReferencia, // O campo que estava faltando
    required this.valorNominal,
    required this.status,
  });

  factory Mensalidade.fromJson(Map<String, dynamic> json) {
    return Mensalidade(
      id: json['id'],
      mesReferencia: DateTime.parse(json['mes_referencia']), // O campo que estava faltando
      valorNominal: double.parse(json['valor_nominal']),
      status: json['status'],
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic> responseData;
  const DashboardScreen({super.key, required this.responseData});

  @override
  Widget build(BuildContext context) {
    final dashboardData = DashboardData.fromJson(responseData);
    
    // Modern color palette
    const Color primaryBlue = Color(0xFF2563EB);
    const Color lightBlue = Color(0xFFEFF6FF);
    const Color darkBlue = Color(0xFF1E40AF);
    const Color accentPurple = Color(0xFF7C3AED);
    const Color backgroundGray = Color(0xFFF8FAFC);
    const Color cardWhite = Color(0xFFFFFFFF);
    const Color textDark = Color(0xFF1F2937);
    const Color textGray = Color(0xFF6B7280);
    const Color successGreen = Color(0xFF10B981);
    const Color warningRed = Color(0xFFEF4444);

    // Find next payment
    Mensalidade? proximaMensalidade;
    if (dashboardData.alunos.isNotEmpty &&
        dashboardData.alunos.first.mensalidadesPendentes.isNotEmpty) {
      proximaMensalidade = dashboardData.alunos.first.mensalidadesPendentes.first;
    }

    return Scaffold(
      backgroundColor: backgroundGray,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: primaryBlue,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryBlue, darkBlue],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Olá,',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dashboardData.nomeResponsavel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
                                onPressed: () => Navigator.pushNamed(context, '/settings'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Card
                  _buildModernPaymentCard(context, proximaMensalidade, primaryBlue, warningRed, successGreen),
                  const SizedBox(height: 24),

                  // Quick Actions
                  const Text(
                    'Ações Rápidas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildModernActionsGrid(context, primaryBlue, accentPurple),
                  const SizedBox(height: 32),

                  // Students Section
                  if (dashboardData.alunos.isNotEmpty) ...[
                    Row(
                      children: [
                        const Text(
                          'Estudantes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: lightBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${dashboardData.alunos.length}',
                            style: const TextStyle(
                              color: primaryBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...dashboardData.alunos.map((aluno) => _buildModernStudentCard(context, aluno, primaryBlue, accentPurple)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPaymentCard(BuildContext context, Mensalidade? mensalidade, Color primaryColor, Color warningColor, Color successColor) {
    final formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    if (mensalidade == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [successColor, successColor.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: successColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tudo em dia!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nenhuma mensalidade pendente',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with warning indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: warningColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: warningColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.schedule,
                    color: warningColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Mensalidade Pendente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          
          // Payment details
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Valor a pagar',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formatadorMoeda.format(mensalidade.valorNominal),
                            style: TextStyle(
                              color: warningColor,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Vence em ${DateFormat('dd/MM/yyyy').format(mensalidade.mesReferencia)}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primaryColor, primaryColor.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
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
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.pix,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Pagar\ncom Pix',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: () { /* TODO: Navigate to history */ },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                          ),
                          child: Text(
                            'Ver histórico de pagamentos',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionsGrid(BuildContext context, Color primaryColor, Color accentColor) {
    final actions = [
      {'icon': Icons.receipt_long_outlined, 'label': 'Histórico', 'color': primaryColor},
      {'icon': Icons.support_agent_outlined, 'label': 'Suporte', 'color': accentColor},
      {'icon': Icons.notifications_outlined, 'label': 'Avisos', 'color': const Color(0xFFEF4444)},
    ];

    return Row(
      children: actions.map((action) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: action == actions.last ? 0 : 12,
            ),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 0,
              shadowColor: Colors.black.withOpacity(0.05),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (action['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          action['icon'] as IconData,
                          color: action['color'] as Color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        action['label'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModernStudentCard(BuildContext context, Aluno aluno, Color primaryColor, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accentColor.withOpacity(0.2), primaryColor.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.person_outline,
            color: accentColor,
            size: 24,
          ),
        ),
        title: Text(
          aluno.nomeCompleto,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF1F2937),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            aluno.serieAno,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: aluno.mensalidadesPendentes.isEmpty 
                ? const Color(0xFF10B981).withOpacity(0.1)
                : const Color(0xFFEF4444).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            aluno.mensalidadesPendentes.isEmpty ? 'Em dia' : '${aluno.mensalidadesPendentes.length} pendente${aluno.mensalidadesPendentes.length > 1 ? 's' : ''}',
            style: TextStyle(
              color: aluno.mensalidadesPendentes.isEmpty 
                  ? const Color(0xFF10B981)
                  : const Color(0xEF4444),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}