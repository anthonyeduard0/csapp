// Arquivo: lib/main.dart
// MODIFICADO: Trocado ThemeData.dark() por AppTheme.darkTheme

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart'; // +++ IMPORTAÇÃO DO TEMA +++

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  await initializeDateFormatting('pt_BR', null); 

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduCSA',
      // +++ TEMA APLICADO +++
      theme: AppTheme.theme,
      // --- CORREÇÃO 2: Use o tema escuro customizado ---
      darkTheme: AppTheme.darkTheme, 
      themeMode: Provider.of<ThemeProvider>(context).themeMode,
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}