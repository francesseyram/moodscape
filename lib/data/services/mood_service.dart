import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/mood_model.dart';
import '../models/track_model.dart';

class MoodService {
  static final _db = FirebaseFirestore.instance;

  static Future<List<MoodModel>> getMoods() async {
  try {
    final snapshot = await _db
        .collection('moods')
        .orderBy('order')
        .get();

    final moods = snapshot.docs
        .map((doc) => MoodModel.fromFirestore(doc.id, doc.data()))
        .where((m) => m.isActive)  // filter in Dart instead of Firestore
        .toList();

    final box = Hive.box('userPrefs');
    await box.put('cachedMoods', moods.map((m) => m.toHive()).toList());

    return moods;
  } catch (e) {
    print('❌ Error fetching moods: $e');
    return _getMoodsFromCache();
  }
}

  static List<MoodModel> _getMoodsFromCache() {
    final box = Hive.box('userPrefs');
    final cached = box.get('cachedMoods');
    if (cached == null) return [];
    return (cached as List)
        .map((m) => MoodModel.fromHive(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  static Future<List<TrackModel>> getTracksForMood(String moodId) async {
    try {
      final snapshot = await _db
          .collection('playlists')
          .doc(moodId)
          .collection('tracks')
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => TrackModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<String> getQuoteForMood(String moodId) async {
    try {
      final snapshot = await _db
          .collection('quotes')
          .where('moodTag', isEqualTo: moodId.toLowerCase())
          .get();

      if (snapshot.docs.isEmpty) return 'You are doing amazing! 🌸';
      snapshot.docs.shuffle();
      return snapshot.docs.first.data()['text'] ?? 'You are doing amazing! 🌸';
    } catch (e) {
      return 'You are doing amazing! 🌸';
    }
  }
}