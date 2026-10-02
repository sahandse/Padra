import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferences {
  const NotificationPreferences({
    required this.enabled,
    required this.securityAlerts,
    required this.storageAlerts,
    required this.batteryAlerts,
    required this.scanReminders,
  });

  static const _enabledKey = 'notifications_enabled';
  static const _securityKey = 'notifications_security';
  static const _storageKey = 'notifications_storage';
  static const _batteryKey = 'notifications_battery';
  static const _reminderKey = 'notifications_scan_reminders';

  final bool enabled;
  final bool securityAlerts;
  final bool storageAlerts;
  final bool batteryAlerts;
  final bool scanReminders;

  factory NotificationPreferences.defaults() => const NotificationPreferences(
        enabled: false,
        securityAlerts: true,
        storageAlerts: true,
        batteryAlerts: true,
        scanReminders: false,
      );

  static Future<NotificationPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationPreferences(
      enabled: prefs.getBool(_enabledKey) ?? false,
      securityAlerts: prefs.getBool(_securityKey) ?? true,
      storageAlerts: prefs.getBool(_storageKey) ?? true,
      batteryAlerts: prefs.getBool(_batteryKey) ?? true,
      scanReminders: prefs.getBool(_reminderKey) ?? false,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool(_enabledKey, enabled),
      prefs.setBool(_securityKey, securityAlerts),
      prefs.setBool(_storageKey, storageAlerts),
      prefs.setBool(_batteryKey, batteryAlerts),
      prefs.setBool(_reminderKey, scanReminders),
    ]);
  }

  NotificationPreferences copyWith({
    bool? enabled,
    bool? securityAlerts,
    bool? storageAlerts,
    bool? batteryAlerts,
    bool? scanReminders,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      securityAlerts: securityAlerts ?? this.securityAlerts,
      storageAlerts: storageAlerts ?? this.storageAlerts,
      batteryAlerts: batteryAlerts ?? this.batteryAlerts,
      scanReminders: scanReminders ?? this.scanReminders,
    );
  }
}
