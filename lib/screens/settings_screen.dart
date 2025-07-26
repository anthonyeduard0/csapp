import 'package:csapp/screens/login_screen.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: <Widget>[
          const SizedBox(height: 20),
          _buildSettingsTile(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notificações',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.description_outlined,
            title: 'Termos de serviço',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Política de privacidade',
            onTap: () {},
          ),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: Icons.logout,
            title: 'Sair',
            color: Colors.red,
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final tileColor = color ?? Theme.of(context).textTheme.bodyLarge?.color;
    return ListTile(
      leading: Icon(icon, color: tileColor),
      title: Text(
        title,
        style: TextStyle(color: tileColor, fontSize: 16),
      ),
      // CORREÇÃO FINAL: Uso de withAlpha ao invés de withOpacity
      trailing:
          Icon(Icons.arrow_forward_ios, color: tileColor?.withAlpha(128), size: 16),
      onTap: onTap,
    );
  }
}
