// Arquivo: lib/main.dart

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
      title: 'CSApp',
      // +++ TEMA APLICADO +++
      theme: AppTheme.theme,
      darkTheme: ThemeData.dark(), // Pode ser customizado depois
      themeMode: Provider.of<ThemeProvider>(context).themeMode,
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
