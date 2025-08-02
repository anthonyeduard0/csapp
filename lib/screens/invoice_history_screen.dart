// Arquivo: lib/screens/invoice_history_screen.dart
// VERSÃO COM LÓGICA DE ORDENAÇÃO E PAGAMENTO CORRIGIDA

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:csapp/screens/payment_screen.dart';
import 'main_screen.dart'; 

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

  Future<void> _refreshData() async {
    setState(() {
      _historyFuture = _fetchInvoiceHistory();
      _selectedInvoiceIds.clear();
      _totalSelecionado = 0.0;
    });
  }

  Future<List<AlunoComMensalidades>> _fetchInvoiceHistory() async {
    final url = Uri.parse('https://csa-url-app.onrender.com/api/mensalidades/?cpf=${widget.responsavelCpf}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        final data = body.map((dynamic item) => AlunoComMensalidades.fromJson(item)).toList();
        
        // Junta as faturas de todos os alunos em uma única lista
        _allInvoices = data.expand((aluno) => aluno.mensalidades).toList();
        
        // --- CORREÇÃO PRINCIPAL ---
        // Garante que a lista principal de faturas esteja sempre ordenada da mais antiga para a mais nova.
        // Isso resolve o problema de faturas de anos diferentes.
        _allInvoices.sort((a, b) => a.mesReferencia.compareTo(b.mesReferencia));
        
        return data;
      } else {
        throw Exception('Falha ao carregar o histórico de faturas.');
      }
    } catch (e) {
      throw Exception('Erro de conexão: ${e.toString()}');
    }
  }

  void _onInvoiceSelected(bool? isSelected, Mensalidade mensalidade) {
    // Agora que _allInvoices está sempre ordenada, podemos confiar nela.
    final mensalidadesEmAberto = _allInvoices
        .where((m) => m.status == 'PENDENTE' || m.status == 'ATRASADA')
        .toList(); // Não precisa mais de sort aqui, a lista já está na ordem correta.

    if (isSelected == true) {
      // Encontra a primeira fatura em aberto que ainda não foi selecionada.
      // Como a lista está ordenada, esta será a mais antiga.
      Mensalidade? faturaMaisAntigaNaoSelecionada;
      for (final fatura in mensalidadesEmAberto) {
        if (!_selectedInvoiceIds.contains(fatura.id)) {
          faturaMaisAntigaNaoSelecionada = fatura;
          break;
        }
      }

      // Se existe uma fatura mais antiga não paga, e o usuário está tentando
      // pagar uma fatura posterior a ela, bloqueia a ação.
      if (faturaMaisAntigaNaoSelecionada != null &&
          mensalidade.mesReferencia.isAfter(faturaMaisAntigaNaoSelecionada.mesReferencia)) {
        
        final mesFormatado = DateFormat('MMMM \'de\' yyyy', 'pt_BR').format(faturaMaisAntigaNaoSelecionada.mesReferencia);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Por favor, pague ou selecione a fatura de ${capitalize(mesFormatado)} primeiro.'),
            backgroundColor: Colors.orange.shade700,
          ),
        );
        return; // Impede a seleção
      }
    }

    // Se a lógica de bloqueio não foi ativada, permite a seleção/deseleção.
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
    if (!mounted) return;
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
        _refreshData();

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Faturas'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Container(
              color: Theme.of(context).appBarTheme.backgroundColor,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(51),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: TabBar(
                    indicatorPadding: const EdgeInsets.all(4.0),
                    indicator: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    tabs: const [
                      Tab(text: 'Em aberto'),
                      Tab(text: 'Histórico'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refreshData,
          child: FutureBuilder<List<AlunoComMensalidades>>(
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
              // Filtra a lista principal (que já está ordenada) para cada aba
              final mensalidadesEmAberto = _allInvoices.where((m) => m.status == 'PENDENTE' || m.status == 'ATRASADA').toList();
              final historicoFaturas = _allInvoices.where((m) => m.status == 'PAGA' || m.status == 'CANCELADA').toList();
              
              return TabBarView(
                children: [
                  _buildInvoiceList(mensalidadesEmAberto, isPending: true),
                  _buildInvoiceList(historicoFaturas, isPending: false),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: _selectedInvoiceIds.isNotEmpty
            ? _buildPaymentFooter(context)
            : null,
      ),
    );
  }
  
  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'PAGA':
        return {'text': 'PAGO', 'color': Colors.green.shade800, 'bgColor': Colors.green.shade100};
      case 'ATRASADA':
        return {'text': 'EM ATRASO', 'color': Colors.red.shade800, 'bgColor': Colors.red.shade100};
      case 'PENDENTE':
        return {'text': 'PENDENTE', 'color': Colors.orange.shade800, 'bgColor': Colors.orange.shade100};
      case 'CANCELADA':
        return {'text': 'CANCELADA', 'color': Colors.grey.shade700, 'bgColor': Colors.grey.shade300};
      default:
        return {'text': status, 'color': Colors.black, 'bgColor': Colors.grey.shade200};
    }
  }

  Widget _buildInvoiceList(List<Mensalidade> mensalidades, {required bool isPending}) {
    if (mensalidades.isEmpty) {
      return LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const Center(child: Text('Nenhuma fatura nesta categoria.')),
          ),
        );
      });
    }
    // Não é mais necessário ordenar aqui, a lista principal já está correta.
    // Para a aba de histórico, invertemos a ordem para mostrar as mais recentes primeiro.
    final listParaExibir = isPending ? mensalidades : mensalidades.reversed.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: listParaExibir.length,
      itemBuilder: (context, index) {
        return _buildInvoiceCard(listParaExibir[index], isPending: isPending);
      },
    );
  }

  Widget _buildInvoiceCard(Mensalidade mensalidade, {required bool isPending}) {
    final bool isSelected = _selectedInvoiceIds.contains(mensalidade.id);
    final formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formatadorMesAno = DateFormat('MMMM \'de\' yyyy', 'pt_BR');
    final formatadorVencimento = DateFormat('dd/MM/yyyy');
    final mesFormatado = capitalize(formatadorMesAno.format(mensalidade.mesReferencia));
    
    final statusInfo = _getStatusInfo(mensalidade.status);
    
    return Card(
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
                  activeColor: Theme.of(context).primaryColor,
                  shape: const CircleBorder(),
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
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatadorMoeda.format(mensalidade.valorFinal),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusInfo['bgColor'],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusInfo['text'],
                      style: TextStyle(
                        color: statusInfo['color'],
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

  Widget _buildPaymentFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
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
            child: const Text('Pagar'),
          ),
        ],
      ),
    );
  }
}

String capitalize(String s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '';
