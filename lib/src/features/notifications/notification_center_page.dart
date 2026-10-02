import 'package:flutter/material.dart';

import '../../core/notifications/notification_preferences.dart';
import '../../core/notifications/notification_service.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> {
  NotificationPreferences _prefs = NotificationPreferences.defaults();
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await NotificationPreferences.load();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _loading = false;
    });
  }

  Future<void> _save(NotificationPreferences next) async {
    setState(() {
      _prefs = next;
      _busy = true;
    });
    await next.save();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _toggleMaster(bool value) async {
    if (value) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اجازه اعلان در اندروید فعال نشد.')),
        );
        return;
      }
    }
    await _save(_prefs.copyWith(enabled: value));
  }

  Future<void> _test() async {
    setState(() => _busy = true);
    try {
      await NotificationService.instance.sendTest();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('اعلان‌ها و محافظت')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Icon(Icons.notifications_active_outlined, size: 48, color: colors.primary),
                          const SizedBox(height: 10),
                          const Text('هشدارهای واقعی پادرا', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text(
                            'پادرا فقط بر اساس بررسی‌هایی که واقعاً انجام شده‌اند اعلان می‌دهد. فعال‌بودن این بخش به معنی مانیتورینگ دائمی پس‌زمینه نیست.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.onSurfaceVariant, height: 1.7),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: SwitchListTile(
                      value: _prefs.enabled,
                      onChanged: _busy ? null : _toggleMaster,
                      secondary: const Icon(Icons.notifications_rounded),
                      title: const Text('فعال‌کردن اعلان‌های پادرا', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('در Android 13 و بالاتر فقط بعد از تأیید خودت فعال می‌شود.'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ToggleTile(
                    title: 'هشدارهای امنیتی',
                    subtitle: 'مثلاً وصله امنیتی قدیمی دستگاه',
                    icon: Icons.security_rounded,
                    value: _prefs.securityAlerts,
                    enabled: _prefs.enabled && !_busy,
                    onChanged: (value) => _save(_prefs.copyWith(securityAlerts: value)),
                  ),
                  _ToggleTile(
                    title: 'هشدار فضای حافظه',
                    subtitle: 'وقتی استفاده از فضای ذخیره‌سازی به ۹۰٪ یا بیشتر برسد',
                    icon: Icons.storage_rounded,
                    value: _prefs.storageAlerts,
                    enabled: _prefs.enabled && !_busy,
                    onChanged: (value) => _save(_prefs.copyWith(storageAlerts: value)),
                  ),
                  _ToggleTile(
                    title: 'هشدار باتری کم',
                    subtitle: 'وقتی شارژ ۲۰٪ یا کمتر باشد و گوشی در حال شارژ نباشد',
                    icon: Icons.battery_alert_outlined,
                    value: _prefs.batteryAlerts,
                    enabled: _prefs.enabled && !_busy,
                    onChanged: (value) => _save(_prefs.copyWith(batteryAlerts: value)),
                  ),
                  _ToggleTile(
                    title: 'یادآوری بررسی دوره‌ای',
                    subtitle: 'تنظیم ذخیره می‌شود؛ زمان‌بندی پس‌زمینه در مرحله بعد فعال خواهد شد.',
                    icon: Icons.event_repeat_rounded,
                    value: _prefs.scanReminders,
                    enabled: _prefs.enabled && !_busy,
                    onChanged: (value) => _save(_prefs.copyWith(scanReminders: value)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: !_prefs.enabled || _busy ? null : _test,
                      icon: const Icon(Icons.notification_add_outlined),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('ارسال اعلان آزمایشی'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.privacy_tip_outlined, color: colors.primary),
                      title: const Text('کنترل دست کاربر است', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('پادرا برای جلب توجه هشدار ساختگی، تعداد ویروس جعلی یا اعلان ترسناک نمایش نمی‌دهد.'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        value: value,
        onChanged: enabled ? onChanged : null,
        secondary: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
      ),
    );
  }
}
