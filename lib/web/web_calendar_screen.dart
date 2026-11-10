// lib/web/web_calendar_screen.dart
// Calendário Escolar Web: Layout Master-Detail de 2 Colunas (flex 6 : flex 5) ocupando 100% da área útil.

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
      id: json['id'].toString(),
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'],
      dataInicio: DateTime.parse(json['data_inicio']).toLocal(),
      dataFim: json['data_fim'] != null
          ? DateTime.parse(json['data_fim']).toLocal()
          : null,
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
  List<Evento> _allEventsSorted = [];
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
      duration: const Duration(milliseconds: 450),
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
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response =
          await http.get(Uri.parse('${ApiConfig.baseUrl}/eventos/'));
      if (response.statusCode == 200) {
        final List<dynamic> data =
            json.decode(utf8.decode(response.bodyBytes));
        final Map<DateTime, List<Evento>> events = {};
        final List<Evento> flatList = [];
        for (var item in data) {
          final evento = Evento.fromJson(item);
          flatList.add(evento);
          final date = DateTime.utc(
            evento.dataInicio.year,
            evento.dataInicio.month,
            evento.dataInicio.day,
          );
          events[date] ??= [];
          events[date]!.add(evento);
        }
        flatList.sort((a, b) => a.dataInicio.compareTo(b.dataInicio));

        if (mounted) {
          setState(() {
            _events = events;
            _allEventsSorted = flatList;
            _isLoading = false;
          });
          _selectedEvents.value = _getEventsForDay(_selectedDay!);
          _fadeController.forward(from: 0.0);
        }
      } else {
        throw Exception('Falha ao carregar eventos');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível carregar os eventos do calendário.';
          _isLoading = false;
        });
      }
    }
  }

  List<Evento> _getEventsForDay(DateTime day) =>
      _events[DateTime.utc(day.year, day.month, day.day)] ?? [];

  List<Evento> _getEventsForMonth(DateTime monthDay) {
    final list = _allEventsSorted
        .where((e) =>
            e.dataInicio.year == monthDay.year &&
            e.dataInicio.month == monthDay.month)
        .toList();
    list.sort((a, b) => a.dataInicio.compareTo(b.dataInicio));
    return list;
  }

  List<Evento> _getUpcomingEvents() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // 1. Eventos a partir de hoje
    final upcoming = _allEventsSorted
        .where((e) => !e.dataInicio.isBefore(todayStart))
        .toList();
    if (upcoming.isNotEmpty) {
      return upcoming.take(8).toList();
    }

    // 2. Fallback: eventos do mês focado ou últimos eventos do ano
    final monthEvents = _getEventsForMonth(_focusedDay);
    if (monthEvents.isNotEmpty) {
      return monthEvents;
    }

    return _allEventsSorted.reversed.take(8).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedEvents.value = _getEventsForDay(selectedDay);
    });
  }

  String _capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
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
              'Carregando calendário escolar...',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchEvents,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 820;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Coluna Esquerda (flex: 6) -> TableCalendar + Rodapé/Legenda
                      Expanded(
                        flex: 6,
                        child: _buildCalendarMasterCard(isDark),
                      ),
                      const SizedBox(width: 24),
                      // Coluna Direita (flex: 5) -> Eventos do Dia + Próximos Eventos
                      Expanded(
                        flex: 5,
                        child: _buildRightDetailColumn(isDark),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCalendarMasterCard(isDark),
                      const SizedBox(height: 24),
                      _buildRightDetailColumn(isDark),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // COLUNA ESQUERDA (flex: 6): Card amplo com TableCalendar + Rodapé de Legenda
  // ===========================================================================

  Widget _buildCalendarMasterCard(bool isDark) {
    final monthEvents = _getEventsForMonth(_focusedDay);
    final monthName =
        _capitalize(DateFormat.MMMM('pt_BR').format(_focusedDay));
    final daysWithEventsCount = monthEvents
        .map((e) =>
            DateTime.utc(e.dataInicio.year, e.dataInicio.month, e.dataInicio.day))
        .toSet()
        .length;

    return Container(
      padding: const EdgeInsets.all(28),
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
          // Cabeçalho do Card
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryColor, accentColor],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calendário Escolar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : primaryColor,
                      ),
                    ),
                    Text(
                      'Selecione uma data para consultar os compromissos e atividades letivas',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // TableCalendar amplo e espaçado
          TableCalendar<Evento>(
            locale: 'pt_BR',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getEventsForDay,
            rowHeight: 58,
            daysOfWeekHeight: 42,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              headerPadding: const EdgeInsets.symmetric(vertical: 8),
              leftChevronIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: isDark ? Colors.white : primaryColor,
                  size: 20,
                ),
              ),
              rightChevronIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white : primaryColor,
                  size: 20,
                ),
              ),
            ),
            calendarBuilders: CalendarBuilders(
              headerTitleBuilder: (context, date) {
                final title =
                    _capitalize(DateFormat.yMMMM('pt_BR').format(date));
                return Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
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
                          ? const Color(0xFFEF4444)
                          : (isDark
                              ? Colors.grey.shade400
                              : const Color(0xFF475569)),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
              markerBuilder: (context, day, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    bottom: 6,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: events.take(3).map((_) {
                        return Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: const BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }
                return null;
              },
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: true,
              cellMargin: const EdgeInsets.all(6),
              outsideTextStyle: TextStyle(
                color: isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFFCBD5E1),
                fontSize: 14,
              ),
              defaultTextStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
              weekendTextStyle: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.fromBorderSide(
                  BorderSide(
                    color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                    width: 2.0,
                  ),
                ),
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
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
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(height: 20),
          Divider(
            height: 1,
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
          const SizedBox(height: 16),

          // Rodapé com legenda e resumo de eventos no mês selecionado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLegendItem(
                      isDark: isDark,
                      label: 'Dia selecionado',
                      indicator: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              colors: [primaryColor, accentColor]),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildLegendItem(
                      isDark: isDark,
                      label: 'Hoje',
                      indicator: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isDark ? const Color(0xFF60A5FA) : primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildLegendItem(
                      isDark: isDark,
                      label: 'Possui evento',
                      indicator: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF3B82F6) : primaryColor)
                        .withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_note_rounded,
                        size: 15,
                        color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${monthEvents.length} ${monthEvents.length == 1 ? 'evento' : 'eventos'} em $monthName ($daysWithEventsCount ${daysWithEventsCount == 1 ? 'dia' : 'dias'})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? const Color(0xFF60A5FA) : primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required bool isDark,
    required String label,
    required Widget indicator,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // COLUNA DIREITA (flex: 5):
  //   1. Eventos do Dia Selecionado
  //   2. Próximos Eventos do Calendário Escolar
  // ===========================================================================

  Widget _buildRightDetailColumn(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSelectedDayEventsSection(isDark),
        const SizedBox(height: 24),
        _buildUpcomingEventsSection(isDark),
      ],
    );
  }

  Widget _buildSelectedDayEventsSection(bool isDark) {
    final selectedDateStr = _selectedDay != null
        ? DateFormat('dd/MM/yyyy').format(_selectedDay!)
        : '';
    final dayOfWeekStr = _selectedDay != null
        ? _capitalize(DateFormat('EEEE', 'pt_BR').format(_selectedDay!))
        : '';

    return Container(
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
                  gradient: const LinearGradient(
                    colors: [primaryColor, accentColor],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.event_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Eventos de $selectedDateStr',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : primaryColor,
                      ),
                    ),
                    if (dayOfWeekStr.isNotEmpty)
                      Text(
                        dayOfWeekStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              ValueListenableBuilder<List<Evento>>(
                valueListenable: _selectedEvents,
                builder: (context, events, _) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: events.isNotEmpty
                          ? accentColor.withAlpha(30)
                          : (isDark
                              ? const Color(0xFF334155)
                              : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${events.length} ${events.length == 1 ? 'evento' : 'eventos'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: events.isNotEmpty
                            ? accentColor
                            : (isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<List<Evento>>(
            valueListenable: _selectedEvents,
            builder: (context, value, _) {
              if (value.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.grey.shade200.withAlpha(140),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.event_busy_rounded,
                          size: 24,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nenhum evento para esta data',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Selecione outro dia no calendário ou confira abaixo os próximos eventos.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: value
                    .map((evento) => _buildDetailedDayEventCard(evento, isDark))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedDayEventCard(Evento evento, bool isDark) {
    final formatadorHora = DateFormat('HH:mm');
    final String horario;
    if (evento.dataFim != null && evento.dataFim != evento.dataInicio) {
      horario =
          '${formatadorHora.format(evento.dataInicio)} – ${formatadorHora.format(evento.dataFim!)}';
    } else {
      horario = formatadorHora.format(evento.dataInicio);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [primaryColor, accentColor]),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  evento.titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : primaryColor,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 13, color: accentColor),
                    const SizedBox(width: 4),
                    Text(
                      horario,
                      style: const TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (evento.descricao != null &&
              evento.descricao!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              evento.descricao!,
              style: TextStyle(
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsSection(bool isDark) {
    final upcomingEvents = _getUpcomingEvents();

    return Container(
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
                  color: const Color(0xFF3B82F6).withAlpha(isDark ? 35 : 20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.upcoming_rounded,
                  color: isDark ? const Color(0xFF60A5FA) : primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Próximos Eventos do Calendário Escolar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : primaryColor,
                      ),
                    ),
                    Text(
                      'Cronograma de atividades e datas importantes',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
          const SizedBox(height: 16),
          if (upcomingEvents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Nenhum evento cadastrado no calendário escolar.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ),
            )
          else
            Column(
              children: upcomingEvents
                  .map((evento) => _buildUpcomingEventTile(evento, isDark))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventTile(Evento evento, bool isDark) {
    final dayNum = DateFormat('dd').format(evento.dataInicio);
    final monthShort =
        DateFormat('MMM', 'pt_BR').format(evento.dataInicio).toUpperCase();
    final timeStr = DateFormat('HH:mm').format(evento.dataInicio);
    final isSelectedDate =
        _selectedDay != null && isSameDay(_selectedDay, evento.dataInicio);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelectedDate
            ? (isDark
                ? const Color(0xFF1E3A8A).withAlpha(55)
                : const Color(0xFFF0F7FF))
            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelectedDate
              ? (isDark ? const Color(0xFF60A5FA) : primaryColor)
              : (isDark ? Colors.white12 : Colors.grey.shade200),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onDaySelected(evento.dataInicio, evento.dataInicio),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient:
                        const LinearGradient(colors: [primaryColor, accentColor]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        dayNum,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        monthShort,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        evento.titulo,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (evento.descricao != null &&
                          evento.descricao!.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          evento.descricao!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded,
                              size: 12, color: accentColor),
                          const SizedBox(width: 4),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
