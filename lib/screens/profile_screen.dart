// Arquivo: lib/screens/profile_screen.dart (VERSÃO CORRIGIDA)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// +++ CORREÇÃO: Importa os arquivos necessários +++
import 'package:csapp/screens/dashboard_screen.dart'; 
import 'package:csapp/screens/login_screen.dart';

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
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      // O upload é chamado aqui após a seleção da imagem
      _uploadImage(File(pickedFile.path));
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    setState(() {
      _isUploading = true;
    });

    final uri = Uri.parse('https://csa-url-app.onrender.com/api/responsavel/upload-foto/');
    var request = http.MultipartRequest('POST', uri)
      ..fields['cpf'] = _dashboardData.cpfResponsavel
      ..files.add(await http.MultipartFile.fromPath(
        'foto_perfil',
        imageFile.path,
      ));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // +++ CORREÇÃO: Adiciona a verificação 'mounted' antes de usar o context +++
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _dashboardData = _dashboardData.copyWith(fotoPerfilUrl: data['foto_perfil_url']);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto atualizada com sucesso!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar foto: ${response.body}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      // +++ CORREÇÃO: Adiciona a verificação 'mounted' antes de usar o context +++
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E3A8A);
    final aluno = _dashboardData.alunos.isNotEmpty ? _dashboardData.alunos.first : null;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          // Cabeçalho do perfil
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
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
                            ? const CircularProgressIndicator()
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
                Text(
                  _dashboardData.nomeResponsavel,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _dashboardData.email,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                 if (_dashboardData.telefone != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _dashboardData.telefone!,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ]
              ],
            ),
          ),
          // Corpo com informações
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (aluno != null)
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            aluno.nomeCompleto,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(aluno.serieAno, style: const TextStyle(color: Colors.grey)),
                          const Divider(height: 30),
                          _buildInfoRow('Status da Matrícula', aluno.statusMatricula, Colors.green),
                          const SizedBox(height: 12),
                          _buildInfoRow('Validade', aluno.validadeMatriculaFormatada ?? 'N/A', Colors.black),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: const Text('Sair do aplicativo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                     Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (Route<dynamic> route) => false,
                      );
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: valueColor),
        ),
      ],
    );
  }
}

// +++ CORREÇÃO: A extensão 'copyWith' foi REMOVIDA deste arquivo +++
// Ela agora existe apenas no arquivo dashboard_screen.dart para evitar ambiguidade.
