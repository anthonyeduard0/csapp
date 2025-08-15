// lib/screens/calendar_screen.dart
// VERSÃO FINAL: Polimento visual e funcional avançado.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

// Modelo de dados (sem alterações)
class Evento {
  final String id;
  final String titulo;
  final String? descricao;
  final DateTime dataInicio;
  final DateTime? dataFim;

  Evento({
    required this.id,
    required this.titulo,
    this.descricao,
    required this.dataInicio,
    this.dataFim,
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    final dataInicio = DateTime.parse(json['data_inicio']).toLocal();
    final dataFim = json['data_fim'] != null ? DateTime.parse(json['data_fim']).toLocal() : null;
    return Evento(
      id: json['id'],
      titulo: json['titulo'],
      descricao: json['descricao'],
      dataInicio: dataInicio,
      dataFim: dataFim,
    );
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> with TickerProviderStateMixin {
  late final ValueNotifier<List<Evento>> _selectedEvents;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  Map<DateTime, List<Evento>> _events = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;
  String? _error;

  // Cores do tema
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color accentColor = Color(0xFF8B5CF6);
  static const Color backgroundColor = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _fetchEvents();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchEvents() async {
    // Lógica de busca de dados (sem alterações)
    try {
      final response = await http.get(Uri.parse('https://csa-url-app.onrender.com/api/eventos/'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final Map<DateTime, List<Evento>> events = {};
        for (var item in data) {
          final evento = Evento.fromJson(item);
          final date = DateTime.utc(evento.dataInicio.year, evento.dataInicio.month, evento.dataInicio.day);
          if (events[date] == null) {
            events[date] = [];
          }
          events[date]!.add(evento);
        }
        if (mounted) {
          setState(() {
            _events = events;
            _isLoading = false;
          });
          _selectedEvents.value = _getEventsForDay(_selectedDay!);
          _fadeController.forward();
        }
      } else {
        throw Exception('Falha ao carregar eventos');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível carregar os eventos.';
          _isLoading = false;
        });
      }
    }
  }

  List<Evento> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay; // --- 3. CORREÇÃO: Garante que o calendário foque no mês selecionado
        _selectedEvents.value = _getEventsForDay(selectedDay);
      });
    }
  }
  
  String capitalize(String s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ Color(0xFF1E3A8A), Color(0xFF3B82F6), Color(0xFF8B5CF6) ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  // --- 1 & 6. CORREÇÃO: Adicionado Scrollbar e SingleChildScrollView para evitar overflow ---
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      child: _isLoading
                          ? _buildLoadingState()
                          : _error != null
                              ? _buildErrorState()
                              : _buildCalendarContent(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() { /* ... (sem alterações) ... */ 
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Calendário Escolar', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Acompanhe os eventos importantes', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() { /* ... (sem alterações) ... */ 
    return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)));
  }

  Widget _buildErrorState() { /* ... (sem alterações) ... */ 
    return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
  }

  Widget _buildCalendarContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            padding: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [ BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8)) ],
            ),
            child: TableCalendar<Evento>(
              locale: 'pt_BR',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              eventLoader: _getEventsForDay,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextFormatter: (date, locale) => capitalize(DateFormat.yMMMM(locale).format(date)),
                titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                leftChevronIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.chevron_left, color: primaryColor),
                ),
                rightChevronIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.chevron_right, color: primaryColor),
                ),
              ),
              daysOfWeekHeight: 30.0,
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600),
                weekendStyle: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: true,
                outsideTextStyle: const TextStyle(color: Color(0xFFCBD5E1)),
                weekendTextStyle: const TextStyle(color: Colors.red),
                todayDecoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF67E8F9), Color(0xFF22D3EE)]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color(0xFF22D3EE).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]),
                // --- 4. CORREÇÃO: GRADIENTE AZUL ESCURO PARA O DIA SELECIONADO ---
                selectedDecoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [primaryColor, accentColor]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))]),
                // --- 5. CORREÇÃO: MARCADOR DE EVENTO VERDE BEBÊ ---
                markerDecoration: const BoxDecoration(color: Color(0xFFA7F3D0), shape: BoxShape.circle),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [ BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8)) ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [primaryColor, accentColor]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.event_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDay != null ? 'Eventos de ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}' : 'Eventos do dia',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                ValueListenableBuilder<List<Evento>>(
                  valueListenable: _selectedEvents,
                  builder: (context, value, _) {
                    if (value.isEmpty) return _buildEmptyEventsState();
                    return ListView.builder(
                      shrinkWrap: true, // Essencial para ListView dentro de SingleChildScrollView
                      physics: const NeverScrollableScrollPhysics(), // Desabilita o scroll da lista interna
                      padding: const EdgeInsets.all(16),
                      itemCount: value.length,
                      itemBuilder: (context, index) {
                        return EventCard(evento: value[index]);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyEventsState() { /* ... (sem alterações) ... */ 
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Nenhum evento para este dia', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET PARA O CARD DE EVENTO EXPANSÍVEL ---
class EventCard extends StatefulWidget {
  final Evento evento;
  const EventCard({super.key, required this.evento});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E3A8A);
    const Color accentColor = Color(0xFF8B5CF6);
    
    final formatadorHora = DateFormat('HH:mm');
    String horario;
    if (widget.evento.dataFim != null && widget.evento.dataFim != widget.evento.dataInicio) {
      horario = '${formatadorHora.format(widget.evento.dataInicio)} - ${formatadorHora.format(widget.evento.dataFim!)}';
    } else {
      horario = formatadorHora.format(widget.evento.dataInicio);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white, Colors.grey.shade50]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          onExpansionChanged: (bool expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // --- 2. CORREÇÃO: GRADIENTE AZUL ESCURO NOS ÍCONES ---
              gradient: const LinearGradient(colors: [primaryColor, accentColor]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.event_note_rounded, color: Colors.white, size: 20),
          ),
          title: Text(widget.evento.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
          subtitle: Text(horario, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
          trailing: Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            color: primaryColor,
          ),
          children: <Widget>[
            if (widget.evento.descricao != null && widget.evento.descricao!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.evento.descricao!,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
