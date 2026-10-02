import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../device/device_scan_service.dart';
import '../history/history_service.dart';
import '../notifications/notification_preferences.dart';
import '../notifications/notification_service.dart';

class BackgroundHealthService {
  static const taskName = 'padraBackgroundHealthCheck';
  static const uniqueName = 'padra_background_health_check';
  static const lastRunKey = 'background_health_last_run';
  static const enabledKey = 'background_health_enabled';
  static const defaultFrequency = Duration(hours: 12);

  static Future<void> initialize() async {
    await Workmanager().initialize(backgroundCallbackDispatcher);
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey, enabled);

    if (!enabled) {
      await Workmanager().cancelByUniqueName(uniqueName);
      return;
    }

    await Workmanager().registerPeriodicTask(
      uniqueName,
      taskName,
      frequency: defaultFrequency,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(enabledKey) ?? false;
  }

  static Future<DateTime?> lastRun() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(lastRunKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  static Future<bool> runNow() => _performCheck();

  static Future<bool> _performCheck() async {
    try {
      final snapshot = await DeviceScanService().scan();
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(lastRunKey, now.toIso8601String());

      await const HistoryService().add(
        HistoryEvent(
          type: 'background',
          title: 'بررسی پس‌زمینه دستگاه',
          subtitle:
              'باتری ${snapshot.batteryLevel}٪ • حافظه ${snapshot.usedStoragePercent == null ? 'نامشخص' : '${snapshot.usedStoragePercent!.round()}٪'}',
          createdAt: now,
          value: snapshot.usedStoragePercent,
        ),
      );

      final notificationPrefs = await NotificationPreferences.load();
      if (notificationPrefs.enabled) {
        await NotificationService.instance.evaluate(snapshot);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != BackgroundHealthService.taskName) return true;
    return BackgroundHealthService.runNow();
  });
}
