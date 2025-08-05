// Arquivo: lib/screens/profile_screen.dart
// VERSÃO FINAL COM CORREÇÃO DE ERROS E AVISOS

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:educsa/screens/main_screen.dart'; 
import 'package:educsa/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> responseData;
  const ProfileScreen({super.key, required this.responseData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late DashboardData _dashboardData;
  File? _imageFile;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _dashboardData = DashboardData.fromJson(widget.responseData);
    // A inicialização de data foi removida daqui, pois já ocorre no main.dart
  }

  Future<void> _reloadData() async {
    final url = Uri.parse('https://csa-url-app.onrender.com/api/login/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        // A senha é enviada vazia pois o backend não a exige para recarregar os dados
        body: jsonEncode({'cpf': _dashboardData.cpfResponsavel, 'senha': ''}),
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
      // O 'print' foi removido para seguir as boas práticas
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
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
    const Color primaryColor = Color(0xFF1E3A8A);
    final aluno = _dashboardData.alunos.isNotEmpty ? _dashboardData.alunos.first : null;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: RefreshIndicator(
        onRefresh: _reloadData,
        child: ListView(
          children: [
            // --- CABEÇALHO COM INFORMAÇÕES DO RESPONSÁVEL ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (_dashboardData.fotoPerfilUrl != null && _dashboardData.fotoPerfilUrl!.isNotEmpty
                                  ? NetworkImage(_dashboardData.fotoPerfilUrl!)
                                  : null) as ImageProvider?,
                          child: _isUploading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : (_dashboardData.fotoPerfilUrl == null || _dashboardData.fotoPerfilUrl!.isEmpty && _imageFile == null
                                  ? const Icon(Icons.person, size: 50, color: primaryColor)
                                  : null),
                        ),
                        const CircleAvatar(
                          radius: 15,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.camera_alt, size: 18, color: primaryColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_dashboardData.nomeResponsavel, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.email_outlined, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      const Text("Email:", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(_dashboardData.email, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                  if (_dashboardData.telefone != null && _dashboardData.telefone!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone_outlined, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        const Text("Celular:", style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(_dashboardData.telefone!, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ]
                ],
              ),
            ),
            
            // --- CARD COM INFORMAÇÕES DO ALUNO ---
            if (aluno != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  // CORREÇÃO: Trocado withOpacity por withAlpha
                  shadowColor: Colors.grey.withAlpha(77), // 0.3 * 255 = 76.5 -> 77
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aluno.nomeCompleto,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                        ),
                        const SizedBox(height: 8),
                        _buildAlunoInfoRow(
                          icon: Icons.school_outlined,
                          label: 'Série/Ano:',
                          value: aluno.serieAno,
                        ),
                        const Divider(height: 24),
                        _buildAlunoInfoRow(
                          icon: Icons.check_circle_outline,
                          label: 'Status da Matrícula:',
                          value: aluno.statusMatricula,
                          valueColor: Colors.green.shade700,
                        ),
                        const SizedBox(height: 12),
                        _buildAlunoInfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Validade:',
                          value: aluno.validadeMatriculaFormatada ?? 'N/A',
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // --- BOTÃO DE SAIR E VERSÃO ---
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
              child: Column(
                children: [
                  Text('Versão do Aplicativo 1.0.1', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: const Text('Sair do APP', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlunoInfoRow({required IconData icon, required String label, required String value, Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: valueColor ?? const Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}
