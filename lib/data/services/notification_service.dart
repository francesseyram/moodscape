import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();

    // Auto detect device timezone
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (details) {},
    );
  }

  static Future<void> scheduleDailyCheckIn(int hour, int minute) async {
    await _notifications.cancel(0);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      0,
      'How are you feeling? 🌸',
      'Take a moment to log your mood and journal your thoughts.',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_checkin',
          'Daily Check-In',
          channelDescription: 'Daily mood check-in reminder',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF880E4F),
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelDailyCheckIn() async {
    await _notifications.cancel(0);
  }

  static Future<void> showTestNotification() async {
    await _notifications.show(
      1,
      'MoodScape 🌸',
      'Your daily reminder is set! We\'ll check in with you soon.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_checkin',
          'Daily Check-In',
          channelDescription: 'Daily mood check-in reminder',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF880E4F),
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> showWellnessPrompt() async {
    await _notifications.show(
      2,
      'Time for a wellness check 🌿',
      'You\'ve been still for a while. Take a breath and log how you\'re feeling.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'wellness_prompt',
          'Wellness Prompts',
          channelDescription: 'Wellness and inactivity prompts',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: const Color(0xFF880E4F),
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}