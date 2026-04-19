import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _textController = TextEditingController();
  String _selectedMood = 'Happy';
  File? _selectedImage;
  String? _locationText;
  double? _latitude;
  double? _longitude;
  bool _isSaving = false;
  bool _isLoadingLocation = false;

  // Speech to text
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';

  final List<Map<String, String>> _moods = const [
    {'label': 'Happy', 'emoji': '😊'},
    {'label': 'Sad', 'emoji': '😢'},
    {'label': 'Calm', 'emoji': '😌'},
    {'label': 'Angry', 'emoji': '😤'},
    {'label': 'Nutcracker', 'emoji': '🎄'},
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (error) => print('Speech error: $error'),
    );
    setState(() {});
  }

  Future<void> _toggleListening() async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Speech recognition not available 🌸')),
      );
      return;
    }

    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    } else {
      _lastWords = _textController.text;
      setState(() => _isListening = true);

      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            if (_lastWords.isEmpty) {
              _textController.text = result.recognizedWords;
            } else {
              _textController.text =
                  '$_lastWords ${result.recognizedWords}';
            }
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: _textController.text.length),
            );
          });
          if (result.finalResult) {
            _lastWords = _textController.text;
          }
        },
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 4),
        localeId: 'en_US',
        listenMode: ListenMode.dictation,
      );

      _speechToText.statusListener = (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      };
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _speechToText.cancel();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _getLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final permissionStatus = await Permission.location.request();
      if (!permissionStatus.isGranted) {
        setState(() => _locationText = 'Location permission denied');
        setState(() => _isLoadingLocation = false);
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationText = 'Please enable location services');
        setState(() => _isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      _latitude = position.latitude;
      _longitude = position.longitude;

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final parts = [
            place.subLocality,
            place.locality,
            place.country,
          ].where((p) => p != null && p.isNotEmpty).toList();
          setState(() => _locationText = parts.join(', '));
        } else {
          setState(() => _locationText =
              '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}');
        }
      } catch (_) {
        setState(() => _locationText =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}');
      }
    } catch (e) {
      setState(() => _locationText = 'Could not get location');
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<String?> _uploadPhoto(File image) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/${user.uid}/journal/$fileName');

      final uploadTask = await ref.putFile(
        image,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('❌ Photo upload failed: $e');
      return null;
    }
  }

  Future<void> _saveEntry() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please write or speak something first 🌸')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    String? photoUrl;

    if (_selectedImage != null) {
      photoUrl = await _uploadPhoto(_selectedImage!);
    }

    final entry = {
      'uid': user?.uid ?? '',
      'mood': _selectedMood,
      'text': _textController.text.trim(),
      'location': _locationText ?? '',
      'latitude': _latitude,
      'longitude': _longitude,
      'photoUrl': photoUrl ?? '',
      'timestamp': DateTime.now().toIso8601String(),
    };

    final box = Hive.box('journalEntries');
    await box.add(entry);

    try {
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('journalEntries')
            .add({
          ...entry,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('❌ Firestore save error: $e');
    }

    setState(() {
      _isSaving = false;
      _textController.clear();
      _selectedImage = null;
      _locationText = null;
      _latitude = null;
      _longitude = null;
      _lastWords = '';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Journal entry saved! 🌸'),
          backgroundColor: AppColors.primaryLight,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Journal'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('EEEE, MMMM d').format(DateTime.now()),
                style: GoogleFonts.poppins(
                    fontSize: 14, color: AppColors.textMedium)),
            const SizedBox(height: 4),
            Text('How was your day?',
                style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
            const SizedBox(height: 20),

            // Mood selector
            Text('Mood',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
            const SizedBox(height: 10),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _moods.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final mood = _moods[i];
                  final selected = mood['label'] == _selectedMood;
                  return GestureDetector(
                    onTap: () => setState(
                        () => _selectedMood = mood['label']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.accent
                                    .withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Text(mood['emoji']!,
                              style:
                                  const TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Text(mood['label']!,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textDark)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Write section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Write',
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
                GestureDetector(
                  onTap: _toggleListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isListening
                          ? AppColors.primary
                          : AppColors.cardPink,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _isListening
                              ? AppColors.primary
                              : AppColors.accent
                                  .withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isListening
                              ? Icons.mic
                              : Icons.mic_none,
                          color: _isListening
                              ? Colors.white
                              : AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isListening
                              ? 'Listening...'
                              : 'Speak',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _isListening
                                  ? Colors.white
                                  : AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Text field
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isListening
                          ? AppColors.primary
                          : AppColors.accent.withOpacity(0.3),
                      width: _isListening ? 2 : 1,
                    ),
                  ),
                  child: TextField(
                    controller: _textController,
                    maxLines: 7,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: _isListening
                          ? 'Listening... speak now 🎤'
                          : 'Express yourself freely or tap Speak to use your voice 🌸',
                      hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textLight),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                if (_isListening)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: _PulsingMic(),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Add to entry
            Text('Add to Entry',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
            const SizedBox(height: 12),
            Row(
              children: [
                _ActionButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  onTap: _takePhoto,
                ),
                const SizedBox(width: 10),
                _ActionButton(
                  icon: Icons.photo_outlined,
                  label: 'Gallery',
                  onTap: _pickImage,
                ),
                const SizedBox(width: 10),
                _ActionButton(
                  icon: _isLoadingLocation
                      ? Icons.hourglass_empty
                      : Icons.location_on_outlined,
                  label: _isLoadingLocation
                      ? 'Loading...'
                      : 'Location',
                  onTap: _getLocation,
                ),
              ],
            ),

            // Image preview
            if (_selectedImage != null) ...[
              const SizedBox(height: 16),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_selectedImage!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 16, color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Location tag
            if (_locationText != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardPink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(_locationText!,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.primary)),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _locationText = null;
                        _latitude = null;
                        _longitude = null;
                      }),
                      child: const Icon(Icons.close,
                          size: 14, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Save button
            _isSaving
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary))
                : ElevatedButton.icon(
                    onPressed: _saveEntry,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Entry'),
                  ),

            const SizedBox(height: 32),

            // Past entries
            Text('Past Entries',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
            const SizedBox(height: 12),
            _PastEntriesList(),
          ],
        ),
      ),
    );
  }
}

