import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/mood_model.dart';
import '../../../data/models/track_model.dart';
import '../../../data/services/mood_service.dart';

class PlayerScreen extends StatefulWidget {
  final MoodModel mood;
  const PlayerScreen({super.key, required this.mood});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  late AnimationController _rotationController;
  List<TrackModel> _tracks = [];
  int _currentTrackIndex = 0;
  bool _isLoading = true;
  bool _isBuffering = false;
  String _quote = '';
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    _setupPlayerListeners();
    _loadData();
  }

  void _setupPlayerListeners() {
    _player.playingStream.listen((playing) {
      if (!mounted) return;
      if (playing) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
      setState(() {});
    });

    _player.durationStream.listen((duration) {
      if (mounted) setState(() => _duration = duration ?? Duration.zero);
    });

    _player.positionStream.listen((position) {
      if (mounted) setState(() => _position = position);
    });

    _player.processingStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _isBuffering =
          state == ProcessingState.buffering ||
          state == ProcessingState.loading);
      if (state == ProcessingState.completed) _nextTrack();
    });
  }

  Future<void> _loadData() async {
    final tracks = await MoodService.getTracksForMood(widget.mood.id);
    final quote = await MoodService.getQuoteForMood(widget.mood.id);
    print('🎵 Loaded ${tracks.length} tracks for ${widget.mood.id}');
    for (final t in tracks) {
      print('   → ${t.title} | URL: ${t.storageUrl}');
    }
    if (mounted) {
      setState(() {
        _tracks = tracks;
        _quote = quote;
        _isLoading = false;
      });
      if (tracks.isNotEmpty) await _loadTrack(0);
    }
  }

  Future<void> _loadTrack(int index) async {
    final track = _tracks[index];
    if (track.storageUrl.isEmpty) {
      print('❌ storageUrl is empty for: ${track.title}');
      return;
    }
    print('🎵 Loading: ${track.storageUrl}');
    try {
      await _player.setUrl(track.storageUrl);
      print('✅ Track loaded!');
    } catch (e) {
      print('❌ Error loading track: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load: ${track.title}')),
        );
      }
    }
  }

  Future<void> _togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> _nextTrack() async {
    if (_tracks.isEmpty) return;
    final next = (_currentTrackIndex + 1) % _tracks.length;
    setState(() => _currentTrackIndex = next);
    await _loadTrack(next);
    await _player.play();
  }

  Future<void> _prevTrack() async {
    if (_tracks.isEmpty) return;
    final prev = (_currentTrackIndex - 1 + _tracks.length) % _tracks.length;
    setState(() => _currentTrackIndex = prev);
    await _loadTrack(prev);
    await _player.play();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTrack =
        _tracks.isNotEmpty ? _tracks[_currentTrackIndex] : null;
    final isPlaying = _player.playing;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.mood.color.withOpacity(0.4),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: AppColors.primary),
                      onPressed: () {
                        _player.stop();
                        Navigator.pop(context);
                      },
                    ),
                    Expanded(
                      child: Text(
                        '${widget.mood.emoji} ${widget.mood.label} Mood',
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

              const SizedBox(height: 24),

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
                    color: widget.mood.color.withOpacity(0.3),
                    border:
                        Border.all(color: widget.mood.color, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: widget.mood.color.withOpacity(0.4),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(widget.mood.emoji,
                        style: const TextStyle(fontSize: 80)),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Quote
              if (_quote.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    '"$_quote"',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textMedium,
                        fontStyle: FontStyle.italic),
                  ),
                ),

              const SizedBox(height: 24),

              // Track info
              _isLoading
                  ? const CircularProgressIndicator(
                      color: AppColors.primary)
                  : Column(
                      children: [
                        Text(
                          currentTrack?.title ?? 'No tracks available',
                          style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentTrack?.artist ?? '',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.textMedium),
                        ),
                      ],
                    ),

              const SizedBox(height: 24),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor:
                            AppColors.accent.withOpacity(0.3),
                        thumbColor: AppColors.primary,
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _duration.inSeconds > 0
                            ? (_position.inSeconds /
                                    _duration.inSeconds)
                                .clamp(0.0, 1.0)
                            : 0.0,
                        onChanged: (value) {
                          final newPos = Duration(
                              seconds:
                                  (value * _duration.inSeconds).round());
                          _player.seek(newPos);
                        },
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(_position),
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textMedium)),
                          Text(_formatDuration(_duration),
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textMedium)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

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
                      child: _isBuffering
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 3),
                            )
                          : Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
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