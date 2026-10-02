import 'package:flutter/material.dart';

import '../../core/device/device_scan_service.dart';
import '../../core/device/device_snapshot.dart';
import '../../core/history/history_service.dart';
import '../antivirus/antivirus_page.dart';
import '../apps/apps_page.dart';
import '../battery/battery_page.dart';
import '../cleaner/cleaner_page.dart';
import '../history/history_page.dart';
import '../network/network_page.dart';
import '../optimization/optimization_page.dart';
import '../privacy/privacy_page.dart';
import '../security/security_page.dart';
import '../storage/storage_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DeviceScanService _scanner = DeviceScanService();
  final HistoryService _history = const HistoryService();
  DeviceSnapshot? _snapshot;
  bool _scanning = false;
  String? _error;

  Future<void> _scan() async {
    if (_scanning) return;
    setState(() {
      _scanning = true;
      _error = null;
    });
    try {
      final snapshot = await _scanner.scan();
      await _history.add(
        HistoryEvent(
          type: 'device',
          title: 'بررسی کامل دستگاه',
          subtitle: '${snapshot.deviceLabel} • باتری ${snapshot.batteryLevel}٪ • حافظه ${snapshot.usedStoragePercent == null ? 'نامشخص' : '${snapshot.usedStoragePercent!.round()}٪'}',
          createdAt: DateTime.now(),
          value: snapshot.usedStoragePercent,
        ),
      );
      if (!mounted) return;
      setState(() => _snapshot = snapshot);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'خواندن اطلاعات دستگاه کامل نشد. دوباره تلاش کن.');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  void _openTool(String title) {
    final Widget? page = switch (title) {
      'آنتی‌ویروس' => const AntivirusPage(),
      'پاک‌سازی' => const CleanerPage(),
      'باتری' => const BatteryPage(),
      'حافظه' => const StoragePage(),
      'امنیت' => const SecurityPage(),
      'برنامه‌ها' => const AppsPage(),
      'شبکه' => const NetworkPage(),
      _ => null,
    };
    if (page == null) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _openOptimization() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OptimizationPage(snapshot: _snapshot)),
    );
  }

  void _openPrivacy() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PrivacyPage()),
    );
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HistoryPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final snapshot = _snapshot;
    final items = _healthItems(snapshot);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('پادرا', style: TextStyle(fontWeight: FontWeight.w800)),
              Text('امنیت و سلامت گوشی', style: TextStyle(fontSize: 12)),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'تاریخچه و گزارش‌ها',
              onPressed: _openHistory,
              icon: const Icon(Icons.history_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _scan,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                _ScanHero(snapshot: snapshot, scanning: _scanning, error: _error, onScan: _scan),
                const SizedBox(height: 12),
                _FeatureCard(
                  icon: Icons.bolt_rounded,
                  title: 'مرکز بهینه‌سازی',
                  subtitle: snapshot == null
                      ? 'همه بررسی‌ها را یک‌جا ببین'
                      : 'نتیجه‌های واقعی دستگاه و اقدامات پیشنهادی',
                  onTap: _openOptimization,
                ),
                const SizedBox(height: 10),
                _FeatureCard(
                  icon: Icons.shield_lock_outlined,
                  title: 'حریم خصوصی و مجوزها',
                  subtitle: 'مجوزهای حساس، Accessibility، Overlay و Privacy Dashboard',
                  onTap: _openPrivacy,
                ),
                const SizedBox(height: 10),
                _FeatureCard(
                  icon: Icons.insights_rounded,
                  title: 'تاریخچه و گزارش‌ها',
                  subtitle: 'اسکن‌ها، رویدادهای امنیتی و میزان فضای آزادشده',
                  onTap: _openHistory,
                ),
                if (snapshot != null) ...[
                  const SizedBox(height: 18),
                  _DeviceCard(snapshot: snapshot),
                ],
                const SizedBox(height: 24),
                const Text('وضعیت گوشی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.28,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => _openTool(item.title),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(item.icon, color: colors.primary),
                                  Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: colors.onSurfaceVariant),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 3),
                                  Text(
                                    item.status,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Icon(Icons.privacy_tip_outlined, color: colors.primary),
                    title: const Text('اسکن شفاف و بدون نتیجه ساختگی', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('پادرا فقط اطلاعاتی را گزارش می‌کند که واقعاً از اندروید یا فایل انتخاب‌شده دریافت شده باشند.'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_HealthItem> _healthItems(DeviceSnapshot? snapshot) {
    if (snapshot == null) {
      return const [
        _HealthItem('آنتی‌ویروس', 'برای اسکن فایل لمس کن', Icons.shield_outlined),
        _HealthItem('پاک‌سازی', 'فایل‌های بزرگ و تکراری', Icons.cleaning_services_outlined),
        _HealthItem('باتری', 'برای جزئیات لمس کن', Icons.battery_charging_full_rounded),
        _HealthItem('حافظه', 'برای تحلیل لمس کن', Icons.storage_rounded),
        _HealthItem('امنیت', 'برای بررسی لمس کن', Icons.security_rounded),
        _HealthItem('برنامه‌ها', 'برای تحلیل لمس کن', Icons.apps_rounded),
        _HealthItem('شبکه', 'سلامت اینترنت و اتصال', Icons.language_rounded),
      ];
    }
    final storage = snapshot.usedStoragePercent == null
        ? 'نامشخص'
        : '${snapshot.usedStoragePercent!.round()}٪ استفاده شده';
    return [
      const _HealthItem('آنتی‌ویروس', 'اسکن فایل و APK + SHA-256', Icons.shield_outlined),
      const _HealthItem('پاک‌سازی', 'تحلیل و حذف با تأیید', Icons.cleaning_services_outlined),
      _HealthItem('باتری', '${snapshot.batteryLevel}٪ • ${snapshot.batteryState}', Icons.battery_charging_full_rounded),
      _HealthItem('حافظه', '$storage • تحلیل فایل‌ها', Icons.storage_rounded),
      _HealthItem('امنیت', snapshot.securityPatch == null ? 'Patch نامشخص • ورود برای جزئیات' : 'Patch ${snapshot.securityPatch}', Icons.security_rounded),
      const _HealthItem('برنامه‌ها', 'فهرست و تحلیل واقعی', Icons.apps_rounded),
      const _HealthItem('شبکه', 'نوع اتصال، DNS و دسترسی واقعی', Icons.language_rounded),
    ];
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: colors.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: colors.onSurfaceVariant)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanHero extends StatelessWidget {
  const _ScanHero({required this.snapshot, required this.scanning, required this.error, required this.onScan});
  final DeviceSnapshot? snapshot;
  final bool scanning;
  final String? error;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasResult = snapshot != null;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .45)),
      ),
      child: Column(
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: colors.primary, width: 7)),
            child: scanning
                ? Padding(padding: const EdgeInsets.all(30), child: CircularProgressIndicator(color: colors.primary))
                : Icon(hasResult ? Icons.verified_user_rounded : Icons.shield_outlined, size: 48, color: colors.primary),
          ),
          const SizedBox(height: 18),
          Text(
            scanning ? 'در حال بررسی گوشی…' : hasResult ? 'اطلاعات دستگاه بررسی شد' : 'هنوز گوشی بررسی نشده',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(
            error ?? (hasResult ? 'اطلاعات واقعی باتری، حافظه و نسخه امنیتی اندروید دریافت شد.' : 'برای مشاهده وضعیت واقعی دستگاه، اسکن را شروع کن.'),
            textAlign: TextAlign.center,
            style: TextStyle(color: error == null ? colors.onSurfaceVariant : colors.error, height: 1.7),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: scanning ? null : onScan,
              icon: Icon(hasResult ? Icons.refresh_rounded : Icons.radar_rounded),
              label: Padding(padding: const EdgeInsets.symmetric(vertical: 13), child: Text(hasResult ? 'بررسی دوباره' : 'شروع بررسی کامل')),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.snapshot});
  final DeviceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final total = snapshot.totalStorageMb;
    final free = snapshot.freeStorageMb;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.smartphone_rounded, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(snapshot.deviceLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            ]),
            const SizedBox(height: 14),
            _InfoRow('اندروید', '${snapshot.androidVersion} (SDK ${snapshot.sdkInt})'),
            _InfoRow('وصله امنیتی', snapshot.securityPatch ?? 'نامشخص'),
            _InfoRow('دستگاه واقعی', snapshot.isPhysicalDevice ? 'بله' : 'خیر'),
            _InfoRow('حافظه', total == null || free == null ? 'نامشخص' : '${_gb(free)} GB آزاد از ${_gb(total)} GB'),
          ],
        ),
      ),
    );
  }

  static String _gb(double mb) => (mb / 1024).toStringAsFixed(1);
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        SizedBox(width: 92, child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

class _HealthItem {
  const _HealthItem(this.title, this.status, this.icon);
  final String title;
  final String status;
  final IconData icon;
}
