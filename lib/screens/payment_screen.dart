import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para usar o Clipboard
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentScreen extends StatefulWidget {
  final String mensalidadeId;
  final String valor;
  final String mesReferencia;

  const PaymentScreen({
    super.key,
    required this.mensalidadeId,
    required this.valor,
    required this.mesReferencia,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Estados da tela
  Future<Map<String, dynamic>>? _pixDataFuture;

  // TODO: Substitua pela URL do seu backend (use o IP da sua máquina para testes no celular)
  // Ex: 'http://192.168.0.107:8000/api'
  final String _backendUrl = 'https://csa-url-app.onrender.com/api';

  @override
  void initState() {
    super.initState();
    // Inicia a chamada à API assim que a tela é construída
    _pixDataFuture = _gerarPagamentoPix();
  }

  /// Chama o backend para gerar os dados do pagamento Pix.
  Future<Map<String, dynamic>> _gerarPagamentoPix() async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/pagamento/criar-pix/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mensalidade_id': widget.mensalidadeId}),
      );

      if (response.statusCode == 201) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        // Tenta decodificar a mensagem de erro do backend
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception('Falha ao gerar Pix: ${errorBody['error'] ?? response.body}');
      }
    } catch (e) {
      // Captura erros de rede ou de parsing
      throw Exception('Erro de conexão: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagamento via Pix'),
        backgroundColor: theme.primaryColor,
      ),
      body: Center(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _pixDataFuture,
          builder: (context, snapshot) {
            // 1. Estado de Carregamento
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Gerando QR Code...'),
                ],
              );
            }

            // 2. Estado de Erro
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Ocorreu um erro: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              );
            }

            // 3. Estado de Sucesso
            if (snapshot.hasData) {
              final pixData = snapshot.data!;
              final qrCodeBase64 = pixData['qr_code_base64'];
              final qrCodeText = pixData['qr_code'];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Pague a mensalidade via Pix',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Referência: ${widget.mesReferencia} - Valor: R\$ ${widget.valor}',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '1. Abra o app do seu banco e escaneie o código abaixo:',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Exibe a imagem do QR Code
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.memory(
                        base64Decode(qrCodeBase64),
                        width: 250,
                        height: 250,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '2. Ou use o Pix Copia e Cola:',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        qrCodeText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Copiar Código'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: qrCodeText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Código Pix copiado!')),
                        );
                      },
                    ),
                  ],
                ),
              );
            }

            // Estado Padrão (não deve ser alcançado)
            return const Text('Algo inesperado aconteceu.');
          },
        ),
      ),
    );
  }
}
