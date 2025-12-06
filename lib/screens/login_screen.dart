// Arquivo: lib/screens/login_screen.dart
// ATUALIZADO: Salva CPF e senha para recarregamento automático de dados.
// ATUALIZADO: Gradiente de cores alterado conforme solicitado.
// MODIFICADO: Uso de ApiConfig.baseUrl.
// CORRIGIDO: Aviso 'use_build_context_synchronously' resolvido com verificação 'if (mounted)'.
// ATUALIZADO: Fontes levemente aumentadas.
// ATUALIZADO: Adicionados 'const' para resolver avisos de lint.
//
// +++ ÚLTIMA ALTERAÇÃO (FUNCIONALIDADE E ALINHAMENTO) +++
// 1. Corrigido bug no _loadSavedCredentials que impedia o autopreenchimento.
// 2. Adicionado Padding ao Row do "Lembrar-me" para alinhamento com os TextFields.

import 'package:educsa/screens/terms_acceptance_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:educsa/api_config.dart'; // Importação adicionada

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
  bool _rememberMe = false; 

  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  // --- CORREÇÃO (BUG DO AUTOPREENCHIMENTO) ---
  // Usamos a variável local `rememberMe` para o `if`, pois o `_rememberMe` (do setState)
  // pode não ter sido atualizado ainda no mesmo frame.
  void _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final bool rememberMe = prefs.getBool('remember_me') ?? false;

    setState(() {
      _rememberMe = rememberMe;
    });

    if (rememberMe) { // Usar a variável local `rememberMe` aqui
      _cpfController.text = prefs.getString('user_cpf') ?? '';
      _passwordController.text = prefs.getString('user_password') ?? '';
    }
  }
  // --- FIM DA CORREÇÃO ---


  void _launchTermsOfUse() async {
    final Uri url = Uri.parse('https://gist.githubusercontent.com/anthonyeduard0/0b02af52257c33aee17c52b2872b19a4/raw/0ecf2b0a2491ff082e5649bc2d20a269643f374f/termos-de-uso.md');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Não foi possível abrir o link dos termos.')), );
    }
  }

  void _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://gist.githubusercontent.com/anthonyeduard0/05ddce8404f3af175acff888101994c2/raw/fe2abf43c91983fe78ff053c626b2f3f1c6bfb6c/politica_de_privacidade.md');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Não foi possível abrir o link da política.')), );
    }
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() { _isLoading = true; });

    final cpf = _cpfController.text;
    final password = _passwordController.text;

    final url = Uri.parse('${ApiConfig.baseUrl}/login/');

    try {
      final response = await http.post(
        url,
        headers: <String, String>{ 'Content-Type': 'application/json; charset=UTF-8', },
        body: jsonEncode(<String, String>{ 'cpf': cpf, 'password': password, }),
      ).timeout(const Duration(seconds: 50));

      if (!mounted) return; // Primeira verificação de segurança

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        
        if (_rememberMe) {
          await prefs.setBool('remember_me', true);
          await prefs.setString('user_cpf', cpf);
          await prefs.setString('user_password', password);
        } else {
          await prefs.setBool('remember_me', false);
          await prefs.remove('user_cpf');
          await prefs.remove('user_password');
        }
        
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        
        if (mounted) { 
          Navigator.pushReplacement(
            context,
            MaterialPageRoute( builder: (context) => TermsAcceptanceWrapper(responseData: responseData), ),
          );
        }
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar( SnackBar( backgroundColor: Colors.redAccent, content: Text('Erro de login: ${errorData['error']}')), );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar( const SnackBar( backgroundColor: Colors.redAccent, content: Text( 'Não foi possível conectar ao servidor. Verifique sua conexão.')), );
      }
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D449B), Color(0xFF25B6E8)],
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
                const Image(image: AssetImage('assets/images/Logocsa.png'), height: 120),
                const SizedBox(height: 20),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text( 
                    'Seja bem-vindo(a)!', 
                    style: TextStyle( color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, ), 
                  ),
                ),
                const SizedBox(height: 10),
                const Text( 'Entrar na conta', style: TextStyle( color: Colors.white70, fontSize: 17, ), ), 
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
                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                    ),
                    onPressed: () { setState(() { _isPasswordVisible = !_isPasswordVisible; }); },
                  ),
                ),
                const SizedBox(height: 10),
                
                // --- CORREÇÃO (ALINHAMENTO) ---
                // Adicionado Padding para alinhar o Checkbox com o texto dos campos acima
                Padding(
                  padding: const EdgeInsets.only(left: 12.0), 
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (bool? value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          activeColor: Colors.white,
                          checkColor: const Color(0xFF1D449B),
                          side: const BorderSide(color: Colors.white70, width: 2),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _rememberMe = !_rememberMe;
                          });
                        },
                        child: const Text(
                          'Lembrar-me',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                // --- FIM DA CORREÇÃO ---
                
                const SizedBox(height: 20),
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
                            shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(30), ),
                          ),
                          child: const Text( 'ENTRAR', style: TextStyle( fontSize: 18, fontWeight: FontWeight.bold, ), ),
                        ),
                      ),
                const SizedBox(height: 40),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white70, fontSize: 13), 
                    children: [
                      const TextSpan( text: 'Ao entrar, você concorda com nossos ', ),
                      TextSpan(
                        text: 'Termos de Uso',
                        style: const TextStyle( fontWeight: FontWeight.bold, decoration: TextDecoration.underline, ),
                        recognizer: TapGestureRecognizer()..onTap = _launchTermsOfUse,
                      ),
                      const TextSpan(text: ' e '),
                      TextSpan(
                        text: 'Política de Privacidade.',
                        style: const TextStyle( fontWeight: FontWeight.bold, decoration: TextDecoration.underline, ),
                        recognizer: TapGestureRecognizer()..onTap = _launchPrivacyPolicy,
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
      style: const TextStyle(color: Colors.white, fontSize: 16), 
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