import 'dart:math';
import 'dart:developer' as dev;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotification {
  static final _notification = FlutterLocalNotificationsPlugin();

  static FlutterLocalNotificationsPlugin get instance => _notification;

  static Future<List<PendingNotificationRequest>> get pending =>
      _notification.pendingNotificationRequests();

  static Future<void> initialize() async {
    try {
      tz.initializeTimeZones();
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      const androidSettings = AndroidInitializationSettings('notification');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _notification.initialize(
        InitializationSettings(android: androidSettings, iOS: iosSettings),
        onDidReceiveNotificationResponse: (NotificationResponse res) {
          // Handle notification tap
          _log(
            'NotificationResponse('
            'id: ${res.id}, '
            'data: ${res.data}, '
            'payload: ${res.payload}, '
            'action: ${res.actionId}, '
            'input: ${res.input}, '
            'type: ${res.notificationResponseType}, '
            ')',
          );
        },
      );
    } catch (e) {
      _log('Initialize failed: ${e.toString()}');
    }
  }

  static Future<void> requestPermissions() async {
    try {
      // request permissions for iOS
      await _notification
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      // request permissions for Android 13+
      await _notification
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (e) {
      _log('request permissions: $e');
    }
  }

  /// Showing basic notification
  static Future<void> show({
    int? id,
    String? icon,
    required String title,
    String? body,
    String? payload,
    bool playSound = true,
    bool ongoing = false,
    bool showTimestamp = true,
    StyleInformation? style,
    List<AndroidNotificationAction>? actions,
  }) async {
    try {
      final iOS = DarwinNotificationDetails(
        categoryIdentifier: 'actionCategory',
      );

      final android = AndroidNotificationDetails(
        'basic_channel_id',
        'Basic Notifications',
        icon: icon,
        channelDescription: 'This channel is used for basic notifications.',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: style,
        playSound: playSound,
        ongoing: ongoing,
        showWhen: showTimestamp,
        actions: actions,
      );

      await _notification.show(
        id ?? Random().nextInt(1000),
        title,
        body,
        NotificationDetails(android: android, iOS: iOS),
        payload: payload,
      );
    } catch (e) {
      _log('Show notification failed: ${e.toString()}');
    }
  }

  /// Showing progress notification
  static Future<void> showProgress({
    int id = 999, // fixed ID for progress updates
    String? icon,
    required String title,
    String? body,
    String? payload,
    StyleInformation? style,
    int progress = 0,
    int maxProgress = 0,
    bool onlyAlertOnce = false,
    List<AndroidNotificationAction>? actions,
  }) async {
    try {
      final iOS = DarwinNotificationDetails(
        categoryIdentifier: 'actionCategory',
      );

      final android = AndroidNotificationDetails(
        'progress_channel_id',
        'Progress Notifications',
        icon: icon,
        channelDescription: 'This channel is used for progress notifications.',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: style,
        showProgress: true,
        progress: progress,
        maxProgress: maxProgress,
        onlyAlertOnce: onlyAlertOnce,
        actions: actions,
      );

      await _notification.show(
        id,
        title,
        body,
        NotificationDetails(android: android, iOS: iOS),
        payload: payload,
      );
    } catch (e) {
      _log('Progress notification failed: ${e.toString()}');
    }
  }

  /// Showing scheduled notification
  static Future<void> showSchedule({
    int? id,
    required String title,
    String? body,
    String? payload,
    required DateTime schedule,
    StyleInformation? style,
    List<AndroidNotificationAction>? actions,
  }) async {
    try {
      final iOS = DarwinNotificationDetails(
        categoryIdentifier: 'actionCategory',
      );

      final android = AndroidNotificationDetails(
        'schedule_channel_id',
        'Schedule Notifications',
        channelDescription: 'This channel is used for schedule notifications.',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: style,
        actions: actions,
      );

      await _notification.zonedSchedule(
        id ?? Random().nextInt(1000),
        title,
        body,
        tz.TZDateTime.parse(tz.local, schedule.toString()),
        NotificationDetails(android: android, iOS: iOS),
        payload: payload,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      _log('Schedule notification failed: ${e.toString()}');
    }
  }

  static Future<void> cancel(int id, {String? tag}) async {
    await _notification.cancel(id, tag: tag);
  }

  static Future<void> cancelPending() async {
    await _notification.cancelAllPendingNotifications();
  }

  static Future<void> cancelAll() async {
    await _notification.cancelAll();
  }

  static void _log(String message) {
    dev.log(message, name: 'LocalNotification');
  }
}

class LocalNotificationContent {
  final int id;
  final String? icon;
  final String title;
  final String? body;
  final String? payload;
  final StyleInformation? style;
  final List<AndroidNotificationAction>? actions;

  LocalNotificationContent({
    int? id,
    this.icon,
    required this.title,
    this.body,
    this.payload,
    this.style,
    this.actions,
  }) : id = id ?? Random().nextInt(1000);
}
