// Arquivo: lib/main.dart
// MODIFICADO: Trocado ThemeData.dark() por AppTheme.darkTheme
// MODIFICADO: Adicionado 'builder' ao MaterialApp para travar o fator de escala da fonte em 1.0 (ignorando as configurações do sistema).

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
      themeMode: Provider.of<ThemeProvider>(context).themeMode,

      // +++ INÍCIO DA SOLUÇÃO (TRAVAR FONTE) +++
      // Este 'builder' intercepta a configuração de fonte do sistema
      // e força o app a usar sempre a escala 1.0 (padrão).
      builder: (context, child) {
        // Pega os dados de mídia atuais (que contêm o fator de escala do sistema)
        final mediaQueryData = MediaQuery.of(context);
        
        // Retorna um novo MediaQuery que envolve todo o app
        return MediaQuery(
          // Copia os dados de mídia, mas sobrescreve o 'textScaler'
          data: mediaQueryData.copyWith(
            // TextScaler.noScaling é a forma moderna de forçar a escala em 1.0
            textScaler: TextScaler.noScaling,
          ),
          child: child!,
        );
      },
      // +++ FIM DA SOLUÇÃO (TRAVAR FONTE) +++

      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}