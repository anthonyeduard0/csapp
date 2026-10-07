// lib/web/web_calendar_screen.dart
// Calendário web: layout lado a lado - calendário à esquerda, eventos à direita.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:educsa/api_config.dart';

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
    return Evento(
      id: json['id'],
      titulo: json['titulo'],
      descricao: json['descricao'],
      dataInicio: DateTime.parse(json['data_inicio']).toLocal(),
      dataFim:
          json['data_fim'] != null ? DateTime.parse(json['data_fim']).toLocal() : null,
    );
  }
}

class WebCalendarScreen extends StatefulWidget {
  const WebCalendarScreen({super.key});

  @override
  State<WebCalendarScreen> createState() => _WebCalendarScreenState();
}

class _WebCalendarScreenState extends State<WebCalendarScreen>
    with TickerProviderStateMixin {
  static const Color primaryColor = Color(0xFF1D449B);
  static const Color accentColor = Color(0xFF25B6E8);

  late final ValueNotifier<List<Evento>> _selectedEvents;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  Map<DateTime, List<Evento>> _events = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _fadeController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fetchEvents();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchEvents() async {
    try {
      final response =
          await http.get(Uri.parse('${ApiConfig.baseUrl}/eventos/'));
      if (response.statusCode == 200) {
        final List<dynamic> data =
            json.decode(utf8.decode(response.bodyBytes));
        final Map<DateTime, List<Evento>> events = {};
        for (var item in data) {
          final evento = Evento.fromJson(item);
          final date = DateTime.utc(
              evento.dataInicio.year, evento.dataInicio.month, evento.dataInicio.day);
          events[date] ??= [];
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

  List<Evento> _getEventsForDay(DateTime day) =>
      _events[DateTime.utc(day.year, day.month, day.day)] ?? [];

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents.value = _getEventsForDay(selectedDay);
      });
    }
  }

  String _capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor)),
            SizedBox(height: 16),
            Text('Carregando eventos...',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(_error!,
            style: const TextStyle(color: Colors.red, fontSize: 16)),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 750;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Calendar
                      Expanded(flex: 3, child: _buildCalendarPanel()),
                      const SizedBox(width: 24),
                      // Right: Event list
                      Expanded(flex: 2, child: _buildEventsPanel()),
                    ],
                  )
                : Column(
                    children: [
                      _buildCalendarPanel(),
                      const SizedBox(height: 24),
                      _buildEventsPanel(),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarPanel() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.transparent,
        ),
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
                  gradient: const LinearGradient(
                      colors: [primaryColor, accentColor]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_month_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Calendário Escolar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TableCalendar<Evento>(
            locale: 'pt_BR',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            eventLoader: _getEventsForDay,
            rowHeight: 48,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : primaryColor,
              ),
              leftChevronIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0x1A1E3A8A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chevron_left,
                  color: isDark ? Colors.white : primaryColor,
                  size: 18,
                ),
              ),
              rightChevronIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0x1A1E3A8A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.white : primaryColor,
                  size: 18,
                ),
              ),
            ),
            daysOfWeekHeight: 36,
            calendarBuilders: CalendarBuilders(
              headerTitleBuilder: (context, date) {
                final title =
                    _capitalize(DateFormat.yMMMM('pt_BR').format(date));
                return Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : primaryColor,
                    ),
                  ),
                );
              },
              dowBuilder: (context, day) {
                final text = DateFormat.E('pt_BR').format(day).toUpperCase();
                final isWeekend = day.weekday == DateTime.sunday ||
                    day.weekday == DateTime.saturday;
                return Center(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isWeekend
                          ? Colors.red
                          : (isDark ? Colors.grey.shade400 : const Color(0xFF475569)),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                );
              },
              markerBuilder: (context, day, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    bottom: 4,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: accentColor, shape: BoxShape.circle),
                    ),
                  );
                }
                return null;
              },
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: true,
              outsideTextStyle: TextStyle(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                fontSize: 13,
              ),
              defaultTextStyle: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
              ),
              weekendTextStyle: const TextStyle(color: Colors.red, fontSize: 13),
              todayDecoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.fromBorderSide(
                  BorderSide(
                    color: isDark ? Colors.white70 : Colors.black,
                    width: 2.0,
                  ),
                ),
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 13,
              ),
              selectedDecoration: const BoxDecoration(
                gradient: LinearGradient(colors: [primaryColor, accentColor]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x661E3A8A),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              selectedTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsPanel() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(minHeight: 300),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.transparent,
        ),
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [primaryColor, accentColor]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.event_rounded,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDay != null
                        ? 'Eventos de ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}'
                        : 'Eventos do dia',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
          ValueListenableBuilder<List<Evento>>(
            valueListenable: _selectedEvents,
            builder: (context, value, _) {
              if (value.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 40,
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhum evento para este dia',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: value.length,
                itemBuilder: (context, index) =>
                    _buildWebEventCard(value[index], isDark),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWebEventCard(Evento evento, [bool isDark = false]) {
    final formatadorHora = DateFormat('HH:mm');
    final String horario;
    if (evento.dataFim != null && evento.dataFim != evento.dataInicio) {
      horario =
          '${formatadorHora.format(evento.dataInicio)} – ${formatadorHora.format(evento.dataFim!)}';
    } else {
      horario = formatadorHora.format(evento.dataInicio);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.transparent,
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ExpansionTile(
          iconColor: isDark ? Colors.grey.shade400 : null,
          collapsedIconColor: isDark ? Colors.grey.shade500 : null,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [primaryColor, accentColor]),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: const Icon(Icons.event_note_rounded,
                color: Colors.white, size: 16),
          ),
          title: Text(
            evento.titulo,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDark ? Colors.white : primaryColor,
            ),
          ),
          subtitle: Text(
            horario,
            style: const TextStyle(
              color: accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          children: [
            if (evento.descricao != null && evento.descricao!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    evento.descricao!,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
