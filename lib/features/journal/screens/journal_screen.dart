import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
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
  bool _isSaving = false;
  bool _isLoadingLocation = false;

  final List<Map<String, String>> _moods = const [
    {'label': 'Happy', 'emoji': '😊'},
    {'label': 'Sad', 'emoji': '😢'},
    {'label': 'Calm', 'emoji': '😌'},
    {'label': 'Angry', 'emoji': '😤'},
    {'label': 'Nutcracker', 'emoji': '🎄'},
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  Future<void> _getLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationText = 'Location services disabled');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _locationText = 'Location permission denied');
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      setState(() => _locationText =
          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}');
    } catch (e) {
      setState(() => _locationText = 'Could not get location');
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _saveEntry() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something first 🌸')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    final entry = {
      'uid': user?.uid ?? '',
      'mood': _selectedMood,
      'text': _textController.text.trim(),
      'location': _locationText ?? '',
      'hasImage': _selectedImage != null,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Save locally
    final box = Hive.box('journalEntries');
    await box.add(entry);

    // Save to Firestore
    try {
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('journalEntries')
            .add({...entry, 'timestamp': FieldValue.serverTimestamp()});
      }
    } catch (_) {}

    setState(() {
      _isSaving = false;
      _textController.clear();
      _selectedImage = null;
      _locationText = null;
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
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final mood = _moods[i];
                  final selected = mood['label'] == _selectedMood;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMood = mood['label']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.accent.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Text(mood['emoji']!,
                              style: const TextStyle(fontSize: 20)),
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

            // Text entry
            Text('Write',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _textController,
                maxLines: 7,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Express yourself freely... 🌸',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 14, color: AppColors.textLight),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons
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
                  icon: Icons.location_on_outlined,
                  label: _isLoadingLocation ? 'Loading...' : 'Location',
                  onTap: _getLocation,
                ),
              ],
            ),

            // Show selected image
            if (_selectedImage != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_selectedImage!,
                    height: 160, width: double.infinity, fit: BoxFit.cover),
              ),
            ],

            // Show location
            if (_locationText != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardPink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(_locationText!,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.primary)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),
            _isSaving
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))
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
            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
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
    final box = Hive.box('journalEntries');
    final entries = box.values.toList().reversed.toList();

    if (entries.isEmpty) {
      return Center(
        child: Text('No entries yet — start writing! 🌸',
            style:
                GoogleFonts.poppins(fontSize: 13, color: AppColors.textMedium)),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final entry = Map<String, dynamic>.from(entries[i] as Map);
        final time = DateTime.tryParse(entry['timestamp'] ?? '');
        final timeStr = time != null
            ? DateFormat('MMM d · h:mm a').format(time)
            : '';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(_moodEmoji(entry['mood'] ?? ''),
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(entry['mood'] ?? '',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                  const Spacer(),
                  Text(timeStr,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textMedium)),
                ],
              ),
              const SizedBox(height: 8),
              Text(entry['text'] ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textDark)),
            ],
          ),
        );
      },
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