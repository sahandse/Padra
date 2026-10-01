import 'package:flutter/material.dart';

import '../../core/device/device_scan_service.dart';
import '../../core/device/device_snapshot.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DeviceScanService _scanner = DeviceScanService();

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
      if (!mounted) return;
      setState(() => _snapshot = snapshot);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'خواندن اطلاعات دستگاه کامل نشد. دوباره تلاش کن.';
      });
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
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
              onPressed: null,
              tooltip: 'تنظیمات',
              icon: const Icon(Icons.settings_outlined),
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
                _ScanHero(
                  snapshot: snapshot,
                  scanning: _scanning,
                  error: _error,
                  onScan: _scan,
                ),
                if (snapshot != null) ...[
                  const SizedBox(height: 18),
                  _DeviceCard(snapshot: snapshot),
                ],
                const SizedBox(height: 24),
                const Text(
                  'وضعیت گوشی',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(item.icon, color: colors.primary),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.status,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Card(
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Icon(Icons.info_outline_rounded, color: colors.primary),
                    title: const Text(
                      'داده واقعی، بدون عدد نمایشی',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'اگر اندروید دسترسی به اطلاعاتی را محدود کند، پادرا همان مورد را «نامشخص» نمایش می‌دهد و مقدار حدسی جایگزین نمی‌کند.',
                    ),
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
        _HealthItem('آنتی‌ویروس', 'بررسی نشده', Icons.shield_outlined),
        _HealthItem('پاک‌سازی', 'بررسی نشده', Icons.cleaning_services_outlined),
        _HealthItem('باتری', 'بررسی نشده', Icons.battery_charging_full_rounded),
        _HealthItem('حافظه', 'بررسی نشده', Icons.storage_rounded),
        _HealthItem('امنیت', 'بررسی نشده', Icons.security_rounded),
        _HealthItem('برنامه‌ها', 'بررسی نشده', Icons.apps_rounded),
      ];
    }

    final storage = snapshot.usedStoragePercent == null
        ? 'نامشخص'
        : '${snapshot.usedStoragePercent!.round()}٪ استفاده شده';

    return [
      const _HealthItem('آنتی‌ویروس', 'اسکن فایل‌ها در مرحله بعد', Icons.shield_outlined),
      const _HealthItem('پاک‌سازی', 'تحلیل فایل‌ها در مرحله بعد', Icons.cleaning_services_outlined),
      _HealthItem(
        'باتری',
        '${snapshot.batteryLevel}٪ • ${snapshot.batteryState}',
        Icons.battery_charging_full_rounded,
      ),
      _HealthItem('حافظه', storage, Icons.storage_rounded),
      _HealthItem(
        'امنیت',
        snapshot.securityPatch == null
            ? 'Security Patch نامشخص'
            : 'Patch: ${snapshot.securityPatch}',
        Icons.security_rounded,
      ),
      const _HealthItem('برنامه‌ها', 'بررسی مجوزها در مرحله بعد', Icons.apps_rounded),
    ];
  }
}

class _ScanHero extends StatelessWidget {
  const _ScanHero({
    required this.snapshot,
    required this.scanning,
    required this.error,
    required this.onScan,
  });

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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.primary, width: 7),
            ),
            child: scanning
                ? Padding(
                    padding: const EdgeInsets.all(30),
                    child: CircularProgressIndicator(color: colors.primary),
                  )
                : Icon(
                    hasResult ? Icons.verified_user_rounded : Icons.shield_outlined,
                    size: 48,
                    color: colors.primary,
                  ),
          ),
          const SizedBox(height: 18),
          Text(
            scanning
                ? 'در حال بررسی گوشی…'
                : hasResult
                    ? 'اطلاعات دستگاه بررسی شد'
                    : 'هنوز گوشی بررسی نشده',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(
            error ??
                (hasResult
                    ? 'اطلاعات واقعی باتری، حافظه و نسخه امنیتی اندروید دریافت شد.'
                    : 'برای مشاهده وضعیت واقعی دستگاه، اسکن را شروع کن.'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: error == null ? colors.onSurfaceVariant : colors.error,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: scanning ? null : onScan,
              icon: Icon(hasResult ? Icons.refresh_rounded : Icons.radar_rounded),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Text(hasResult ? 'بررسی دوباره' : 'شروع بررسی کامل'),
              ),
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
    final totalStorage = snapshot.totalStorageMb;
    final freeStorage = snapshot.freeStorageMb;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smartphone_rounded, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    snapshot.deviceLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InfoRow('اندروید', '${snapshot.androidVersion} (SDK ${snapshot.sdkInt})'),
            _InfoRow(
              'وصله امنیتی',
              snapshot.securityPatch ?? 'نامشخص',
            ),
            _InfoRow('دستگاه واقعی', snapshot.isPhysicalDevice ? 'بله' : 'خیر'),
            _InfoRow(
              'حافظه',
              totalStorage == null || freeStorage == null
                  ? 'نامشخص'
                  : '${_gb(freeStorage)} GB آزاد از ${_gb(totalStorage)} GB',
            ),
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
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _HealthItem {
  const _HealthItem(this.title, this.status, this.icon);

  final String title;
  final String status;
  final IconData icon;
}
