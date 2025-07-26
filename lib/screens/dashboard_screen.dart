// Arquivo: lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:csapp/screens/payment_screen.dart';
import 'package:csapp/screens/settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic> dashboardData;
  final String cpf;

  const DashboardScreen({super.key, required this.dashboardData, required this.cpf});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final mensalidade = dashboardData['ultima_mensalidade'] ?? 0.0;
    final bool temDebito = (mensalidade is num) && mensalidade > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Financeiro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá, ${dashboardData['nome_completo'] ?? 'Responsável'}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow('Aluno(a) em:', dashboardData['serie_ano'] ?? 'N/A'),
                    const Divider(),
                    _buildInfoRow(
                      'Situação da Matrícula:',
                      dashboardData['situacao_matricula'] ?? 'N/A',
                      valueColor: (dashboardData['situacao_matricula'] == 'Ativa')
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Financeiro',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Última mensalidade devida:',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      currencyFormat.format(mensalidade),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: temDebito ? Theme.of(context).colorScheme.error : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: temDebito ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => PaymentScreen(cpf: cpf)),
                        );
                      } : null,
                      icon: const Icon(Icons.pix),
                      label: const Text('PAGAR COM PIX'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}