// Arquivo: lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csapp/providers/theme_provider.dart';
import 'package:csapp/screens/login_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Carrega o tema salvo ao iniciar
    Provider.of<ThemeProvider>(context, listen: false).loadTheme();
    
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'App Escola',
          theme: ThemeData.light(useMaterial3: true),
          darkTheme: ThemeData.dark(useMaterial3: true),
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          home: const LoginScreen(),
        );
      },
    );
  }
}