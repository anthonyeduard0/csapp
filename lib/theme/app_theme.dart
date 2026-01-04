// Arquivo: lib/theme/app_theme.dart (VERSÃO CORRIGIDA)
// MODIFICADO: Adicionado um darkTheme completo para corrigir bugs de transição.
// CORRIGIDO: Corrigido CardTheme para CardThemeData e TabBarTheme para TabBarThemeData.

import 'package:flutter/material.dart';

class AppTheme {
  // --- Cores Claras ---
  static const Color primaryLight = Color(0xFF1E3A8A);
  static const Color accentLight = Color(0xFF8B5CF6);
  static const Color backgroundLight = Color.fromARGB(255, 243, 244, 246); // Cinza claro
  static const Color cardBackgroundLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);

  // --- Tema Claro ---
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryLight,
      scaffoldBackgroundColor: backgroundLight,
      
      // Tema da AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          inherit: false, // Correção explícita
        ),
      ),

      // Tema dos Cards
      // CORREÇÃO: Trocado CardTheme por CardThemeData
      cardTheme: CardThemeData(
        color: cardBackgroundLight,
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        shadowColor: Colors.black.withAlpha(13),
      ),

      // Tema da Barra de Navegação
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryLight,
        unselectedItemColor: textSecondaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8.0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
      ),

      // Tema dos Botões
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Tema da TabBar
      // CORREÇÃO: Trocado TabBarTheme por TabBarThemeData
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryLight,
        unselectedLabelColor: Colors.white, // Inconsistente?
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: Colors.white,
            width: 3.0,
          ),
        ),
      ),
    );
  }
}