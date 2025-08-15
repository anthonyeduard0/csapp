// Arquivo: lib/screens/profile_screen.dart
// VERSÃO CORRIGIDA: Removidos avisos de código e otimizações aplicadas.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:educsa/screens/main_screen.dart'; 
import 'package:educsa/screens/login_screen.dart';
import 'package:educsa/screens/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> responseData;
  const ProfileScreen({super.key, required this.responseData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late DashboardData _dashboardData;
  // File? _imageFile; // Variável não utilizada removida
  bool _isUploading = false;

  // Cores do tema
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color accentColor = Color(0xFF8B5CF6);
  static const Color backgroundColor = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _dashboardData = DashboardData.fromJson(widget.responseData);
  }

  Future<void> _reloadData() async {
    final url = Uri.parse('https://csa-url-app.onrender.com/api/login/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'cpf': _dashboardData.cpfResponsavel, 'password': 'dummy_password_for_refresh'}),
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
      // Silencioso
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      _uploadImage(File(pickedFile.path));
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    setState(() { _isUploading = true; });
    final uri = Uri.parse('https://csa-url-app.onrender.com/api/responsavel/upload-foto/');
    var request = http.MultipartRequest('POST', uri)
      ..fields['cpf'] = _dashboardData.cpfResponsavel
      ..files.add(await http.MultipartFile.fromPath('foto_perfil', imageFile.path));
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _dashboardData = _dashboardData.copyWith(fotoPerfilUrl: data['foto_perfil_url']);
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto atualizada!'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ${response.body}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro de conexão: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) { setState(() { _isUploading = false; }); }
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
                      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 100.0), // Padding para a barra de navegação
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Alunos Vinculados", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                          const SizedBox(height: 16),
                          // --- CORREÇÃO: Removido .toList() desnecessário ---
                          ..._dashboardData.alunos.map((aluno) => _buildAlunoCard(aluno)),
                          const SizedBox(height: 24),
                          const Text("Opções", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                          const SizedBox(height: 16),
                          _buildOptionTile(
                            icon: Icons.settings_rounded,
                            title: 'Configurações',
                            subtitle: 'Ajustes do aplicativo',
                            onTap: () {
                               Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                            }
                          ),
                          _buildOptionTile(
                            icon: Icons.logout_rounded,
                            title: 'Sair do Aplicativo',
                            subtitle: 'Encerrar sua sessão atual',
                            color: Colors.red.shade700,
                            onTap: () {
                              Navigator.of(context).pushAndRemoveUntil(
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
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white.withAlpha(51), // Correção: withOpacity -> withAlpha
                  backgroundImage: _dashboardData.fotoPerfilUrl != null ? NetworkImage(_dashboardData.fotoPerfilUrl!) : null,
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : (_dashboardData.fotoPerfilUrl == null
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor, width: 2)
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 18, color: primaryColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(_dashboardData.nomeResponsavel, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_dashboardData.email, style: const TextStyle(color: Colors.white70, fontSize: 14)),
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
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10)], // Correção: withOpacity -> withAlpha
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

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade400, size: 20),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: valueColor ?? Colors.black87),
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
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10)], // Correção: withOpacity -> withAlpha
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
