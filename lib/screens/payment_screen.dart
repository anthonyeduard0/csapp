import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:educsa/api_config.dart';
import 'package:educsa/web/web_payment_screen.dart';

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
  int _checksCount = 0; // --- OTIMIZAÇÃO: Contador para Backoff ---

  static const Color primaryColor = Color(0xFF1D449B);
  static const Color accentColor = Color(0xFF25B6E8);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const double _desktopBreakpoint = 768;

  @override
  void initState() {
    super.initState();
    if (widget.initialPixData != null) {
      _pixDataFuture = Future.value(widget.initialPixData);
      _startPollingForPaymentStatus();
    } else {
      _pixDataFuture = _gerarPagamentoPixIndividual();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _retryGeneratePix() {
    setState(() {
      _pixDataFuture = _gerarPagamentoPixIndividual();
    });
  }

  void _startPollingForPaymentStatus() {
    _pollingTimer?.cancel();
    if (widget.mensalidadeId.startsWith('lote_')) return;

    // --- OTIMIZAÇÃO DE POLLING ---
    // Verifica a cada 5 segundos, mas para após 5 minutos (60 tentativas).
    _checksCount = 0;
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checksCount++;
      if (_checksCount > 60) {
        timer.cancel();
        return;
      }
      _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    // --- ATUALIZAÇÃO: Busca Token ---
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    // Se não tiver token, não faz a requisição (segurança e economia)
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/pagamento/status/${widget.mensalidadeId}/'),
        headers: {
          'Authorization': 'Bearer $token', // Header de Autenticação
        },
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
      debugPrint("Falha ao checar status do pagamento: $e");
    }
  }

  Future<Map<String, dynamic>> _gerarPagamentoPixIndividual() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) throw Exception('Não autenticado.');

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/pagamento/criar-pix/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Header de Autenticação
        },
        body: jsonEncode({'mensalidade_id': widget.mensalidadeId}),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        _startPollingForPaymentStatus();
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(
            'Falha ao gerar Pix: ${errorBody['error'] ?? response.body}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _desktopBreakpoint) {
          return WebPaymentScreen(
            mensalidadeId: widget.mensalidadeId,
            valor: widget.valor,
            mesReferencia: widget.mesReferencia,
            pixDataFuture: _pixDataFuture,
            isPaid: _isPaid,
            onBack: () => Navigator.pop(context, _isPaid),
            onRetryGeneratePix: _retryGeneratePix,
          );
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : backgroundColor,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF0F172A), Color(0xFF1E3A8A)]
                    : const [primaryColor, accentColor],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color:
                            isDark ? const Color(0xFF0F172A) : backgroundColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: _isPaid
                          ? _buildSuccessWidget(isDark)
                          : _buildPaymentContent(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context, _isPaid),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pagamento via Pix',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                Text('Finalize sua transação',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentContent(bool isDark) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _pixDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? const Color(0xFF60A5FA) : primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Gerando QR Code...',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
                    fontSize: 16,
                  ),
                ),
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
                style: TextStyle(
                  color: isDark ? const Color(0xFFF87171) : Colors.red,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }
        if (snapshot.hasData) {
          final pixData = snapshot.data!;
          final qrCodeBase64 = pixData['qr_code_base64'];
          final qrCodeText = pixData['qr_code'];
          final formatadorMoeda =
              NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
          final valorNumerico = double.tryParse(widget.valor) ?? 0.0;
          final valorFormatado = formatadorMoeda.format(valorNumerico);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                if (widget.mesReferencia.contains('Matrícula')) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF93C5FD),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.school_rounded,
                          size: 14,
                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'MATRÍCULA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (widget.mesReferencia.contains('Matrícula')) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF064E3B).withAlpha(80)
                          : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF059669).withAlpha(90)
                            : const Color(0xFF86EFAC),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'O pagamento desta parcela efetiva a renovação de matrícula online.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Text(
                  'Valor Total a Pagar',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valorFormatado,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildBillingMetaCard(isDark),
                const SizedBox(height: 24),

                // Exibe o QR Code
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: isDark ? Border.all(color: Colors.white24) : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 50 : 12),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: qrCodeBase64 != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(base64Decode(qrCodeBase64),
                              width: 220, height: 220),
                        )
                      : const SizedBox(
                          height: 220,
                          width: 220,
                          child: Center(
                            child: Text(
                              "QR Code Imagem Indisponível",
                              style: TextStyle(
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 24),
                Text(
                  'Ou use o Pix Copia e Cola:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: isDark
                        ? Border.all(color: const Color(0xFF334155))
                        : null,
                  ),
                  child: Text(
                    qrCodeText ?? "Código indisponível",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isDark ? const Color(0xFF94A3B8) : Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botão de Copiar
                ElevatedButton.icon(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  label: const Text('Copiar Código Pix'),
                  onPressed: () {
                    if (qrCodeText != null) {
                      Clipboard.setData(ClipboardData(text: qrCodeText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Código Pix copiado!'),
                          backgroundColor:
                              isDark ? const Color(0xFF3B82F6) : primaryColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? const Color(0xFF3B82F6) : primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 24),
                _buildStepByStepCard(isDark),
              ],
            ),
          );
        }
        return Center(
          child: Text(
            'Algo inesperado aconteceu.',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
        );
      },
    );
  }

  Widget _buildBillingMetaCard(bool isDark) {
    final bool isBatch = widget.mensalidadeId.startsWith('lote_');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildMetaRow(
            Icons.description_rounded,
            isBatch ? 'Pagamento em Lote' : 'Referência da Fatura',
            widget.mesReferencia,
            isDark,
          ),
          const SizedBox(height: 10),
          _buildMetaRow(Icons.pix_rounded, 'Modalidade', 'Pix Instantâneo (24h)', isDark),
          const SizedBox(height: 10),
          _buildMetaRow(Icons.verified_rounded, 'Beneficiário',
              'Colégio Santo Antônio • EduCSA', isDark),
        ],
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value, bool isDark) {
    final Color muted = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: muted),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, color: muted)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepByStepCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withAlpha(50) : Colors.black.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF3B82F6) : primaryColor).withAlpha(22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.help_outline_rounded,
                  color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Passo a Passo para Pagar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStepItem(
            '1',
            'Abra o app do seu banco',
            'No seu celular, acesse o aplicativo da sua instituição financeira ou carteira digital.',
            isDark,
          ),
          const SizedBox(height: 12),
          _buildStepItem(
            '2',
            'Escolha pagar via Pix com QR Code ou Copia e Cola',
            "Escaneie o QR Code acima ou clique em 'Copiar Código Pix' para colar no aplicativo do seu banco.",
            isDark,
          ),
          const SizedBox(height: 12),
          _buildStepItem(
            '3',
            'Confirme os dados e finalize',
            'A baixa ocorre automaticamente nesta tela em poucos segundos após a confirmação.',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String title, String description, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [primaryColor, accentColor]),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessWidget(bool isDark) {
    final valorFormatado = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
        .format(double.tryParse(widget.valor) ?? 0.0);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withAlpha(80),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child:
                const Icon(Icons.check_rounded, color: Colors.white, size: 80),
          ),
          const SizedBox(height: 32),
          Text(
            'Pagamento Confirmado!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Seu pagamento de $valorFormatado (Ref: ${widget.mesReferencia}) foi processado com sucesso.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF3B82F6) : primaryColor,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Voltar para o Início'),
          )
        ],
      ),
    );
  }
}
