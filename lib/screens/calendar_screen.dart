// lib/screens/calendar_screen.dart
// VERSÃO FINAL CORRIGIDA

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

// Modelo de dados para o evento
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
      dataInicio: DateTime.parse(json['data_inicio']),
      dataFim: json['data_fim'] != null ? DateTime.parse(json['data_fim']) : null,
    );
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key}); // Correção: super.key

  @override
  // Correção: Removido tipo privado _CalendarScreenState
  State<CalendarScreen> createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<List<Evento>> _selectedEvents;
  Map<DateTime, List<Evento>> _events = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _fetchEvents();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<void> _fetchEvents() async {
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
        }
      } else {
        throw Exception('Falha ao carregar eventos');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível carregar os eventos. Verifique sua conexão.';
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
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário Escolar'), // Adicionado const
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Adicionado const
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red))) // Adicionado const
              : Column(
                  children: [
                    TableCalendar<Evento>(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: _onDaySelected,
                      calendarFormat: _calendarFormat,
                      onFormatChanged: (format) {
                        if (_calendarFormat != format) {
                          setState(() {
                            _calendarFormat = format;
                          });
                        }
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                      eventLoader: _getEventsForDay,
                      locale: 'pt_BR',
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Colors.orange.shade200,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: const HeaderStyle( // Adicionado const
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Expanded(
                      child: ValueListenableBuilder<List<Evento>>(
                        valueListenable: _selectedEvents,
                        builder: (context, value, _) {
                          if (value.isEmpty) {
                            return const Center(child: Text('Nenhum evento para este dia.')); // Adicionado const
                          }
                          return ListView.builder(
                            itemCount: value.length,
                            itemBuilder: (context, index) {
                              final evento = value[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0), // Adicionado const
                                decoration: BoxDecoration(
                                  border: Border.all(color: Theme.of(context).primaryColor),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: ListTile(
                                  title: Text(evento.titulo),
                                  subtitle: evento.descricao != null ? Text(evento.descricao!) : null,
                                  trailing: Text(DateFormat('HH:mm').format(evento.dataInicio)),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
