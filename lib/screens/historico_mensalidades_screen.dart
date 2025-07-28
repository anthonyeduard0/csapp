import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dashboard_screen.dart'; // Reutiliza o modelo de dados da Mensalidade

class HistoricoMensalidadesScreen extends StatefulWidget {
  final String cpfResponsavel;

  const HistoricoMensalidadesScreen({super.key, required this.cpfResponsavel});

  @override
  State<HistoricoMensalidadesScreen> createState() =>
      _HistoricoMensalidadesScreenState();
}

class _HistoricoMensalidadesScreenState
    extends State<HistoricoMensalidadesScreen> {
  late Future<List<Mensalidade>> _historicoFuture;
  final String _backendUrl = 'http://csa-url-app.onrender.com:8000/api';

  @override
  void initState() {
    super.initState();
    _historicoFuture = _fetchHistorico();
  }

  Future<List<Mensalidade>> _fetchHistorico() async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/mensalidades/?cpf=${widget.cpfResponsavel}'),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        List<Mensalidade> mensalidades =
            body.map((dynamic item) => Mensalidade.fromJson(item)).toList();
        return mensalidades;
      } else {
        throw Exception('Falha ao carregar histórico.');
      }
    } catch (e) {
      throw Exception('Erro de conexão: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E3A8A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Mensalidades'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Mensalidade>>(
        future: _historicoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum histórico encontrado.'));
          }

          final mensalidades = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: mensalidades.length,
            itemBuilder: (context, index) {
              final mensalidade = mensalidades[index];
              final bool isPaga = mensalidade.status == 'PAGA';
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                elevation: 2,
                child: ListTile(
                  leading: Icon(
                    isPaga ? Icons.check_circle : Icons.error,
                    color: isPaga ? Colors.green : Colors.orange,
                  ),
                  title: Text(
                      'Referência: ${DateFormat('MM/yyyy').format(mensalidade.dataVencimento)}'),
                  subtitle: Text(
                      'Valor: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(mensalidade.valorNominal)}'),
                  trailing: Text(
                    mensalidade.status,
                    style: TextStyle(
                      color: isPaga ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
