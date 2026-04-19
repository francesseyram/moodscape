import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/mood_model.dart';
import '../../../data/services/mood_service.dart';
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

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  List<MoodModel> _moods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMoods();
  }

  Future<void> _loadMoods() async {
    final moods = await MoodService.getMoods();
    if (mounted) {
      setState(() {
        _moods = moods;
        _isLoading = false;
      });
    }
  }

  Future<void> _logMood(BuildContext context, MoodModel mood) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final log = {
      'uid': user.uid,
      'moodId': mood.id,
      'mood': mood.label,
      'emoji': mood.emoji,
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
        MaterialPageRoute(
          builder: (_) => PlayerScreen(mood: mood),
        ),
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
            // Header
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
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'M',
                          style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Banner
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

            // Mood grid
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary))
                : _moods.isEmpty
                    ? Center(
                        child: Text('Could not load moods 🌸',
                            style: GoogleFonts.poppins(
                                color: AppColors.textMedium)))
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: _moods.length,
                        itemBuilder: (context, i) {
                          final mood = _moods[i];
                          return _MoodCard(
                            mood: mood,
                            onTap: () => _logMood(context, mood),
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
  final MoodModel mood;
  final VoidCallback onTap;

  const _MoodCard({required this.mood, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: mood.bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: mood.color.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: mood.color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 42)),
            const SizedBox(height: 10),
            Text(mood.label,
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('moodLogs')
          .orderBy('timestamp', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
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
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textMedium),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final mood = data['mood'] ?? '';
            final emoji = data['emoji'] ?? '🌸';
            final timestamp = data['timestamp'];
            String timeStr = '';
            if (timestamp is Timestamp) {
              timeStr = DateFormat('h:mm a').format(timestamp.toDate());
            }

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
      },
    );
  }
}