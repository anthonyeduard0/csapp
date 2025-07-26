// Arquivo: lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csapp/providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        children: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return SwitchListTile(
                title: const Text('Tema Escuro'),
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Termos de Uso'),
            onTap: () { /* Lógica para abrir link */ },
          ),
          ListTile(
            title: const Text('Política de Privacidade'),
            onTap: () { /* Lógica para abrir link */ },
          ),
          const Divider(),
          const ListTile(
            title: Text('Versão do App'),
            subtitle: Text('1.0.0'), // Pode ser obtido dinamicamente com o package_info_plus
          ),
        ],
      ),
    );
  }
}