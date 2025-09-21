// Arquivo: lib/screens/login_screen.dart
// VERSÃO CORRIGIDA: Links de Termos de Uso e Política de Privacidade separados.

import 'package:educsa/screens/terms_acceptance_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _cpfController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  // --- FUNÇÃO PARA ABRIR OS TERMOS DE USO ---
  void _launchTermsOfUse() async {
    // !!! IMPORTANTE: Substitua a URL abaixo pela URL do seu Gist de Termos de Uso !!!
    final Uri url = Uri.parse('https://gist.githubusercontent.com/anthonyeduard0/0b02af52257c33aee17c52b2872b19a4/raw/0ecf2b0a2491ff082e5649bc2d20a269643f374f/termos-de-uso.md');
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o link dos termos.')),
      );
    }
  }

  // --- FUNÇÃO PARA ABRIR A POLÍTICA DE PRIVACIDADE ---
  void _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://gist.githubusercontent.com/anthonyeduard0/05ddce8404f3af175acff888101994c2/raw/fe2abf43c91983fe78ff053c626b2f3f1c6bfb6c/politica_de_privacidade.md');
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o link da política.')),
      );
    }
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
    });

    final cpf = _cpfController.text;
    final password = _passwordController.text;

    final url = Uri.parse('https://csa-url-app.onrender.com/api/login/');

    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'cpf': cpf,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 50));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TermsAcceptanceWrapper(responseData: responseData),
          ),
        );
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text('Erro de login: ${errorData['error']}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
                'Não foi possível conectar ao servidor. Verifique sua conexão.')),
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/images/logocsateste.png', // Logo atualizado
                  height: 120,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Seja bem-vindo(a)!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Entrar na conta',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),
                _buildTextField(
                  controller: _cpfController,
                  formatter: _cpfFormatter,
                  hintText: 'CPF',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _passwordController,
                  hintText: 'Senha',
                  icon: Icons.lock_outline,
                  obscureText: !_isPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 40),
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1E3A8A),
                            disabledBackgroundColor: Colors.white.withAlpha(128),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'ENTRAR',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 40),
                // --- WIDGET RICHTEXT CORRIGIDO ---
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    children: [
                      const TextSpan(
                        text: 'Ao entrar, você concorda com nossos ',
                      ),
                      TextSpan(
                        text: 'Termos de Uso', // Parte 1 clicável
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = _launchTermsOfUse, // Chama a função dos Termos
                      ),
                      const TextSpan(text: ' e '),
                      TextSpan(
                        text: 'Política de Privacidade.', // Parte 2 clicável
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = _launchPrivacyPolicy, // Chama a função da Privacidade
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    MaskTextInputFormatter? formatter,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: formatter != null ? [formatter] : [],
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0x33FFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
