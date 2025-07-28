// Arquivo: lib/screens/invoice_history_screen.dart
// CÓDIGO COM AJUSTES VISUAIS FINAIS

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

// --- FUNÇÃO AUXILIAR PARA CAPITALIZAR A PRIMEIRA LETRA ---
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

// Modelo para os dados que virão da API
class AlunoComMensalidades {
  final String nomeCompleto;
  final List<Mensalidade> mensalidades;

  AlunoComMensalidades({required this.nomeCompleto, required this.mensalidades});

  factory AlunoComMensalidades.fromJson(Map<String, dynamic> json) {
    var mensalidadesList = json['mensalidades'] as List;
    List<Mensalidade> mensalidades =
        mensalidadesList.map((i) => Mensalidade.fromJson(i)).toList();
    mensalidades.sort((a, b) => b.dataVencimento.compareTo(a.dataVencimento));
    return AlunoComMensalidades(
      nomeCompleto: json['nome_completo'],
      mensalidades: mensalidades,
    );
  }
}

class Mensalidade {
  final DateTime mesReferencia;
  final DateTime dataVencimento;
  final double valorNominal;
  final double valorFinal; // NOVO CAMPO ADICIONADO
  final String status;

  Mensalidade({
    required this.mesReferencia,
    required this.dataVencimento,
    required this.valorNominal,
    required this.valorFinal, // NOVO CAMPO ADICIONADO
    required this.status,
  });

  factory Mensalidade.fromJson(Map<String, dynamic> json) {
    return Mensalidade(
      mesReferencia: DateTime.parse(json['mes_referencia']),
      dataVencimento: DateTime.parse(json['data_vencimento']),
      valorNominal: double.parse(json['valor_nominal']),
      valorFinal: double.parse(json['valor_final']), // LÊ O NOVO CAMPO DA API
      status: json['status'],
    );
  }
}

class InvoiceHistoryScreen extends StatefulWidget {
  final String responsavelCpf;

  const InvoiceHistoryScreen({super.key, required this.responsavelCpf});

  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  Future<List<AlunoComMensalidades>>? _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchInvoiceHistory();
  }

  Future<List<AlunoComMensalidades>> _fetchInvoiceHistory() async {
    final url = Uri.parse(
        'https://csa-url-app.onrender.com/api/mensalidades/?cpf=${widget.responsavelCpf}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((dynamic item) => AlunoComMensalidades.fromJson(item)).toList();
      } else {
        throw Exception('Falha ao carregar o histórico de faturas.');
      }
    } catch (e) {
      throw Exception('Erro de conexão: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E3A8A);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Faturas'),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              // --- CONTAINER PARA O FUNDO DAS ABAS ---
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: TabBar(
                  // --- CORES PARA O TEXTO DAS ABAS ---
                  labelColor: primaryColor,
                  unselectedLabelColor: Colors.white,
                  indicatorSize: TabBarIndicatorSize.tab,
                  // --- INDICADOR EM PÍLULA ---
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(fontSize: 16),
                  tabs: const [
                    Tab(text: 'Em aberto'),
                    Tab(text: 'Já pagas'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: FutureBuilder<List<AlunoComMensalidades>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Nenhuma fatura encontrada.'));
            }

            final todosAlunos = snapshot.data!;
            
            final mensalidadesEmAberto = todosAlunos
                .expand((aluno) => aluno.mensalidades)
                .where((m) => m.status != 'PAGA')
                .toList();
            
            final mensalidadesPagas = todosAlunos
                .expand((aluno) => aluno.mensalidades)
                .where((m) => m.status == 'PAGA')
                .toList();

            return TabBarView(
              children: [
                _buildInvoiceList(mensalidadesEmAberto),
                _buildInvoiceList(mensalidadesPagas),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInvoiceList(List<Mensalidade> mensalidades) {
    if (mensalidades.isEmpty) {
      return const Center(child: Text('Nenhuma fatura nesta categoria.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: mensalidades.length,
      itemBuilder: (context, index) {
        return _buildInvoiceCard(mensalidades[index]);
      },
    );
  }

  Widget _buildInvoiceCard(Mensalidade mensalidade) {
    final formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    // --- CORREÇÃO NO FORMATO DA DATA ---
    final formatadorMesAno = DateFormat('MMMM \'de\' yyyy', 'pt_BR');
    final formatadorVencimento = DateFormat('dd/MM/yyyy');
    final isPaid = mensalidade.status == 'PAGA';

    // Pega o texto formatado e aplica a capitalização
    final mesFormatado = capitalize(formatadorMesAno.format(mensalidade.mesReferencia));

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fatura de $mesFormatado',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  // --- ALTERAÇÃO: USA valorFinal SE ESTIVER EM ABERTO, senão valorNominal ---
                  formatadorMoeda.format(isPaid ? mensalidade.valorNominal : mensalidade.valorFinal),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPaid ? 'Pago' : 'Em aberto',
                    style: TextStyle(
                      color: isPaid ? Colors.green.shade800 : Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Vence em ${formatadorVencimento.format(mensalidade.dataVencimento)}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
