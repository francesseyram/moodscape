import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  Map<String, int> _getMoodCounts(List<QueryDocumentSnapshot> docs) {
    final counts = <String, int>{};
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final mood = data['mood'] as String? ?? '';
      counts[mood] = (counts[mood] ?? 0) + 1;
    }
    return counts;
  }

  List<QueryDocumentSnapshot> _getLogsForDay(
      List<QueryDocumentSnapshot> docs, DateTime day) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['timestamp'];
      if (ts is Timestamp) {
        final date = ts.toDate();
        return date.year == day.year &&
            date.month == day.month &&
            date.day == day.day;
      }
      return false;
    }).toList();
  }

  Color? _getDayColor(
      List<QueryDocumentSnapshot> docs, DateTime day) {
    final dayLogs = _getLogsForDay(docs, day);
    if (dayLogs.isEmpty) return null;
    final data = dayLogs.last.data() as Map<String, dynamic>;
    return _moodColors[data['mood']] ?? AppColors.accent;
  }

  Future<void> _deleteMoodLog(
      BuildContext context, String uid, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Mood Log',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: AppColors.primary)),
        content: Text(
            'Are you sure you want to delete this mood log?',
            style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    color: AppColors.textMedium)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('moodLogs')
          .doc(docId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mood log deleted 🌸'),
            backgroundColor: AppColors.primaryLight,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood History'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('moodLogs')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Text(
                'No mood history yet 🌸\nStart by selecting a mood!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 15, color: AppColors.textMedium),
              ),
            );
          }

          final moodCounts = _getMoodCounts(docs);
          final selectedDayLogs = _selectedDay != null
              ? _getLogsForDay(docs, _selectedDay!)
              : [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calendar
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
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        final color = _getDayColor(docs, day);
                        if (color == null) return null;
                        return Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('${day.day}',
                                style:
                                    GoogleFonts.poppins(fontSize: 13)),
                          ),
                        );
                      },
                    ),
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
                          fontSize: 13,
                          color: AppColors.primaryLight),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary),
                      leftChevronIcon: const Icon(
                          Icons.chevron_left,
                          color: AppColors.primary),
                      rightChevronIcon: const Icon(
                          Icons.chevron_right,
                          color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Selected day logs
                if (_selectedDay != null &&
                    selectedDayLogs.isNotEmpty) ...[
                  Text(
                    DateFormat('MMMM d, yyyy').format(_selectedDay!),
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  ...selectedDayLogs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final mood = data['mood'] ?? '';
                    final emoji = data['emoji'] ?? '🌸';
                    final ts = data['timestamp'];
                    final timeStr = ts is Timestamp
                        ? DateFormat('h:mm a').format(ts.toDate())
                        : '';
                    return Dismissible(
                      key: Key('selected_${doc.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white, size: 24),
                      ),
                      confirmDismiss: (_) =>
                          _deleteMoodLog(context, user.uid, doc.id)
                              .then((_) => false),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color:
                                  AppColors.accent.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Text(emoji,
                                style:
                                    const TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(mood,
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                            ),
                            Text(timeStr,
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppColors.textMedium)),
                            const SizedBox(width: 8),
                            const Icon(Icons.swipe_left,
                                size: 14,
                                color: AppColors.textLight),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                // Mood breakdown chart
                Text('Mood Breakdown',
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
                const SizedBox(height: 16),
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
                        maxY: (moodCounts.values.isNotEmpty
                                ? moodCounts.values.reduce(
                                    (a, b) => a > b ? a : b)
                                : 1)
                            .toDouble() + 1,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                              sideTitles:
                                  SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles:
                                  SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles:
                                  SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, _) {
                                final moods =
                                    moodCounts.keys.toList();
                                if (val.toInt() >= moods.length) {
                                  return const SizedBox();
                                }
                                return Text(
                                  _moodEmoji(moods[val.toInt()]),
                                  style: const TextStyle(
                                      fontSize: 18),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: moodCounts.entries
                            .toList()
                            .asMap()
                            .entries
                            .map((e) => BarChartGroupData(
                                  x: e.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: e.value.value
                                          .toDouble(),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Logs',
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark)),
                    Text('Swipe left to delete',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textLight,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.take(10).length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final mood = data['mood'] ?? '';
                    final emoji = data['emoji'] ?? '🌸';
                    final ts = data['timestamp'];
                    final timeStr = ts is Timestamp
                        ? DateFormat('MMM d · h:mm a')
                            .format(ts.toDate())
                        : '';

                    return Dismissible(
                      key: Key(doc.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white, size: 24),
                      ),
                      confirmDismiss: (_) =>
                          _deleteMoodLog(context, user.uid, doc.id)
                              .then((_) => false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color:
                                  AppColors.accent.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Text(emoji,
                                style:
                                    const TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(mood,
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                            ),
                            Text(timeStr,
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppColors.textMedium)),
                            const SizedBox(width: 8),
                            const Icon(Icons.swipe_left,
                                size: 14,
                                color: AppColors.textLight),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}