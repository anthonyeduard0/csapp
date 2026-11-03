// Arquivo: lib/screens/terms_acceptance_screen.dart
// ATUALIZADO: Revertido para o fundo branco e melhorado o estilo.
// MODIFICADO: Uso de ApiConfig.baseUrl.
// SINCRONIZADO: Termos de Uso e Política de Privacidade unificados via links externos do GitHub Gist.

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // Importação essencial para o Token
import 'package:url_launcher/url_launcher.dart';
import 'package:educsa/screens/main_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:educsa/api_config.dart';
import 'package:educsa/theme/app_theme.dart';

class TermsAcceptanceWrapper extends StatelessWidget {
  final Map<String, dynamic> responseData;
  const TermsAcceptanceWrapper({super.key, required this.responseData});

  @override
  Widget build(BuildContext context) {
    final bool termosAceitos = responseData['termos_aceitos'] ?? false;

    if (termosAceitos) {
      return MainScreen(responseData: responseData);
    } else {
      return _TermsAcceptancePage(responseData: responseData);
    }
  }
}

class _TermsAcceptancePage extends StatefulWidget {
  final Map<String, dynamic> responseData;
  const _TermsAcceptancePage({required this.responseData});

  @override
  State<_TermsAcceptancePage> createState() => _TermsAcceptancePageState();
}

class _TermsAcceptancePageState extends State<_TermsAcceptancePage> {
  bool _isLoading = false;
  bool _termsAccepted = false;

  void _launchTermsOfUse() async {
    final Uri url = Uri.parse(
        'https://gist.githubusercontent.com/anthonyeduard0/0b02af52257c33aee17c52b2872b19a4/raw/0ecf2b0a2491ff082e5649bc2d20a269643f374f/termos-de-uso.md');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não foi possível abrir o link dos termos.')),
      );
    }
  }

  void _launchPrivacyPolicy() async {
    final Uri url = Uri.parse(
        'https://gist.githubusercontent.com/anthonyeduard0/05ddce8404f3af175acff888101994c2/raw/fe2abf43c91983fe78ff053c626b2f3f1c6bfb6c/politica_de_privacidade.md');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não foi possível abrir o link da política.')),
      );
    }
  }

  Future<void> _acceptTerms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // --- 1. Recuperar o Token JWT salvo ---
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Token de autenticação não encontrado. Faça login novamente.');
      }

      final cpf = widget.responseData['cpf'];
      final url = Uri.parse('${ApiConfig.baseUrl}/aceitar-termos/');

      // --- 2. Enviar a requisição com o Header Authorization ---
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token', // Autenticação corrigida aqui
        },
        body: jsonEncode({'cpf': cpf}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Atualiza o dado localmente antes de navegar
        final updatedData = Map<String, dynamic>.from(widget.responseData);
        updatedData['termos_aceitos'] = true;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(responseData: updatedData),
          ),
        );
      } else {
        // Tenta ler a mensagem de erro do backend, se houver
        String msgErro = 'Erro ao aceitar os termos.';
        try {
          final erroJson = jsonDecode(response.body);
          if (erroJson['error'] != null) {
            msgErro = erroJson['error'];
          }
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$msgErro (Cód: ${response.statusCode})'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E3A8A);

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.policy_outlined,
                          size: 80, color: primaryColor),
                      const SizedBox(height: 24),
                      const Text(
                        'Termos e Privacidade',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Para continuar, você precisa ler e aceitar nossos Termos de Uso e Políticas de Privacidade.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Checkbox(
                            value: _termsAccepted,
                            onChanged: (bool? value) {
                              setState(() {
                                _termsAccepted = value ?? false;
                              });
                            },
                            activeColor: primaryColor,
                            checkColor: Colors.white,
                            side: const BorderSide(color: Colors.black54, width: 2),
                          ),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                    color: Colors.black54, fontSize: 14),
                                children: [
                                  const TextSpan(text: 'Eu li e aceito os '),
                                  TextSpan(
                                    text: 'Termos de Uso',
                                    style: const TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = _launchTermsOfUse,
                                  ),
                                  const TextSpan(text: ' e a '),
                                  TextSpan(
                                    text: 'Política de Privacidade',
                                    style: const TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = _launchPrivacyPolicy,
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _termsAccepted ? _acceptTerms : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  disabledForegroundColor: Colors.grey.shade600,
                                ),
                                child: const Text('CONTINUAR',
                                    style: TextStyle(fontSize: 16)),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
