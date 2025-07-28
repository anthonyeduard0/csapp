import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'historico_mensalidades_screen.dart';

// --- Modelos de Dados (sem alteração, mas incluídos para o arquivo ser completo) ---
class DashboardData {
  final String nomeResponsavel;
  final String cpfResponsavel;
  final List<Aluno> alunos;
  DashboardData(
      {required this.nomeResponsavel,
      required this.alunos,
      required this.cpfResponsavel});
  factory DashboardData.fromJson(Map<String, dynamic> json) {
    var alunosList = json['alunos'] as List;
    List<Aluno> alunos = alunosList.map((i) => Aluno.fromJson(i)).toList();
    return DashboardData(
      nomeResponsavel: json['nome_completo'],
      cpfResponsavel: json['cpf'],
      alunos: alunos,
    );
  }
}

class Aluno {
  final String nomeCompleto;
  final String serieAno;
  final List<Mensalidade> mensalidadesPendentes;
  Aluno(
      {required this.nomeCompleto,
      required this.serieAno,
      required this.mensalidadesPendentes});
  factory Aluno.fromJson(Map<String, dynamic> json) {
    var mensalidadesList = json['mensalidades_pendentes'] as List;
    List<Mensalidade> mensalidades =
        mensalidadesList.map((i) => Mensalidade.fromJson(i)).toList();
    return Aluno(
      nomeCompleto: json['nome_completo'],
      serieAno: json['serie_ano'],
      mensalidadesPendentes: mensalidades,
    );
  }
}

class Mensalidade {
  final String id;
  final DateTime dataVencimento;
  final double valorNominal;
  final String status;
  Mensalidade(
      {required this.id,
      required this.dataVencimento,
      required this.valorNominal,
      required this.status});
  factory Mensalidade.fromJson(Map<String, dynamic> json) {
    return Mensalidade(
      id: json['id'],
      dataVencimento: DateTime.parse(json['data_vencimento']),
      valorNominal: double.parse(json['valor_nominal']),
      status: json['status'],
    );
  }
}
// --- Fim dos Modelos de Dados ---

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> responseData;
  const DashboardScreen({super.key, required this.responseData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isPixLoading = false;
  Map<String, dynamic>? _pixData;
  String? _pixError;
  String? _selectedMensalidadeId;

  final String _backendUrl = 'http://csa-url-app.onrender.com:8000/api';

  Future<void> _gerarPagamentoPix(String mensalidadeId) async {
    setState(() {
      _isPixLoading = true;
      _pixData = null;
      _pixError = null;
      _selectedMensalidadeId = mensalidadeId;
    });

    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/pagamento/criar-pix/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mensalidade_id': mensalidadeId}),
      );

      if (response.statusCode == 201) {
        setState(() {
          _pixData = jsonDecode(utf8.decode(response.bodyBytes));
        });
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(errorBody.toString()); // Mostra o erro completo do MP
      }
    } catch (e) {
      setState(() {
        _pixError = e.toString();
      });
    } finally {
      setState(() {
        _isPixLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardData = DashboardData.fromJson(widget.responseData);
    const Color primaryColor = Color(0xFF1E3A8A);
    const Color accentColor = Color(0xFF8B5CF6);
    const Color lightBackgroundColor = Color(0xFFF3F4F6);
    const Color valorColor = Color(0xFF4A5568); // Cor cinza-azulado para o valor

    Mensalidade? proximaMensalidade;
    if (dashboardData.alunos.isNotEmpty &&
        dashboardData.alunos.first.mensalidadesPendentes.isNotEmpty) {
      proximaMensalidade = dashboardData.alunos.first.mensalidadesPendentes.first;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180.0, // Aumenta a altura para a logo
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, size: 28),
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Olá, ${dashboardData.nomeResponsavel.split(' ')[0]}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // --- AJUSTE DE DESIGN: Logo no topo ---
                    Positioned(
                      top: 40,
                      left: 16,
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        height: 40,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: lightBackgroundColor,
              child: Column(
                children: [
                  _buildFaturaCard(context, proximaMensalidade, primaryColor, dashboardData.cpfResponsavel, valorColor),
                  if (_selectedMensalidadeId != null)
                    _buildPixDisplaySection(),
                  
                  const SizedBox(height: 24),
                  _buildAcoesGrid(context, dashboardData.cpfResponsavel),
                  const SizedBox(height: 24),
                  ...dashboardData.alunos.map((aluno) => _buildAlunoCard(context, aluno)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaturaCard(BuildContext context, Mensalidade? mensalidade, Color primaryColor, String cpf, Color valorColor) {
    if (mensalidade == null) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'Tudo em dia! Nenhuma mensalidade pendente.',
            style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shadowColor: Colors.grey.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Próxima fatura', style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 4),
            // --- AJUSTE DE DESIGN: Nova cor para o valor ---
            Text(
              NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(mensalidade.valorNominal),
              style: TextStyle(color: valorColor, fontSize: 36, fontWeight: FontWeight.bold),
            ),
            Text('Vence em ${DateFormat('dd/MM/yyyy').format(mensalidade.dataVencimento)}'),
            const Divider(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => HistoricoMensalidadesScreen(cpfResponsavel: cpf)));
                    },
                    child: const Text('Ver Faturas'),
                    style: OutlinedButton.styleFrom(foregroundColor: primaryColor, side: BorderSide(color: primaryColor)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _gerarPagamentoPix(mensalidade.id),
                    icon: const Icon(Icons.pix, size: 18),
                    label: const Text('Pagar com Pix'),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPixDisplaySection() {
    // ... (Esta função não muda)
    if (_isPixLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: CircularProgressIndicator(),
      );
    }
    if (_pixError != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Erro ao gerar Pix: $_pixError', style: const TextStyle(color: Colors.red)),
      );
    }
    if (_pixData != null) {
      final qrCodeBase64 = _pixData!['qr_code_base64'];
      final qrCodeText = _pixData!['qr_code'];
      return Card(
        margin: const EdgeInsets.only(top: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text("Pague com Pix", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Image.memory(base64Decode(qrCodeBase64), width: 200, height: 200),
              const SizedBox(height: 16),
              const Text("Ou copie o código abaixo:", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                child: Text(qrCodeText, style: const TextStyle(fontSize: 11)),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: qrCodeText));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código Pix copiado!')));
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copiar código'),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildAcoesGrid(BuildContext context, String cpf) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildGridItem(context, icon: Icons.receipt_long, label: 'Histórico', onTap: () {
           Navigator.push(context, MaterialPageRoute(builder: (context) => HistoricoMensalidadesScreen(cpfResponsavel: cpf)));
        }),
        _buildGridItem(context, icon: Icons.support_agent, label: 'Suporte', onTap: () {}),
        _buildGridItem(context, icon: Icons.info_outline, label: 'Avisos', onTap: () {}),
      ],
    );
  }

  Widget _buildGridItem(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    // ... (Esta função não muda)
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: const Color(0xFF1E3A8A)),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildAlunoCard(BuildContext context, Aluno aluno) {
    // ... (Esta função não muda)
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.2),
          child: const Icon(Icons.person, color: Color(0xFF8B5CF6)),
        ),
        title: Text(aluno.nomeCompleto, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(aluno.serieAno),
      ),
    );
  }
}
