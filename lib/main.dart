// Arquivo: lib/main.dart
// CÓDIGO CORRIGIDO

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // 1. IMPORTE O PACOTE NECESSÁRIO
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';

void main() async { // 2. TRANSFORME A FUNÇÃO EM 'async'
  // 3. GARANTA QUE OS WIDGETS DO FLUTTER ESTEJAM PRONTOS
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // 4. INICIALIZE A FORMATAÇÃO DE DATA PARA O PORTUGUÊS DO BRASIL
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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      darkTheme: ThemeData.dark(),
      themeMode: Provider.of<ThemeProvider>(context).themeMode,
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

