import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';

import '../../core/battery/battery_health_service.dart';

class BatteryPage extends StatefulWidget {
  const BatteryPage({super.key});

  @override
  State<BatteryPage> createState() => _BatteryPageState();
}

class _BatteryPageState extends State<BatteryPage> {
  final BatteryHealthService _service = BatteryHealthService();
  BatteryHealthSnapshot? _snapshot;
  StreamSubscription<BatteryState>? _subscription;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _subscription = _service.stateChanges.listen((_) => _load(silent: true));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final snapshot = await _service.read();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'اطلاعات باتری کامل دریافت نشد.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final snapshot = _snapshot;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('سلامت باتری')),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 128,
                        height: 128,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: snapshot == null ? null : snapshot.level / 100,
                              strokeWidth: 10,
                            ),
                            if (snapshot != null)
                              Text(
                                '${snapshot.level}٪',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _loading
                            ? 'در حال خواندن باتری…'
                            : _error ?? snapshot?.stateLabel ?? 'نامشخص',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      if (snapshot != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          snapshot.isBatterySaverOn
                              ? 'حالت ذخیره باتری روشن است.'
                              : 'حالت ذخیره باتری خاموش است.',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('پیشنهادهای بهینه‌سازی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              _AdviceCard(
                icon: Icons.battery_saver_rounded,
                title: 'Battery Saver',
                text: snapshot?.isBatterySaverOn == true
                    ? 'فعال است؛ در شارژ کم می‌تواند مصرف پس‌زمینه را کاهش دهد.'
                    : 'در شارژ کم می‌توانی Battery Saver اندروید را فعال کنی.',
              ),
              const SizedBox(height: 10),
              const _AdviceCard(
                icon: Icons.notifications_active_outlined,
                title: 'برنامه‌های پرمصرف',
                text: 'اندروید دسترسی مستقیم و قابل‌اعتماد به مصرف باتری همه برنامه‌ها را به اپ عادی نمی‌دهد. پادرا به‌جای حدس‌زدن، این مورد را از تنظیمات سیستم به کاربر واگذار می‌کند.',
              ),
              const SizedBox(height: 10),
              const _AdviceCard(
                icon: Icons.device_thermostat_rounded,
                title: 'دمای باتری',
                text: 'اگر API عمومی دستگاه دمای قابل‌اعتماد ارائه نکند، پادرا عدد ساختگی نمایش نمی‌دهد. این داده را بعداً با کانال Native مخصوص Android اضافه می‌کنیم.',
              ),
              const SizedBox(height: 10),
              const _AdviceCard(
                icon: Icons.health_and_safety_outlined,
                title: 'سلامت واقعی باتری',
                text: 'درصد سلامت فیزیکی باتری روی همه گوشی‌ها API استاندارد ندارد. پادرا فعلاً فقط وضعیت‌های قابل‌اندازه‌گیری را گزارش می‌کند.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text(text, style: TextStyle(color: colors.onSurfaceVariant, height: 1.6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
