// Arquivo: lib/screens/legal_screen.dart
// ATUALIZADO: Melhorias visuais e cor do título alterada para preto.
// CORRIGIDO: Removido 'primaryColor' não usado e corrigida a deprecation de 'withOpacity'.

import 'package:flutter/material.dart';

class LegalScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    // REMOVIDA: static const Color primaryColor = Color(0xFF1E3A8A);
    const Color backgroundColor = Color(0xFFF8FAFC);
    const Color textColor = Color(0xFF334155);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black, // Cor do título alterada para preto
        elevation: 1,
        // CORREÇÃO: Usando withAlpha para evitar deprecation e manter 20% de opacidade (0.2 * 255 = 51)
        shadowColor: Colors.grey.withAlpha(51),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black), // Cor do ícone alterada para preto
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            color: textColor,
            height: 1.6, // Espaçamento entre linhas para melhor legibilidade
          ),
        ),
      ),
    );
  }
}
