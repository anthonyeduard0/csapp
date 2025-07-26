// Arquivo: lib/screens/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentScreen extends StatefulWidget {
  final String cpf;
  const PaymentScreen({super.key, required this.cpf});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Future<Map<String, dynamic>>? _pixDataFuture;

  @override
  void initState() {
    super.initState();
    _pixDataFuture = _gerarPix();
  }

  Future<Map<String, dynamic>> _gerarPix() async {
    final url = Uri.parse('http://192.168.0.107/api/pagamento/pix/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'cpf': widget.cpf}),
      );
      if (response.statusCode == 201) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Falha ao gerar o código Pix.');
      }
    } catch (e) {
      throw Exception('Erro de conexão ao gerar o Pix.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento via Pix')),
      body: Center(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _pixDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Erro: ${snapshot.error}');
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('Não foi possível obter os dados do Pix.');
            }

            final pixData = snapshot.data!;
            final qrCode = pixData['qr_code'];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Escaneie o QR Code com o app do seu banco',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 2),
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: QrImageView(
                      data: qrCode,
                      version: QrVersions.auto,
                      size: 250.0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Ou copie o código abaixo:'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: Text(qrCode, style: const TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('COPIAR CÓDIGO'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: qrCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código Pix copiado!')),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Após o pagamento, o status será atualizado automaticamente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}