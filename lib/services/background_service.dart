import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'dart:async';
import 'dart:developer' as dev;
import 'package:flipcard/constants/config.dart';
import 'package:flipcard/helpers/local_notification.dart';
import 'package:flipcard/services/quiz_result_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
class BackgroundService {
  /// storage notification key
  static final _key = 'last_notified';

  /// notification channel
  static final _channel = 'background_service';

  /// service timer interval
  static final _interval = Duration(hours: 6);

  /// notification cooldown
  static final _cooldown = Duration(hours: 12);

  static final _service = FlutterBackgroundService();
  static final _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// getting current user is logged
  static bool get _logged => _user != null;

  /// getting detail current user
  static User? get _user => _supabase.auth.currentUser;

  /// supabase client isntant
  static SupabaseClient get _supabase => Supabase.instance.client;

  /// list of notification titles
  static List<String> get _titles => [
    "💡 Knowledge Boost",
    "⏰ Study Time!",
    "🧠 Brain Workout",
    "🚀 Learning Journey",
    "✨ Quick Practice?",
    "🎯 Focus Time Ahead",
    "🌟 Learning Breakthrough",
  ];

  /// list of notification messages
  static List<String> get _messages => [
    "Consistency is key! Keep up the great work 🌈",
    "Your brain is eager for a workout! Let's go 🧠",
    "Don't let your streak break! Quick flip session? 🔥",
    "Knowledge waits for no one! Let's flip some cards 📚",
    "Your cards are waiting for you! Time to practice ✨",
    "Don't miss out on today's learning adventure 🌟",
    "Your learning journey continues... Join us! 🚀",
    "Missing you! Come back and flip some cards 🃏",
    "Your flashcards are just a tap away. Let's make progress 📈",
    "Ready for a brain workout? Your flashcards miss you 🧠",
    "Ready to conquer new knowledge? Your cards are waiting 🎯",
  ];

  @pragma('vm:entry-point')
  static Future<void> initialize() async {
    if (Platform.isAndroid) {
      final channel = AndroidNotificationChannel(
        _channel,
        'Background Service',
        importance: Importance.low,
      );

      await LocalNotification.instance
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }

    await _service.configure(
      iosConfiguration: IosConfiguration(
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        isForegroundMode: false,
        foregroundServiceNotificationId: -1,
        notificationChannelId: _channel,
        initialNotificationTitle: 'Sync process',
        initialNotificationContent: 'Currently syncing...',
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
      ),
    );
  }

  static Future<void> startService() async {
    if (await _service.isRunning()) {
      _log('Service already running');
      return;
    }

    await _service.startService();
    _log('Starting service');
  }

  static Future<void> stopService() async {
    if (!await _service.isRunning()) return;
    _service.invoke('stopService');
    _log('Service stopped');
  }

  static Future<void> reset() async {
    await _storage.delete(key: _key);
  }

  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    try {
      DartPluginRegistrant.ensureInitialized();

      // initialize on main isolate
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

      if (!_logged || _user == null) {
        await service.stopSelf();
        return _log('Unauthorized');
      }

      _setupServiceListeners(service);

      _startPeriodicUpdates(service);
    } catch (e) {
      _log('Starting service failed: $e');
    }
  }

  static void _setupServiceListeners(ServiceInstance s) {
    if (s is AndroidServiceInstance) {
      s.on('setAsForeground').listen((_) => s.setAsForegroundService());
      s.on('setAsBackground').listen((_) => s.setAsBackgroundService());
    }

    s.on('stopService').listen((_) => s.stopSelf());
  }

  static void _startPeriodicUpdates(ServiceInstance service) {
    Timer.periodic(_interval, (timer) async {
      try {
        await _updateService(service, timer);
      } catch (e, stack) {
        _log('Update failed: $e\n$stack');
      }
    });
  }

  static Future<void> _updateService(
    ServiceInstance service,
    Timer timer,
  ) async {
    try {
      if (_user == null) return;
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          await service.setAsBackgroundService();
        }
      }

      final now = DateTime.now();
      final lastQuiz = await QuizResultService.getLastQuizByUserId(_user!.id);

      // user has never taken a quiz
      if (lastQuiz == null) {
        final createdAt = DateTime.parse(_user!.createdAt);

        // send if user was created before today
        if (createdAt.isBefore(DateTime(now.year, now.month, now.day))) {
          if (await _shouldShown(null)) {
            await _push();
            await _write(now);
          }
        }

        return;
      }

      final sinceLastQuiz = now.difference(lastQuiz.createdAt);

      // checking cooldown
      if (sinceLastQuiz < _cooldown) {
        // timer.cancel();
        // await service.stopSelf();
        _log('Last quiz: (${sinceLastQuiz.inHours} hours ago)');
        return;
      }

      if (await _shouldShown(lastQuiz.createdAt)) {
        await _push();
        await _write(now);
      }

      service.invoke('updated', {
        'user_id': _user?.id,
        'timestamp': now.toIso8601String(),
      });
    } catch (e) {
      _log('Updating service failed: $e');
    }
  }

  static Future<bool> _shouldShown(DateTime? lastSeen) async {
    final now = DateTime.now();
    final lastNotified = await _read();

    // If we've never sent a notification, or it's been 12+ hours
    if (lastNotified == null) return true;

    return now.difference(lastNotified) >= _cooldown;
  }

  /// push notification
  static Future<void> _push() async {
    final random = Random();

    /// for specific day index
    // final index = DateTime.now().day % _titles.length;
    // index % _messages.length

    await LocalNotification.show(
      title: _titles[random.nextInt(_titles.length)],
      body: _messages[random.nextInt(_messages.length)],
    );
  }

  /// write last notified
  static Future<void> _write(DateTime time) async {
    await _storage.write(
      key: _key,
      value: time.millisecondsSinceEpoch.toString(),
    );
  }

  /// read last notified
  static Future<DateTime?> _read() async {
    final timeString = await _storage.read(key: _key);
    return timeString != null
        ? DateTime.fromMillisecondsSinceEpoch(int.parse(timeString))
        : null;
  }

  static void _log(String message) {
    dev.log(message, name: 'BackgroundService');
  }
}
