// Arquivo: lib/screens/support_screen.dart
// VERSÃO COM PUXAR PARA ATUALIZAR

import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  // +++ MUDANÇA: Lógica de refresh (simulada) +++
  Future<void> _refreshData() async {
    // Como esta tela é estática, apenas simulamos uma espera.
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E3A8A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suporte'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              color: primaryColor.withOpacity(0.9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              child: const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Que tipo de suporte você precisa hoje?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSupportItem(
              icon: Icons.school_outlined,
              title: 'Orientações Acadêmicas',
              subtitle: 'Materiais e guias para sua jornada.',
              onTap: () {},
            ),
            _buildSupportItem(
              icon: Icons.headset_mic_outlined,
              title: 'Atendimento',
              subtitle: 'Requerimentos e atendimento remoto.',
              onTap: () {},
            ),
            _buildSupportItem(
              icon: Icons.forum_outlined,
              title: 'Ambiente de Interação',
              subtitle: 'Tire dúvidas sobre o conteúdo.',
              onTap: () {},
            ),
            _buildSupportItem(
              icon: Icons.phone_android_outlined,
              title: 'Apresentação do App',
              subtitle: 'Acesse o passo a passo das áreas.',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1E3A8A), size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }
}