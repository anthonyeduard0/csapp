// Arquivo: lib/theme/app_theme.dart (VERSÃO CORRIGIDA)

import 'package:flutter/material.dart';

class AppTheme {
  // --- Cores Principais ---
  static const Color primary = Color(0xFF1E3A8A);
  static const Color accent = Color(0xFF8B5CF6);
  static const Color background = Color.fromARGB(255, 243, 244, 246); // Cinza claro
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  // --- Tema Geral do App ---
  static ThemeData get theme {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      
      // Tema da AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      // Tema dos Cards
      // CORREÇÃO: Trocado CardTheme por CardThemeData
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        // CORREÇÃO: Trocado withOpacity por withAlpha
        shadowColor: Colors.black.withAlpha(13), // 0.05 * 255 = 12.75 -> 13
      ),

      // Tema da Barra de Navegação
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8.0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
      ),

      // Tema dos Botões
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
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
        labelColor: primary,
        unselectedLabelColor: Colors.white,
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
