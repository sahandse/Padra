import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../device/device_snapshot.dart';
import 'notification_preferences.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'padra_protection';
  static const _channelName = 'محافظت پادرا';
  static const _channelDescription = 'هشدارهای واقعی امنیت، حافظه و باتری';

  Future<void> initialize() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }

  Future<void> evaluate(DeviceSnapshot snapshot) async {
    final prefs = await NotificationPreferences.load();
    if (!prefs.enabled) return;
    await initialize();

    if (prefs.batteryAlerts &&
        snapshot.batteryLevel <= 20 &&
        snapshot.batteryState != 'در حال شارژ' &&
        snapshot.batteryState != 'شارژ کامل') {
      await _show(
        id: 1301,
        title: 'باتری کم است',
        body: 'شارژ باتری ${snapshot.batteryLevel}٪ است. در صورت نیاز حالت Battery Saver را بررسی کن.',
      );
    }

    final used = snapshot.usedStoragePercent;
    if (prefs.storageAlerts && used != null && used >= 90) {
      await _show(
        id: 1302,
        title: 'فضای ذخیره‌سازی رو به اتمام است',
        body: '${used.round()}٪ حافظه استفاده شده. Storage و Cleaner پادرا را بررسی کن.',
      );
    }

    if (prefs.securityAlerts && _isSecurityPatchOld(snapshot.securityPatch)) {
      await _show(
        id: 1303,
        title: 'وصله امنیتی دستگاه قدیمی است',
        body: 'بخش امنیت پادرا را باز کن و بروزرسانی‌های سیستم را بررسی کن.',
      );
    }
  }

  Future<void> sendTest() async {
    await initialize();
    await _show(
      id: 1399,
      title: 'اعلان آزمایشی پادرا',
      body: 'اعلان‌ها فعال هستند و فقط برای وضعیت‌های قابل بررسی استفاده می‌شوند.',
    );
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.status,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(id: id, title: title, body: body, notificationDetails: details);
  }

  bool _isSecurityPatchOld(String? patch) {
    if (patch == null || patch.isEmpty) return false;
    final parsed = DateTime.tryParse(patch);
    if (parsed == null) return false;
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);
    return parsed.isBefore(sixMonthsAgo);
  }
}
