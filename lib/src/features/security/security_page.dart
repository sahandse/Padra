import 'package:flutter/material.dart';

import '../../core/device/device_scan_service.dart';
import '../../core/device/device_snapshot.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final _scanner = DeviceScanService();
  DeviceSnapshot? _snapshot;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _scanner.scan();
      if (!mounted) return;
      setState(() => _snapshot = result);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'بررسی امنیت دستگاه کامل نشد.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مرکز امنیت')),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 52),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _Notice(text: _error!, icon: Icons.error_outline_rounded)
              else if (_snapshot case final snapshot?) ...[
                _SecurityHeader(snapshot: snapshot),
                const SizedBox(height: 16),
                _CheckTile(
                  title: 'وصله امنیتی اندروید',
                  subtitle: _patchLabel(snapshot.securityPatch),
                  state: _patchState(snapshot.securityPatch),
                ),
                _CheckTile(
                  title: 'محیط اجرا',
                  subtitle: snapshot.isPhysicalDevice
                      ? 'پادرا روی دستگاه واقعی اجرا می‌شود.'
                      : 'محیط شبیه‌ساز تشخیص داده شد.',
                  state: snapshot.isPhysicalDevice ? _CheckState.ok : _CheckState.info,
                ),
                _CheckTile(
                  title: 'نسخه اندروید',
                  subtitle: 'Android ${snapshot.androidVersion} • API ${snapshot.sdkInt}',
                  state: _CheckState.info,
                ),
                const SizedBox(height: 10),
                const _Notice(
                  text: 'برخی تنظیمات مثل Play Protect، نصب از منابع ناشناس، Accessibility و Overlay روی همه نسخه‌های اندروید مستقیماً قابل خواندن نیستند. پادرا برای این موارد در مرحله بعد مسیر بررسی سیستمی را اضافه می‌کند.',
                  icon: Icons.info_outline_rounded,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static _CheckState _patchState(String? raw) {
    final date = raw == null ? null : DateTime.tryParse(raw);
    if (date == null) return _CheckState.info;
    final age = DateTime.now().difference(date).inDays;
    if (age <= 90) return _CheckState.ok;
    if (age <= 180) return _CheckState.warning;
    return _CheckState.attention;
  }

  static String _patchLabel(String? raw) {
    final date = raw == null ? null : DateTime.tryParse(raw);
    if (date == null) return 'تاریخ وصله امنیتی قابل تشخیص نیست.';
    final age = DateTime.now().difference(date).inDays;
    if (age <= 90) return '$raw • نسبتاً جدید';
    if (age <= 180) return '$raw • بهتر است به‌روزرسانی سیستم را بررسی کنی';
    return '$raw • مدت زیادی از وصله امنیتی گذشته است';
  }
}

class _SecurityHeader extends StatelessWidget {
  const _SecurityHeader({required this.snapshot});

  final DeviceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: colors.primaryContainer,
            foregroundColor: colors.onPrimaryContainer,
            child: const Icon(Icons.shield_rounded, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('بررسی امنیت پایه', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                const SizedBox(height: 4),
                Text(snapshot.deviceLabel, style: TextStyle(color: colors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _CheckState { ok, warning, attention, info }

class _CheckTile extends StatelessWidget {
  const _CheckTile({required this.title, required this.subtitle, required this.state});

  final String title;
  final String subtitle;
  final _CheckState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = switch (state) {
      _CheckState.ok => Icons.check_circle_rounded,
      _CheckState.warning => Icons.update_rounded,
      _CheckState.attention => Icons.warning_amber_rounded,
      _CheckState.info => Icons.info_rounded,
    };
    final color = switch (state) {
      _CheckState.ok => colors.primary,
      _CheckState.warning => colors.tertiary,
      _CheckState.attention => colors.error,
      _CheckState.info => colors.secondary,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(height: 1.65))),
          ],
        ),
      ),
    );
  }
}
