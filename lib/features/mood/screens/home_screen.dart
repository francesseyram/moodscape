import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../player/screens/player_screen.dart';
import '../../journal/screens/journal_screen.dart';
import '../../history/screens/history_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../shared/widgets/bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _HomeTab(),
    JournalScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: MoodScapeBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  final List<Map<String, dynamic>> moods = const [
    {'label': 'Happy', 'emoji': '😊', 'color': Color(0xFFFFD54F), 'bg': Color(0xFFFFFDE7)},
    {'label': 'Sad', 'emoji': '😢', 'color': Color(0xFF90CAF9), 'bg': Color(0xFFE3F2FD)},
    {'label': 'Calm', 'emoji': '😌', 'color': Color(0xFFA5D6A7), 'bg': Color(0xFFE8F5E9)},
    {'label': 'Angry', 'emoji': '😤', 'color': Color(0xFFEF9A9A), 'bg': Color(0xFFFFEBEE)},
    {'label': 'Nutcracker', 'emoji': '🎄', 'color': Color(0xFFCE93D8), 'bg': Color(0xFFF3E5F5)},
  ];

  Future<void> _logMood(BuildContext context, String mood) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final log = {
      'uid': user.uid,
      'mood': mood,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Save locally
    final box = Hive.box('moodLogs');
    await box.add(log);

    // Save to Firestore
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('moodLogs')
          .add({...log, 'timestamp': FieldValue.serverTimestamp()});
    } catch (_) {}

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlayerScreen(mood: mood)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final greeting = _getGreeting();
    final name = user?.displayName?.split(' ').first ?? 'Beautiful';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting,
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: AppColors.textMedium)),
                    Text(name,
                        style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ],
                ),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.cardPink,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'M',
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFAD1457), Color(0xFFE91E8C)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('How are you feeling?',
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('Pick a mood and let the music flow 🎵',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                  const Text('🎧', style: TextStyle(fontSize: 40)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('Select Your Mood',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.1,
              ),
              itemCount: moods.length,
              itemBuilder: (context, i) {
                final mood = moods[i];
                return _MoodCard(
                  label: mood['label'],
                  emoji: mood['emoji'],
                  color: mood['color'],
                  bg: mood['bg'],
                  onTap: () => _logMood(context, mood['label']),
                );
              },
            ),
            const SizedBox(height: 28),
            Text('Today',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
            const SizedBox(height: 12),
            _RecentMoodCard(),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }
}

class _MoodCard extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _MoodCard({
    required this.label,
    required this.emoji,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 42)),
            const SizedBox(height: 10),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
          ],
        ),
      ),
    );
  }
}

class _RecentMoodCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final box = Hive.box('moodLogs');
    final logs = box.values.toList().reversed.take(3).toList();

    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            'No mood logs yet — pick a mood above! 🌸',
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMedium),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: logs.map((log) {
        final map = Map<String, dynamic>.from(log as Map);
        final mood = map['mood'] ?? '';
        final time = DateTime.tryParse(map['timestamp'] ?? '');
        final timeStr = time != null ? DateFormat('h:mm a').format(time) : '';
        final emoji = _moodEmoji(mood);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accent.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(mood,
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ),
              Text(timeStr,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textMedium)),
            ],
          ),
        );
      }).toList(),
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