// Arquivo: lib/screens/profile_screen.dart
// VERSÃO LIMPA E CORRIGIDA: Removida toda a lógica de upload e exibição da foto de perfil.
// MODIFICADO: Uso de ApiConfig.baseUrl.
// CORRIGIDO: Aviso 'use_build_context_synchronously' resolvido.
// NOVO: Adicionado telefone e rótulos de identificação (Email: / Telefone:).
// CORRIGIDO: Adicionado SnackBar para erro no _reloadData.
// CORRIGIDO (RESPONSIVIDADE): Corrigido o layout de _buildInfoRow e _buildHeader para fontes grandes.

import 'package:flutter/material.dart';
import 'package:educsa/screens/main_screen.dart'; 
import 'package:educsa/screens/login_screen.dart';
import 'package:educsa/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:educsa/api_config.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> responseData;
  const ProfileScreen({super.key, required this.responseData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late DashboardData _dashboardData;

  static const Color primaryColor = Color(0xFF1D449B);
  static const Color accentColor = Color(0xFF25B6E8);
  static const Color backgroundColor = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _dashboardData = DashboardData.fromJson(widget.responseData);
  }
  
  // Função para recarregar os dados do servidor
  Future<void> _reloadData() async {
    final prefs = await SharedPreferences.getInstance();
    final cpf = prefs.getString('user_cpf');
    final password = prefs.getString('user_password');
    if (cpf == null || password == null) return;
    
    final url = Uri.parse('${ApiConfig.baseUrl}/login/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'cpf': cpf, 'password': password}),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            _dashboardData = DashboardData.fromJson(responseData);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao recarregar o perfil. Verifique sua conexão.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ primaryColor, accentColor ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: RefreshIndicator(
                    onRefresh: _reloadData,
                    color: primaryColor,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 100.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Alunos Vinculados", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                          const SizedBox(height: 16),
                          ..._dashboardData.alunos.map((aluno) => _buildAlunoCard(aluno)),
                          const SizedBox(height: 24),
                          const Text("Opções", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                          const SizedBox(height: 16),
                          _buildOptionTile(
                            icon: Icons.settings_rounded,
                            title: 'Configurações',
                            subtitle: 'Ajustes do aplicativo',
                            onTap: () {
                               if(mounted) {
                                 Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                               }
                            }
                          ),
                          _buildOptionTile(
                            icon: Icons.logout_rounded,
                            title: 'Sair do Aplicativo',
                            subtitle: 'Encerrar sua sessão atual',
                            color: Colors.red.shade700,
                            onTap: () async {
                              final navigator = Navigator.of(context);
                              
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.remove('user_cpf');
                              await prefs.remove('user_password');
                              
                              if (!mounted) return; 

                              navigator.pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                                (Route<dynamic> route) => false,
                              );
                            }
                          ),
                          const SizedBox(height: 24),
                          const Center(child: Text('Versão do Aplicativo 1.0.1', style: TextStyle(color: Colors.grey, fontSize: 12))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white.withAlpha(51),
            child: const Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(_dashboardData.nomeResponsavel, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
          // --- CORREÇÃO (RESPONSIVIDADE): Row -> Wrap ---
          Wrap( // Usar Wrap permite quebrar a linha se o email for muito grande
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Email: ', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
              Text(_dashboardData.email, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          
          if (_dashboardData.telefone != null && _dashboardData.telefone!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              // --- CORREÇÃO (RESPONSIVIDADE): Row -> Wrap ---
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Telefone: ', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(_dashboardData.telefone!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlunoCard(Aluno aluno) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(aluno.nomeCompleto, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
          const Divider(height: 24),
          _buildInfoRow(Icons.school_rounded, 'Série/Ano', aluno.serieAno),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.check_circle_rounded, 'Status da Matrícula', aluno.statusMatricula, valueColor: Colors.green.shade700),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.event_available_rounded, 'Validade', aluno.validadeMatriculaFormatada ?? 'N/A'),
        ],
      ),
    );
  }

  // --- CORREÇÃO (RESPONSIVIDADE): Layout da Row ajustado ---
  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Alinha pelo topo se o texto quebrar
      children: [
        Icon(icon, color: Colors.grey.shade400, size: 20),
        const SizedBox(width: 12),
        Expanded( // O label pode crescer e quebrar a linha
          child: Text(
            label, 
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
        ),
        const SizedBox(width: 16), // Espaçamento fixo
        Flexible( // Permite que o valor ocupe o espaço restante e quebre linha
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: valueColor ?? Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile({required IconData icon, required String title, required String subtitle, VoidCallback? onTap, Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: color ?? primaryColor, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
                      Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}