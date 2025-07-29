// Arquivo: lib/screens/invoice_history_screen.dart
// VERSÃO COM NOVA REGRA DE SELEÇÃO DE FATURAS

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:csapp/screens/payment_screen.dart';
import 'dashboard_screen.dart'; 

class InvoiceHistoryScreen extends StatefulWidget {
  final String responsavelCpf;
  const InvoiceHistoryScreen({super.key, required this.responsavelCpf});
  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  Future<List<AlunoComMensalidades>>? _historyFuture;
  final Set<String> _selectedInvoiceIds = {};
  double _totalSelecionado = 0.0;
  List<Mensalidade> _allInvoices = [];

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchInvoiceHistory();
  }

  Future<List<AlunoComMensalidades>> _fetchInvoiceHistory() async {
    final url = Uri.parse('https://csa-url-app.onrender.com/api/mensalidades/?cpf=${widget.responsavelCpf}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        final data = body.map((dynamic item) => AlunoComMensalidades.fromJson(item)).toList();
        _allInvoices = data.expand((aluno) => aluno.mensalidades).toList();
        return data;
      } else {
        throw Exception('Falha ao carregar o histórico de faturas.');
      }
    } catch (e) {
      throw Exception('Erro de conexão: ${e.toString()}');
    }
  }

  void _onInvoiceSelected(bool? isSelected, Mensalidade mensalidade) {
    // +++ NOVA FUNCIONALIDADE: Validação de Faturas Anteriores (Frontend) +++
    final mensalidadesEmAberto = _allInvoices
        .where((m) => m.status != 'PAGA')
        .toList()
        ..sort((a, b) => a.mesReferencia.compareTo(b.mesReferencia));

    if (isSelected == true) {
      // Encontra a fatura mais antiga em aberto que ainda não foi selecionada.
      Mensalidade? faturaMaisAntigaNaoSelecionada;
      for (final fatura in mensalidadesEmAberto) {
        if (!_selectedInvoiceIds.contains(fatura.id)) {
          faturaMaisAntigaNaoSelecionada = fatura;
          break;
        }
      }

      // Se existe uma fatura mais antiga não selecionada, e o usuário está tentando
      // selecionar uma fatura mais recente, exibe um erro e bloqueia a ação.
      if (faturaMaisAntigaNaoSelecionada != null &&
          mensalidade.mesReferencia.isAfter(faturaMaisAntigaNaoSelecionada.mesReferencia)) {
        
        final mesFormatado = DateFormat('MMMM', 'pt_BR').format(faturaMaisAntigaNaoSelecionada.mesReferencia);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Por favor, pague ou selecione a fatura de $mesFormatado primeiro.'),
            backgroundColor: Colors.orange.shade700,
          ),
        );
        return; // Bloqueia a seleção
      }
    }
    // +++ FIM DA NOVA FUNCIONALIDADE +++

    setState(() {
      if (isSelected == true) {
        _selectedInvoiceIds.add(mensalidade.id);
        _totalSelecionado += mensalidade.valorFinal;
      } else {
        _selectedInvoiceIds.remove(mensalidade.id);
        _totalSelecionado -= mensalidade.valorFinal;
      }
    });
  }

  Future<void> _pagarSelecionados(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final url = Uri.parse('https://csa-url-app.onrender.com/api/pagamento/criar-pix-lote/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mensalidade_ids': _selectedInvoiceIds.toList()}),
      );

      if (response.statusCode == 201) {
        final pixData = jsonDecode(utf8.decode(response.bodyBytes));
        await navigator.push(
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              mensalidadeId: 'lote_${DateTime.now().millisecondsSinceEpoch}',
              valor: _totalSelecionado.toStringAsFixed(2),
              mesReferencia: '${_selectedInvoiceIds.length} faturas',
              initialPixData: pixData,
            ),
          ),
        );
        setState(() {
          _historyFuture = _fetchInvoiceHistory();
          _selectedInvoiceIds.clear();
          _totalSelecionado = 0.0;
        });

      } else {
        final error = jsonDecode(response.body)['error'];
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Erro: $error'), backgroundColor: Colors.red));
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Erro de conexão: $e'), backgroundColor: Colors.red));
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
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: TabBar(
                  labelColor: primaryColor,
                  unselectedLabelColor: Colors.white,
                  indicatorWeight: 0,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
            final mensalidadesEmAberto = _allInvoices.where((m) => m.status != 'PAGA').toList();
            final mensalidadesPagas = _allInvoices.where((m) => m.status == 'PAGA').toList();
            return TabBarView(
              children: [
                _buildInvoiceList(mensalidadesEmAberto, isPending: true),
                _buildInvoiceList(mensalidadesPagas, isPending: false),
              ],
            );
          },
        ),
        bottomNavigationBar: _selectedInvoiceIds.isNotEmpty
            ? _buildPaymentFooter(context)
            : null,
      ),
    );
  }

  Widget _buildPaymentFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_selectedInvoiceIds.length} fatura(s) selecionada(s)'),
              Text(
                NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(_totalSelecionado),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => _pagarSelecionados(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Pagar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceList(List<Mensalidade> mensalidades, {required bool isPending}) {
    if (mensalidades.isEmpty) {
      return const Center(child: Text('Nenhuma fatura nesta categoria.'));
    }
    // Ordena as faturas em aberto da mais antiga para a mais nova
    if (isPending) {
      mensalidades.sort((a, b) => a.mesReferencia.compareTo(b.mesReferencia));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: mensalidades.length,
      itemBuilder: (context, index) {
        return _buildInvoiceCard(mensalidades[index], isPending: isPending);
      },
    );
  }

  Widget _buildInvoiceCard(Mensalidade mensalidade, {required bool isPending}) {
    final bool isSelected = _selectedInvoiceIds.contains(mensalidade.id);
    final formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formatadorMesAno = DateFormat('MMMM \'de\' yyyy', 'pt_BR');
    final formatadorVencimento = DateFormat('dd/MM/yyyy');
    final isPaid = mensalidade.status == 'PAGA';
    final mesFormatado = capitalize(formatadorMesAno.format(mensalidade.mesReferencia));

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected ? const BorderSide(color: Color(0xFF1E3A8A), width: 2) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isPending ? () => _onInvoiceSelected(!isSelected, mensalidade) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
          child: Row(
            children: [
              if (isPending)
                Checkbox(
                  value: isSelected,
                  onChanged: (bool? value) => _onInvoiceSelected(value, mensalidade),
                  activeColor: const Color(0xFF1E3A8A),
                ),
              if (!isPending)
                const SizedBox(width: 48),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mensalidade de $mesFormatado',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vencimento: ${formatadorVencimento.format(mensalidade.dataVencimento)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatadorMoeda.format(isPaid ? mensalidade.valorNominal : mensalidade.valorFinal),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isPaid ? 'PAGO' : 'EM ATRASO',
                      style: TextStyle(
                        color: isPaid ? Colors.green.shade800 : Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

String capitalize(String s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '';
