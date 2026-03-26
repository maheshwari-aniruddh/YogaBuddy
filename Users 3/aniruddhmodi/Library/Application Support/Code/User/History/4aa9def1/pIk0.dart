import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Notification preferences keys
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyDailyReminder = 'daily_reminder_enabled';
  static const String _keyWeeklyReview = 'weekly_review_enabled';

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    
    // Set local timezone (adjust based on user's location)
    final String timeZoneName = 'America/Los_Angeles'; // Change to user's timezone
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;

    // Request permissions for iOS
    await _requestPermissions();

    // Load preferences and schedule if enabled
    final prefs = await SharedPreferences.getInstance();
    final dailyEnabled = prefs.getBool(_keyDailyReminder) ?? true;
    if (dailyEnabled) {
      await scheduleDailyReminder();
    }
  }

  Future<void> _requestPermissions() async {
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - you can navigate to a specific screen here
    print('Notification tapped: ${response.payload}');
  }

  Future<void> scheduleDailyReminder() async {
    await _notifications.cancelAll(); // Cancel existing notifications

    final random = Random();
    
    // Schedule for the next 30 days at random times between 6-10 PM
    for (int i = 0; i < 30; i++) {
      final now = tz.TZDateTime.now(tz.local);
      
      // Random hour between 18 (6 PM) and 22 (10 PM)
      final randomHour = 18 + random.nextInt(5); // 18, 19, 20, 21, or 22
      final randomMinute = random.nextInt(60); // 0-59 minutes
      
      // Schedule for day i from now
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + i,
        randomHour,
        randomMinute,
      );

      // If the scheduled time for today has passed, skip to tomorrow
      if (i == 0 && scheduledDate.isBefore(now)) {
        continue;
      }

      await _scheduleNotification(
        id: i,
        title: _getRandomTitle(),
        body: _getRandomBody(),
        scheduledDate: scheduledDate,
      );
    }

    print('Daily reminders scheduled for the next 30 days');
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Daily Reminder',
      channelDescription: 'Daily journal reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'daily_reminder',
    );
  }

  String _getRandomTitle() {
    final titles = [
      '🌹 Time to reflect',
      '✨ Your journal awaits',
      '💭 How was your day?',
      '📝 Quick check-in',
      '🌸 Moment of reflection',
      '💖 Share your thoughts',
      '🎨 Capture today',
      '🌟 Daily reflection time',
    ];
    return titles[Random().nextInt(titles.length)];
  }

  String _getRandomBody() {
    final bodies = [
      'Take a moment to journal about your day',
      'What are you grateful for today?',
      'How are you feeling right now?',
      'Capture today\'s moments in your journal',
      'A few minutes of reflection can make a difference',
      'Your thoughts matter - write them down',
      'End your day with a moment of reflection',
      'Take a mindful pause and journal',
    ];
    return bodies[Random().nextInt(bodies.length)];
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('All notifications cancelled');
  }

  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notification channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      '🌹 Test Notification',
      'Notifications are working! You\'ll receive daily reminders between 6-10 PM',
      notificationDetails,
      payload: 'test',
    );
  }

  // Preference management
  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
    
    if (!enabled) {
      await cancelAllNotifications();
    } else {
      final dailyEnabled = await getDailyReminderEnabled();
      if (dailyEnabled) {
        await scheduleDailyReminder();
      }
    }
  }

  Future<bool> getDailyReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDailyReminder) ?? true;
  }

  Future<void> setDailyReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDailyReminder, enabled);
    
    if (enabled) {
      final notificationsEnabled = await getNotificationsEnabled();
      if (notificationsEnabled) {
        await scheduleDailyReminder();
      }
    } else {
      await cancelAllNotifications();
    }
  }

  Future<bool> getWeeklyReviewEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyWeeklyReview) ?? false;
  }

  Future<void> setWeeklyReviewEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWeeklyReview, enabled);
    // TODO: Implement weekly review notifications
  }
}
