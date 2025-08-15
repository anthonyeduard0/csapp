// Arquivo: lib/screens/payment_screen.dart
// VERSÃO CORRIGIDA: Formatação de moeda ajustada para usar vírgula.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // <-- Importação necessária

class PaymentScreen extends StatefulWidget {
  final String mensalidadeId;
  final String valor;
  final String mesReferencia;
  final Map<String, dynamic>? initialPixData;

  const PaymentScreen({
    super.key,
    required this.mensalidadeId,
    required this.valor,
    required this.mesReferencia,
    this.initialPixData,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Future<Map<String, dynamic>>? _pixDataFuture;
  Timer? _pollingTimer;
  bool _isPaid = false;
  final String _backendUrl = 'https://csa-url-app.onrender.com/api';

  // Cores do tema
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color accentColor = Color(0xFF8B5CF6);
  static const Color backgroundColor = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    if (widget.initialPixData != null) {
      _pixDataFuture = Future.value(widget.initialPixData);
    } else {
      _pixDataFuture = _gerarPagamentoPixIndividual();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPollingForPaymentStatus() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (widget.mensalidadeId.startsWith('lote_')) return;
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/pagamento/status/${widget.mensalidadeId}/'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'PAGA') {
          if (mounted) {
            setState(() {
              _isPaid = true;
            });
          }
          _pollingTimer?.cancel();
        }
      }
    } catch (e) {
      // Silencioso
    }
  }

  Future<Map<String, dynamic>> _gerarPagamentoPixIndividual() async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/pagamento/criar-pix/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mensalidade_id': widget.mensalidadeId}),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
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
                  child: _isPaid ? _buildSuccessWidget() : _buildPaymentContent(),
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
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pagamento via Pix', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Finalize sua transação', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentContent() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _pixDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)),
                SizedBox(height: 16),
                Text('Gerando QR Code...', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Ocorreu um erro: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          );
        }
        if (snapshot.hasData) {
          final pixData = snapshot.data!;
          final qrCodeBase64 = pixData['qr_code_base64'];
          final qrCodeText = pixData['qr_code'];

          // --- CORREÇÃO DE FORMATAÇÃO APLICADA AQUI ---
          final formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
          final valorNumerico = double.tryParse(widget.valor) ?? 0.0;
          final valorFormatado = formatadorMoeda.format(valorNumerico);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  'Referência: ${widget.mesReferencia}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  valorFormatado, // Usando o valor formatado
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10)],
                  ),
                  child: Image.memory(base64Decode(qrCodeBase64), width: 220, height: 220),
                ),
                const SizedBox(height: 24),
                const Text('Ou use o Pix Copia e Cola:', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    qrCodeText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  label: const Text('Copiar Código'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: qrCodeText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Código Pix copiado!'),
                        backgroundColor: primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          );
        }
        return const Center(child: Text('Algo inesperado aconteceu.'));
      },
    );
  }

  Widget _buildSuccessWidget() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade600]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 80),
          ),
          const SizedBox(height: 32),
          const Text(
            'Pagamento Confirmado!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Obrigado! Seu pagamento foi processado com sucesso e a fatura foi atualizada.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Voltar para Faturas'),
          )
        ],
      ),
    );
  }
}
