import 'package:flutter/material.dart';

import '../../core/settings/app_settings_service.dart';
import '../notifications/notification_center_page.dart';
import '../privacy/privacy_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.themeMode, required this.onThemeChanged});

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settings = AppSettingsService();
  bool _autoScan = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await _settings.loadAutoScan();
    if (!mounted) return;
    setState(() {
      _autoScan = value;
      _loading = false;
    });
  }

  Future<void> _setTheme(ThemeMode? mode) async {
    if (mode == null) return;
    await _settings.saveThemeMode(mode);
    widget.onThemeChanged(mode);
  }

  Future<void> _setAutoScan(bool value) async {
    await _settings.saveAutoScan(value);
    if (!mounted) return;
    setState(() => _autoScan = value);
  }

  Future<void> _clearLocalData() async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('پاک‌کردن داده‌های محلی؟'),
        content: const Text('تنظیمات، تاریخچه‌ها و وضعیت onboarding پادرا از روی این گوشی پاک می‌شود. فایل‌های شخصی گوشی حذف نمی‌شوند.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('پاک‌کردن')),
        ],
      ),
    );
    if (approved != true) return;
    await _settings.clearPadraLocalData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('داده‌های محلی پادرا پاک شد.')));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تنظیمات')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
          children: [
            const _SectionTitle('ظاهر'),
            Card(
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    groupValue: widget.themeMode,
                    onChanged: _setTheme,
                    title: const Text('مطابق سیستم'),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: widget.themeMode,
                    onChanged: _setTheme,
                    title: const Text('روشن'),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: widget.themeMode,
                    onChanged: _setTheme,
                    title: const Text('تیره'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _SectionTitle('محافظت و اعلان‌ها'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('مرکز اعلان و محافظت'),
                subtitle: const Text('هشدارهای امنیتی، حافظه و باتری با کنترل کامل کاربر'),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationCenterPage()),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _SectionTitle('اسکن و حریم خصوصی'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    value: _autoScan,
                    onChanged: _loading ? null : _setAutoScan,
                    secondary: const Icon(Icons.radar_rounded),
                    title: const Text('اسکن اولیه هنگام ورود'),
                    subtitle: const Text('فقط اطلاعات پایه دستگاه بررسی می‌شود؛ فایل‌ها بدون انتخاب تو اسکن نمی‌شوند.'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('حریم خصوصی و مجوزها'),
                    subtitle: const Text('Accessibility، Overlay، Privacy Dashboard و دسترسی‌های سیستمی'),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPage())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _SectionTitle('داده‌های محلی'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.delete_sweep_outlined),
                title: const Text('پاک‌کردن همه داده‌های پادرا'),
                subtitle: const Text('فقط تنظیمات و تاریخچه‌های خود پادرا؛ فایل‌های گوشی دست‌نخورده می‌مانند.'),
                onTap: _clearLocalData,
              ),
            ),
            const SizedBox(height: 18),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('پادرا به‌صورت آفلاین‌محور طراحی شده است. هیچ فهرست فایل یا برنامه‌ای بدون انتخاب و رضایت کاربر برای سرویس ابری ارسال نمی‌شود.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 4),
        child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      );
}
