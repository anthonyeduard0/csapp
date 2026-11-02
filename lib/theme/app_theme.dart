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

  // --- Cores Escuras ---
  static const Color primaryDark = Color(0xFF3B82F6);
  static const Color accentDark = Color(0xFFA78BFA);
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color cardBackgroundDark = Color(0xFF1E293B); // Slate 800
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // --- Tema Claro ---
  static ThemeData get lightTheme => theme;

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

  // --- Tema Escuro ---
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryDark,
      scaffoldBackgroundColor: backgroundDark,
      cardColor: cardBackgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        secondary: accentDark,
        surface: cardBackgroundDark,
        onPrimary: Colors.white,
        onSurface: textPrimaryDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cardBackgroundDark,
        foregroundColor: textPrimaryDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimaryDark,
          inherit: false,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackgroundDark,
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        shadowColor: Colors.black.withAlpha(50),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardBackgroundDark,
        selectedItemColor: primaryDark,
        unselectedItemColor: textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8.0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
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
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryDark,
        unselectedLabelColor: textSecondaryDark,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: primaryDark,
            width: 3.0,
          ),
        ),
      ),
    );
  }
}
