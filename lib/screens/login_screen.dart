// Arquivo: lib/screens/login_screen.dart

import 'package:csapp/screens/main_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:csapp/screens/legal_screen.dart';

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
  bool _termsAccepted = false;

  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

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
          'senha': password,
        }),
      ).timeout(const Duration(seconds: 50));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(responseData: responseData),
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

  void _showLegalScreen(String type) {
    String title = "";
    String content = "";

    if (type == "terms") {
      title = "Termos de Uso";
      content = "Aqui vai o texto completo dos seus Termos de Uso... \n\nLorem ipsum dolor sit amet, consectetur adipiscing elit. ...";
    } else {
      title = "Política de Privacidade";
      content = "Aqui vai o texto completo da sua Política de Privacidade... \n\nLorem ipsum dolor sit amet, consectetur adipiscing elit. ...";
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LegalScreen(title: title, content: content),
      ),
    );
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
                  'assets/images/logo.jpg',
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
                const SizedBox(height: 20),
                Row(
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      onChanged: (bool? value) {
                        setState(() {
                          _termsAccepted = value ?? false;
                        });
                      },
                      checkColor: const Color(0xFF1E3A8A),
                      activeColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          children: [
                            const TextSpan(text: 'Eu li e aceito os '),
                            TextSpan(
                              text: 'Termos de Uso',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _showLegalScreen("terms"),
                            ),
                            const TextSpan(text: ' e as '),
                            TextSpan(
                              text: 'Políticas de Privacidade',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _showLegalScreen("privacy"),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _termsAccepted ? _login : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1E3A8A),
                            // CORREÇÃO: Trocado withOpacity por withAlpha
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
        // CORREÇÃO: Trocado withOpacity por withAlpha
        fillColor: Colors.white.withAlpha(51),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