// Pulsing mic animation
class _PulsingMic extends StatefulWidget {
  @override
  State<_PulsingMic> createState() => _PulsingMicState();
}

class _PulsingMicState extends State<_PulsingMic>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation =
        Tween<double>(begin: 0.8, end: 1.2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.mic,
            color: AppColors.primary, size: 20),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardPink,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.accent.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PastEntriesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('journalEntries')
          .orderBy('timestamp', descending: true)
          .limit(10)
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
            child: Text('No entries yet — start writing! 🌸',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textMedium)),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final ts = data['timestamp'];
            final timeStr = ts is Timestamp
                ? DateFormat('MMM d · h:mm a').format(ts.toDate())
                : '';
            final photoUrl = data['photoUrl'] as String? ?? '';

            return Dismissible(
              key: Key(doc.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete_outline,
                    color: Colors.white, size: 28),
              ),
              confirmDismiss: (_) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: Text('Delete Entry',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                    content: Text(
                        'Are you sure you want to delete this journal entry?',
                        style: GoogleFonts.poppins(fontSize: 14)),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(ctx, false),
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
                        onPressed: () =>
                            Navigator.pop(ctx, true),
                        child: Text('Delete',
                            style: GoogleFonts.poppins()),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (_) async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('journalEntries')
                    .doc(doc.id)
                    .delete();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Entry deleted 🌸'),
                    backgroundColor: AppColors.primaryLight,
                  ),
                );
              },
              child: GestureDetector(
                onTap: () => _showEditDialog(context, user.uid,
                    doc.id, data),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.accent.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(_moodEmoji(data['mood'] ?? ''),
                              style:
                                  const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(data['mood'] ?? '',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary)),
                          const Spacer(),
                          Text(timeStr,
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textMedium)),
                          const SizedBox(width: 8),
                          const Icon(Icons.edit_outlined,
                              size: 14,
                              color: AppColors.textLight),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(data['text'] ?? '',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textDark)),

                      // Photo
                      if (photoUrl.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            photoUrl,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) =>
                                progress == null
                                    ? child
                                    : const Center(
                                        child:
                                            CircularProgressIndicator(
                                                color: AppColors
                                                    .primary)),
                          ),
                        ),
                      ],

                      // Location
                      if ((data['location'] as String? ?? '')
                          .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 12,
                                color: AppColors.textMedium),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(data['location'] ?? '',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color:
                                          AppColors.textMedium)),
                            ),
                          ],
                        ),
                      ],

                      // Edit hint
                      const SizedBox(height: 8),
                      Text('Tap to edit • Swipe left to delete',
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppColors.textLight,
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, String uid,
      String docId, Map<String, dynamic> data) {
    final editController =
        TextEditingController(text: data['text'] ?? '');
    String selectedMood = data['mood'] ?? 'Happy';

    final List<Map<String, String>> moods = const [
      {'label': 'Happy', 'emoji': '😊'},
      {'label': 'Sad', 'emoji': '😢'},
      {'label': 'Calm', 'emoji': '😌'},
      {'label': 'Angry', 'emoji': '😤'},
      {'label': 'Nutcracker', 'emoji': '🎄'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text('Edit Entry',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
              const SizedBox(height: 16),

              // Mood selector
              Text('Mood',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark)),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: moods.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final mood = moods[i];
                    final selected =
                        mood['label'] == selectedMood;
                    return GestureDetector(
                      onTap: () => setModalState(
                          () => selectedMood = mood['label']!),
                      child: AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.cardPink,
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.accent
                                      .withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Text(mood['emoji']!,
                                style: const TextStyle(
                                    fontSize: 16)),
                            const SizedBox(width: 4),
                            Text(mood['label']!,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textDark)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Text editor
              Text('Journal',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.accent.withOpacity(0.3)),
                ),
                child: TextField(
                  controller: editController,
                  maxLines: 5,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                    hintText: 'Edit your entry...',
                    hintStyle: GoogleFonts.poppins(
                        color: AppColors.textLight,
                        fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Save button
              ElevatedButton.icon(
                onPressed: () async {
                  if (editController.text.trim().isEmpty) return;

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('journalEntries')
                      .doc(docId)
                      .update({
                    'text': editController.text.trim(),
                    'mood': selectedMood,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(ctx);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Entry updated! 🌸'),
                      backgroundColor: AppColors.primaryLight,
                    ),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('Save Changes'),
              ),
            ],
          ),
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