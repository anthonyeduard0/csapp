// Arquivo: lib/screens/invoice_history_screen.dart
// CÓDIGO COMPLETO E CORRIGIDO

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

// Modelo para os dados que virão da API
class AlunoComMensalidades {
  final String nomeCompleto;
  final List<Mensalidade> mensalidades;

  AlunoComMensalidades({required this.nomeCompleto, required this.mensalidades});

  factory AlunoComMensalidades.fromJson(Map<String, dynamic> json) {
    var mensalidadesList = json['mensalidades'] as List;
    List<Mensalidade> mensalidades =
        mensalidadesList.map((i) => Mensalidade.fromJson(i)).toList();
    // Ordena as mensalidades da mais recente para a mais antiga
    mensalidades.sort((a, b) => b.mesReferencia.compareTo(a.mesReferencia));
    return AlunoComMensalidades(
      nomeCompleto: json['nome_completo'],
      mensalidades: mensalidades,
    );
  }
}

class Mensalidade {
  final DateTime mesReferencia;
  final double valorNominal;
  final String status;

  Mensalidade({
    required this.mesReferencia,
    required this.valorNominal,
    required this.status,
  });

  factory Mensalidade.fromJson(Map<String, dynamic> json) {
    return Mensalidade(
      mesReferencia: DateTime.parse(json['mes_referencia']),
      valorNominal: double.parse(json['valor_nominal']),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Faturas'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
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

          final alunos = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: alunos.length,
            itemBuilder: (context, index) {
              final aluno = alunos[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                elevation: 2,
                child: ExpansionTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF8B5CF6),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(aluno.nomeCompleto, style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: aluno.mensalidades.map((mensalidade) {
                    return _buildMensalidadeTile(mensalidade);
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMensalidadeTile(Mensalidade mensalidade) {
    final formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    // --- CORREÇÃO APLICADA AQUI ---
    // Usamos 'MMMM yyyy' para obter "Mês Ano" (ex: "julho 2025")
    final formatadorData = DateFormat('MMMM yyyy', 'pt_BR');
    
    final isPaid = mensalidade.status == 'PAGA';

    return ListTile(
      // Adicionamos "Fatura de" antes da data formatada
      title: Text('Fatura de ${formatadorData.format(mensalidade.mesReferencia)}'),
      subtitle: Text('Valor: ${formatadorMoeda.format(mensalidade.valorNominal)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mensalidade.status,
            style: TextStyle(
              color: isPaid ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            isPaid ? Icons.check_circle : Icons.error,
            color: isPaid ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }
}
