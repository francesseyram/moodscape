import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<String, Color> _moodColors = {
    'Happy': const Color(0xFFFFD54F),
    'Sad': const Color(0xFF90CAF9),
    'Calm': const Color(0xFFA5D6A7),
    'Angry': const Color(0xFFEF9A9A),
    'Nutcracker': const Color(0xFFCE93D8),
  };

  List<Map<String, dynamic>> get _logs {
    final box = Hive.box('moodLogs');
    return box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
        .reversed
        .toList();
  }

  Map<String, int> get _moodCounts {
    final counts = <String, int>{};
    for (final log in _logs) {
      final mood = log['mood'] as String? ?? '';
      counts[mood] = (counts[mood] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood History'),
        automaticallyImplyLeading: false,
      ),
      body: _logs.isEmpty
          ? Center(
              child: Text('No mood history yet 🌸\nStart by selecting a mood!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 15, color: AppColors.textMedium)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Mood Calendar',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.accent.withOpacity(0.2)),
                    ),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2024, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _selectedDay = selected;
                          _focusedDay = focused;
                        });
                      },
                      calendarStyle: CalendarStyle(
                        selectedDecoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        defaultTextStyle:
                            GoogleFonts.poppins(fontSize: 13),
                        weekendTextStyle: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.primaryLight),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary),
                        leftChevronIcon: const Icon(Icons.chevron_left,
                            color: AppColors.primary),
                        rightChevronIcon: const Icon(Icons.chevron_right,
                            color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Mood breakdown chart
                  Text('Mood Breakdown',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark)),
                  const SizedBox(height: 16),
                  if (_moodCounts.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.accent.withOpacity(0.2)),
                      ),
                      child: SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: (_moodCounts.values.isNotEmpty
                                    ? _moodCounts.values.reduce(
                                        (a, b) => a > b ? a : b)
                                    : 1)
                                .toDouble() + 1,
                            barTouchData: BarTouchData(enabled: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (val, _) {
                                    final moods = _moodCounts.keys.toList();
                                    if (val.toInt() >= moods.length) {
                                      return const SizedBox();
                                    }
                                    return Text(
                                      _moodEmoji(moods[val.toInt()]),
                                      style: const TextStyle(fontSize: 18),
                                    );
                                  },
                                ),
                              ),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: _moodCounts.entries
                                .toList()
                                .asMap()
                                .entries
                                .map((e) => BarChartGroupData(
                                      x: e.key,
                                      barRods: [
                                        BarChartRodData(
                                          toY: e.value.value.toDouble(),
                                          color: _moodColors[
                                                  e.value.key] ??
                                              AppColors.accent,
                                          width: 28,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ],
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),

                  // Recent logs
                  Text('Recent Logs',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark)),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _logs.take(10).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final log = _logs[i];
                      final time =
                          DateTime.tryParse(log['timestamp'] ?? '');
                      final timeStr = time != null
                          ? DateFormat('MMM d · h:mm a').format(time)
                          : '';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.accent.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Text(_moodEmoji(log['mood'] ?? ''),
                                style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(log['mood'] ?? '',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                            ),
                            Text(timeStr,
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppColors.textMedium)),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  String _moodEmoji(String mood) {
    switch (mood) {
      case 'Happy': return '😊';
      case 'Sad': return '😢';
      case 'Calm': return '😌';
      case 'Angry': return '😤';
      case 'Nutcracker': return '🎄';
      default: return '🌸';
    }
  }
}