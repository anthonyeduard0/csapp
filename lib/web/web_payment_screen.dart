// lib/web/web_payment_screen.dart
// Layout Web/Desktop (largura >= 768px) para Checkout de Pagamento via Pix em 2 Colunas.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:educsa/providers/theme_provider.dart';

class WebPaymentScreen extends StatelessWidget {
  final String mensalidadeId;
  final String valor;
  final String mesReferencia;
  final Future<Map<String, dynamic>>? pixDataFuture;
  final bool isPaid;
  final VoidCallback onBack;
  final VoidCallback onRetryGeneratePix;

  const WebPaymentScreen({
    super.key,
    required this.mensalidadeId,
    required this.valor,
    required this.mesReferencia,
    required this.pixDataFuture,
    required this.isPaid,
    required this.onBack,
    required this.onRetryGeneratePix,
  });

  static const Color primaryColor = Color(0xFF1D449B);
  static const Color accentColor = Color(0xFF25B6E8);

  bool get _isBatch => mensalidadeId.startsWith('lote_');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B0F19) : const Color(0xFFF0F4FF),
      body: Column(
        children: [
          _buildTopBar(context, isDark),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: isPaid
                      ? _buildSuccessCheckoutCard(context, isDark)
                      : _buildCheckoutBody(context, isDark),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CABEÇALHO SUPERIOR: Voltar + Título + Badge Ambiente Seguro + Tema
  // ===========================================================================

  Widget _buildTopBar(BuildContext context, bool isDark) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withAlpha(10),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Tooltip(
              message: 'Voltar',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : primaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pagamento via Pix',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : primaryColor,
                  ),
                ),
                Text(
                  'Checkout instantâneo com liberação automática',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Alternar Tema
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              final isThemeDark = themeProvider.isDarkMode;
              return Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Tooltip(
                  message: isThemeDark
                      ? 'Alternar para tema claro'
                      : 'Alternar para tema escuro',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => themeProvider.toggleTheme(!isThemeDark),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          isThemeDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: isThemeDark
                              ? const Color(0xFFF59E0B)
                              : primaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CORPO DO CHECKOUT EM 2 COLUNAS (flex 5 : flex 6)
  // ===========================================================================

  Widget _buildCheckoutBody(BuildContext context, bool isDark) {
    return FutureBuilder<Map<String, dynamic>>(
      future: pixDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard(isDark);
        }
        if (snapshot.hasError) {
          return _buildErrorCard(snapshot.error.toString(), isDark);
        }
        if (!snapshot.hasData) {
          return _buildErrorCard(
              'Não foi possível obter os dados do Pix.', isDark);
        }

        final pixData = snapshot.data!;
        final qrCodeBase64 = pixData['qr_code_base64'] as String?;
        final qrCodeText = pixData['qr_code'] as String?;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coluna Esquerda (flex: 5 — Resumo da Cobrança e Instruções)
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBillingSummaryCard(isDark),
                  const SizedBox(height: 24),
                  _buildStepByStepCard(isDark),
                ],
              ),
            ),
            const SizedBox(width: 28),
            // Coluna Direita (flex: 6 — QR Code e Copia e Cola)
            Expanded(
              flex: 6,
              child: _buildQrAndCopyPasteCard(
                context: context,
                isDark: isDark,
                qrCodeBase64: qrCodeBase64,
                qrCodeText: qrCodeText,
              ),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // COLUNA ESQUERDA: Resumo da Cobrança + Passo a Passo
  // ===========================================================================

  Widget _buildBillingSummaryCard(bool isDark) {
    final formatadorMoeda =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final valorNumerico = double.tryParse(valor) ?? 0.0;
    final valorFormatado = formatadorMoeda.format(valorNumerico);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0F172A), Color(0xFF1E3A8A)]
              : const [primaryColor, accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withAlpha(60),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges de status: Aguardando Pagamento e Matrícula (se aplicável)
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(28),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFFDE047)),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Aguardando Pagamento',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (mesReferencia.contains('Matrícula'))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE047).withAlpha(40),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFDE047),
                      width: 1.2,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.school_rounded,
                        size: 14,
                        color: Color(0xFFFDE047),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'MATRÍCULA',
                        style: TextStyle(
                          color: Color(0xFFFDE047),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Valor Total a Pagar',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valorFormatado,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              children: [
                _buildSummaryMetaRow(
                  icon: Icons.description_rounded,
                  label: _isBatch ? 'Pagamento em Lote' : 'Referência da Fatura',
                  value: mesReferencia,
                ),
                const SizedBox(height: 10),
                _buildSummaryMetaRow(
                  icon: Icons.pix_rounded,
                  label: 'Modalidade',
                  value: 'Pix Instantâneo (24h)',
                ),
                const SizedBox(height: 10),
                _buildSummaryMetaRow(
                  icon: Icons.verified_rounded,
                  label: 'Beneficiário',
                  value: 'Colégio Santo Antônio • EduCSA',
                ),
              ],
            ),
          ),
          if (mesReferencia.contains('Matrícula')) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white30),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.school_rounded,
                    color: Color(0xFFFDE047),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'O pagamento desta parcela efetiva a renovação de matrícula online.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryMetaRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStepByStepCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isDark ? Colors.black.withAlpha(50) : Colors.black.withAlpha(8),
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
                  color: (isDark ? const Color(0xFF3B82F6) : primaryColor)
                      .withAlpha(22),
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
          const SizedBox(height: 18),
          _buildStepItem(
            stepNumber: '1',
            title: 'Abra o app do seu banco',
            description:
                'No seu celular, acesse o aplicativo da sua instituição financeira ou carteira digital.',
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildStepItem(
            stepNumber: '2',
            title: 'Escolha pagar via Pix com QR Code ou Copia e Cola',
            description:
                'Aponte a câmera para o QR Code ao lado ou clique em "Copiar Código Pix" para colar no aplicativo.',
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildStepItem(
            stepNumber: '3',
            title: 'Confirme os dados e finalize',
            description:
                'A baixa ocorre automaticamente nesta tela em poucos segundos após a confirmação.',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String stepNumber,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
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
              stepNumber,
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

  // ===========================================================================
  // COLUNA DIREITA (flex: 6): QR Code Base64 + Pix Copia e Cola + Copiar
  // ===========================================================================

  Widget _buildQrAndCopyPasteCard({
    required BuildContext context,
    required bool isDark,
    required String? qrCodeBase64,
    required String? qrCodeText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isDark ? Colors.black.withAlpha(55) : Colors.black.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_scanner_rounded,
                color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Escaneie o QR Code Pix',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Aponte a câmera do seu celular para realizar a leitura imediata',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Moldura com fundo branco puro mesmo no modo escuro para leitura perfeita do QR Code
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.grey.shade200,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 70 : 18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: qrCodeBase64 != null && qrCodeBase64.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(qrCodeBase64),
                      width: 240,
                      height: 240,
                      fit: BoxFit.contain,
                    ),
                  )
                : const SizedBox(
                    width: 240,
                    height: 240,
                    child: Center(
                      child: Text(
                        'QR Code Indisponível',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'OU PIX COPIA E COLA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Caixa estilizada com o código Pix Copia e Cola
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
              ),
            ),
            child: SelectableText(
              qrCodeText ?? 'Código indisponível',
              textAlign: TextAlign.center,
              maxLines: 3,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                height: 1.4,
                color: isDark ? const Color(0xFFCBD5E1) : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Botão principal "Copiar Código Pix"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (qrCodeText != null && qrCodeText.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: qrCodeText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text('Código Pix copiado para a área de transferência!'),
                        ],
                      ),
                      backgroundColor:
                          isDark ? const Color(0xFF3B82F6) : primaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded, size: 20),
              label: const Text(
                'Copiar Código Pix',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? const Color(0xFF3B82F6) : primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ESTADOS DE CARREGAMENTO, ERRO E SUCESSO
  // ===========================================================================

  Widget _buildLoadingCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? const Color(0xFF60A5FA) : primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Gerando cobrança Pix segura...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Aguarde alguns instantes enquanto conectamos ao Mercado Pago.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            'Não foi possível gerar o QR Code Pix',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFFF87171) : Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetryGeneratePix,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Tentar novamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCheckoutCard(BuildContext context, bool isDark) {
    final formatadorMoeda =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final valorNumerico = double.tryParse(valor) ?? 0.0;
    final valorFormatado = formatadorMoeda.format(valorNumerico);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isDark ? Colors.black.withAlpha(55) : Colors.black.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withAlpha(80),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 64,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Pagamento Confirmado!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Seu pagamento de $valorFormatado (Ref: $mesReferencia) foi processado com sucesso.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text(
              'Voltar para o Painel Financeiro',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF3B82F6) : primaryColor,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
