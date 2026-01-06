import 'package:educsa/utils/responsive_layout.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:educsa/api_config.dart'; 
import 'package:educsa/screens/terms_acceptance_screen.dart';


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

  void _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final bool rememberMe = prefs.getBool('remember_me') ?? false;

    // --- LIMPEZA DE SEGURANÇA ---
    // Removemos qualquer senha antiga que tenha ficado salva por engano
    if (prefs.containsKey('user_password')) {
      await prefs.remove('user_password');
    }

    setState(() {
      _rememberMe = rememberMe;
    });

    if (rememberMe) {
      // Carregamos APENAS o CPF. O usuário deve digitar a senha novamente.
      _cpfController.text = prefs.getString('user_cpf') ?? '';
    }
  }

  void _launchTermsOfUse() async {
    final Uri url = Uri.parse('https://gist.githubusercontent.com/anthonyeduard0/0b02af52257c33aee17c52b2872b19a4/raw/0ecf2b0a2491ff082e5649bc2d20a269643f374f/termos-de-uso.md');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o link dos termos.')),);
    }
  }

  void _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://gist.githubusercontent.com/anthonyeduard0/05ddce8404f3af175acff888101994c2/raw/fe2abf43c91983fe78ff053c626b2f3f1c6bfb6c/politica_de_privacidade.md');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o link da política.')),);
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
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8',},
        body: jsonEncode(<String, String>{'cpf': cpf, 'password': password,}),
      ).timeout(const Duration(seconds: 50));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        
        // --- SEGURANÇA ATUALIZADA ---
        // 1. Salvamos o CPF se "Lembrar-me" estiver marcado
        if (_rememberMe) {
          await prefs.setBool('remember_me', true);
          await prefs.setString('user_cpf', cpf);
        } else {
          await prefs.setBool('remember_me', false);
          await prefs.remove('user_cpf');
        }
        
        // 2. NUNCA salvamos a senha.
        await prefs.remove('user_password'); 

        // 3. Salvamos o TOKEN JWT recebido do backend
        if (responseData['token'] != null) {
          await prefs.setString('auth_token', responseData['token']);
        }
        
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
    
    final mobileBody = _buildLoginForm(isDesktop: false);
    
    final desktopBody = Center(
      child: Container(
        width: 400,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: _buildLoginForm(isDesktop: true),
        ),
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        // CORREÇÃO 1: Força o container a ocupar 100% da tela sempre
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D449B), Color(0xFF25B6E8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ResponsiveLayout(
          mobileBody: mobileBody,
          desktopBody: desktopBody,
        ),
      ),
    );
  }

  Widget _buildLoginForm({required bool isDesktop}) {
    // Define colors based on the platform
    final Color primaryTextColor = isDesktop ? Colors.black87 : Colors.white;
    final Color secondaryTextColor = isDesktop ? Colors.black54 : Colors.white70;
    final Color fieldIconColor = isDesktop ? Colors.grey[600]! : Colors.white70;
    final Color buttonBackgroundColor = isDesktop ? const Color(0xFF1E3A8A) : Colors.white;
    final Color buttonForegroundColor = isDesktop ? Colors.white : const Color(0xFF1E3A8A);

    // CORREÇÃO 2: LayoutBuilder para calcular a altura disponível
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            // Define uma altura mínima igual à altura da tela menos o padding
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight > 64 ? constraints.maxHeight - 64 : constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Image(image: AssetImage('assets/images/Logocsa.png'), height: 120),
                  const SizedBox(height: 20),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Seja bem-vindo(a)!',
                      style: TextStyle(color: primaryTextColor, fontSize: 30, fontWeight: FontWeight.bold,),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Entrar na conta', style: TextStyle(color: secondaryTextColor, fontSize: 17,),),
                  const SizedBox(height: 40),
                  _buildTextField(
                    controller: _cpfController,
                    formatter: _cpfFormatter,
                    hintText: 'CPF',
                    icon: Icons.person_outline,
                    keyboardType: TextInputType.number,
                    isDesktop: isDesktop
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
                        color: fieldIconColor,
                      ),
                      onPressed: () { setState(() { _isPasswordVisible = !_isPasswordVisible; }); },
                    ),
                    isDesktop: isDesktop
                  ),
                  const SizedBox(height: 10),
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
                            activeColor: isDesktop ? const Color(0xFF1D449B) : Colors.white,
                            checkColor: isDesktop ? Colors.white : const Color(0xFF1D449B),
                            side: BorderSide(color: secondaryTextColor, width: 2),
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
                          child: Text(
                            'Lembrar-me (Apenas CPF)',
                            style: TextStyle(color: secondaryTextColor, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? CircularProgressIndicator(color: isDesktop ? const Color(0xFF1E3A8A) : Colors.white)
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonBackgroundColor,
                              foregroundColor: buttonForegroundColor,
                              disabledBackgroundColor: buttonBackgroundColor.withAlpha(128),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30),),
                            ),
                            child: const Text('ENTRAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,),),
                          ),
                        ),
                  const SizedBox(height: 40),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(color: secondaryTextColor, fontSize: 13),
                      children: [
                        const TextSpan(text: 'Ao entrar, você concorda com nossos ',),
                        TextSpan(
                          text: 'Termos de Uso',
                          style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline,),
                          recognizer: TapGestureRecognizer()..onTap = _launchTermsOfUse,
                        ),
                        const TextSpan(text: ' e '),
                        TextSpan(
                          text: 'Política de Privacidade.',
                          style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline,),
                          recognizer: TapGestureRecognizer()..onTap = _launchPrivacyPolicy,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
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
    required bool isDesktop
  }) {
    final Color textColor = isDesktop ? Colors.black87 : Colors.white;
    final Color hintColor = isDesktop ? Colors.black54 : Colors.white70;
    final Color iconColor = isDesktop ? Colors.grey[600]! : Colors.white70;
    final Color fillColor = isDesktop ? Colors.grey[200]! : const Color(0x33FFFFFF);

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: formatter != null ? [formatter] : [],
      style: TextStyle(color: textColor, fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: hintColor),
        prefixIcon: Icon(icon, color: iconColor),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}