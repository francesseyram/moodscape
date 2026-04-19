import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/screens/login_screen.dart';
import '../../../data/services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  TimeOfDay _checkInTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled =
          prefs.getBool('notificationsEnabled') ?? true;
      final hour = prefs.getInt('checkInHour') ?? 9;
      final minute = prefs.getInt('checkInMinute') ?? 0;
      _checkInTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setInt('checkInHour', _checkInTime.hour);
    await prefs.setInt('checkInMinute', _checkInTime.minute);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _checkInTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _checkInTime = picked);
      await _savePrefs();

      if (_notificationsEnabled) {
        await NotificationService.scheduleDailyCheckIn(
            picked.hour, picked.minute);
        await NotificationService.showTestNotification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Reminder set for ${picked.format(context)} 🌸'),
              backgroundColor: AppColors.primaryLight,
            ),
          );
        }
      }
    }
  }

  Future<void> _showEditNameDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    final nameController =
        TextEditingController(text: user?.displayName ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
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
              Text('Edit Name',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline,
                      color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;

                  // Update Firebase Auth display name
                  await user?.updateDisplayName(name);

                  // Update Firestore
                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({'name': name});
                  }

                  Navigator.pop(ctx);
                  setState(() {});

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Name updated! 🌸'),
                        backgroundColor: AppColors.primaryLight,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('Save Name'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFAD1457), Color(0xFFE91E8C)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
                        ? Text(
                            user?.displayName?.isNotEmpty == true
                                ? user!.displayName![0].toUpperCase()
                                : user?.email?[0].toUpperCase() ??
                                    'M',
                            style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'MoodScape User',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                        Text(
                          user?.email ?? '',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  // Edit name button
                  IconButton(
                    onPressed: _showEditNameDialog,
                    icon: const Icon(Icons.edit_outlined,
                        color: Colors.white70, size: 20),
                    tooltip: 'Edit name',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Notifications section
            _SectionTitle('Notifications'),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Daily Check-In Reminder',
              trailing: Switch(
                value: _notificationsEnabled,
                activeColor: AppColors.primary,
                onChanged: (v) async {
                  setState(() => _notificationsEnabled = v);
                  await _savePrefs();
                  if (v) {
                    await NotificationService.scheduleDailyCheckIn(
                        _checkInTime.hour, _checkInTime.minute);
                    await NotificationService.showTestNotification();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Daily reminders enabled 🌸'),
                          backgroundColor: AppColors.primaryLight,
                        ),
                      );
                    }
                  } else {
                    await NotificationService.cancelDailyCheckIn();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Reminders turned off')),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.access_time_outlined,
              title: 'Reminder Time',
              subtitle: _checkInTime.format(context),
              onTap: _pickTime,
            ),
            const SizedBox(height: 24),

            // Profile section
            _SectionTitle('Profile'),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.person_outline,
              title: 'Edit Display Name',
              subtitle: user?.displayName ?? 'Tap to set your name',
              onTap: _showEditNameDialog,
            ),
            const SizedBox(height: 24),

            // About section
            _SectionTitle('About'),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'App Version',
              subtitle: '1.0.0',
            ),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.favorite_outline,
              title: 'Made with love 🌸',
              subtitle: 'MoodScape — Your wellness companion',
            ),
            const SizedBox(height: 24),

            // Account section
            _SectionTitle('Account'),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.logout,
              title: 'Sign Out',
              iconColor: AppColors.error,
              titleColor: AppColors.error,
              onTap: _signOut,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textMedium,
          letterSpacing: 0.8),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: AppColors.accent.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: iconColor ?? AppColors.primary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: titleColor ?? AppColors.textDark),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textMedium),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null && onTap != null)
              const Icon(Icons.chevron_right,
                  color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}