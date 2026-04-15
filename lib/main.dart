import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Hive local storage
  await Hive.initFlutter();
  await Hive.openBox('moodLogs');
  await Hive.openBox('journalEntries');
  await Hive.openBox('userPrefs');

  runApp(const ProviderScope(child: MoodScapeApp()));
}