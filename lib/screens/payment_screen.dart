// Arquivo: lib/screens/payment_screen.dart
// Substitua o conteúdo do seu arquivo por este código atualizado.

import 'dart:async'; // Importe o pacote async para usar o Timer
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Future<Map<String, dynamic>>? _pixDataFuture;
  Timer? _pollingTimer;
  bool _isPaid = false; // Novo estado para controlar a confirmação

  // --- CORREÇÃO APLICADA AQUI ---
  // A URL foi corrigida para ser uma string simples, sem formatação de link.
  final String _backendUrl = 'https://csa-url-app.onrender.com/api';

  @override
  void initState() {
    super.initState();
    _pixDataFuture = _gerarPagamentoPix();
  }

  @override
  void dispose() {
    // É MUITO IMPORTANTE cancelar o timer para evitar vazamentos de memória
    _pollingTimer?.cancel();
    super.dispose();
  }

  /// Inicia a verificação periódica do status do pagamento.
  void _startPollingForPaymentStatus() {
    // Cancela qualquer timer anterior para segurança
    _pollingTimer?.cancel();

    // Cria um timer que chama a função _checkPaymentStatus a cada 5 segundos
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkPaymentStatus();
    });
  }

  /// Verifica o status do pagamento no backend.
  Future<void> _checkPaymentStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/pagamento/status/${widget.mensalidadeId}/'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final status = data['status'];

        // Se o status for 'PAGA', atualiza a UI e para o timer
        if (status == 'PAGA') {
          if (mounted) {
            setState(() {
              _isPaid = true;
            });
          }
          _pollingTimer?.cancel();
        }
      }
    } catch (e) {
      // Se houver erro na verificação, apenas imprime no console para não incomodar o usuário
      print("Erro ao verificar status do pagamento: $e");
    }
  }

  Future<Map<String, dynamic>> _gerarPagamentoPix() async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/pagamento/criar-pix/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mensalidade_id': widget.mensalidadeId}),
      );

      if (response.statusCode == 201) {
        // Se o Pix foi gerado com sucesso, COMEÇA A VERIFICAR O STATUS
        _startPollingForPaymentStatus();
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception('Falha ao gerar Pix: ${errorBody['error'] ?? response.body}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: ${e.toString()}');
    }
  }
  
  // --- WIDGET DE SUCESSO ---
  Widget _buildSuccessWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 100),
          const SizedBox(height: 24),
          const Text(
            'Pagamento Confirmado!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Obrigado! Seu pagamento foi processado com sucesso.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // Volta para a tela anterior (Dashboard)
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            ),
            child: const Text('Voltar para o Início'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagamento via Pix'),
        backgroundColor: theme.primaryColor,
      ),
      // Se o pagamento foi confirmado, mostra a tela de sucesso. Senão, mostra o QR Code.
      body: _isPaid ? _buildSuccessWidget() : Center(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _pixDataFuture,
          builder: (context, snapshot) {
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
                    const SizedBox(height: 16),
                    const Text(
                      'Aguardando confirmação do pagamento...',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
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
                      'Ou use o Pix Copia e Cola:',
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

            return const Text('Algo inesperado aconteceu.');
          },
        ),
      ),
    );
  }
}
