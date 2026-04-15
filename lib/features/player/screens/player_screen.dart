import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/theme/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  final String mood;
  const PlayerScreen({super.key, required this.mood});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  late AnimationController _rotationController;
  bool _isPlaying = false;

  // Mood-based sample tracks (YouTube Audio Library free tracks)
  final Map<String, List<Map<String, String>>> _moodTracks = {
    'Happy': [
      {'title': 'Sunny Day', 'artist': 'MoodScape Radio'},
      {'title': 'Feel Good Vibes', 'artist': 'MoodScape Radio'},
    ],
    'Sad': [
      {'title': 'Gentle Rain', 'artist': 'MoodScape Radio'},
      {'title': 'Blue Hour', 'artist': 'MoodScape Radio'},
    ],
    'Calm': [
      {'title': 'Still Waters', 'artist': 'MoodScape Radio'},
      {'title': 'Peaceful Mind', 'artist': 'MoodScape Radio'},
    ],
    'Angry': [
      {'title': 'Release', 'artist': 'MoodScape Radio'},
      {'title': 'Power Through', 'artist': 'MoodScape Radio'},
    ],
    'Nutcracker': [
      {'title': 'Dance of the Sugar Plum', 'artist': 'Tchaikovsky'},
      {'title': 'March', 'artist': 'Tchaikovsky'},
    ],
  };

  int _currentTrackIndex = 0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _rotationController.stop();
  }

  @override
  void dispose() {
    _player.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }
  }

  void _nextTrack() {
    final tracks = _moodTracks[widget.mood] ?? [];
    setState(() {
      _currentTrackIndex = (_currentTrackIndex + 1) % tracks.length;
    });
  }

  void _prevTrack() {
    final tracks = _moodTracks[widget.mood] ?? [];
    setState(() {
      _currentTrackIndex =
          (_currentTrackIndex - 1 + tracks.length) % tracks.length;
    });
  }

  Map<String, Color> get _moodColors => {
        'Happy': const Color(0xFFFFD54F),
        'Sad': const Color(0xFF90CAF9),
        'Calm': const Color(0xFFA5D6A7),
        'Angry': const Color(0xFFEF9A9A),
        'Nutcracker': const Color(0xFFCE93D8),
      };

  Map<String, String> get _moodEmojis => {
        'Happy': '😊',
        'Sad': '😢',
        'Calm': '😌',
        'Angry': '😤',
        'Nutcracker': '🎄',
      };

  @override
  Widget build(BuildContext context) {
    final tracks = _moodTracks[widget.mood] ?? [];
    final currentTrack = tracks.isNotEmpty
        ? tracks[_currentTrackIndex]
        : {'title': 'No Track', 'artist': ''};
    final moodColor = _moodColors[widget.mood] ?? AppColors.accent;
    final moodEmoji = _moodEmojis[widget.mood] ?? '🎵';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              moodColor.withOpacity(0.4),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        '${widget.mood} Mood',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Album art
              AnimatedBuilder(
                animation: _rotationController,
                builder: (_, child) => Transform.rotate(
                  angle: _rotationController.value * 2 * 3.14159,
                  child: child,
                ),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: moodColor.withOpacity(0.3),
                    border: Border.all(color: moodColor, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: moodColor.withOpacity(0.4),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(moodEmoji,
                        style: const TextStyle(fontSize: 80)),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Track info
              Text(
                currentTrack['title'] ?? '',
                style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark),
              ),
              const SizedBox(height: 6),
              Text(
                currentTrack['artist'] ?? '',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: AppColors.textMedium),
              ),

              const SizedBox(height: 32),

              // Progress bar (visual only)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.accent.withOpacity(0.3),
                        thumbColor: AppColors.primary,
                        trackHeight: 4,
                      ),
                      child: Slider(value: 0.3, onChanged: (_) {}),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('1:02',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: AppColors.textMedium)),
                          Text('3:24',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: AppColors.textMedium)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 36,
                    icon: const Icon(Icons.skip_previous_rounded,
                        color: AppColors.primary),
                    onPressed: _prevTrack,
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    iconSize: 36,
                    icon: const Icon(Icons.skip_next_rounded,
                        color: AppColors.primary),
                    onPressed: _nextTrack,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}