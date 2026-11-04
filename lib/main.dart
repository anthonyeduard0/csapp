// Arquivo: lib/main.dart
// MODIFICADO: Trocado ThemeData.dark() por AppTheme.darkTheme
// MODIFICADO: Adicionado 'builder' ao MaterialApp para travar o fator de escala da fonte em 1.0 (ignorando as configurações do sistema).
// MODIFICADO: Integração com SentryFlutter via SENTRY_DSN.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

const String sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  await initializeDateFormatting('pt_BR', null); 

  final app = ChangeNotifierProvider(
    create: (context) => ThemeProvider(),
    child: const MyApp(),
  );

  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 0.2;
      },
      appRunner: () => runApp(app),
    );
  } else {
    runApp(app);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduCSA',
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: Provider.of<ThemeProvider>(context).themeMode,

      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        
        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child!,
        );
      },

      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
