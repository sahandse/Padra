import 'package:flutter/material.dart';

import '../../core/device/device_snapshot.dart';
import '../antivirus/antivirus_page.dart';
import '../apps/apps_page.dart';
import '../battery/battery_page.dart';
import '../cleaner/cleaner_page.dart';
import '../security/security_page.dart';
import '../storage/storage_page.dart';

class OptimizationPage extends StatelessWidget {
  const OptimizationPage({super.key, required this.snapshot});

  final DeviceSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final checks = _checks(snapshot);
    final known = checks.where((e) => e.state != _CheckState.unknown).length;
    final attention = checks.where((e) => e.state == _CheckState.attention).length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مرکز بهینه‌سازی')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            _SummaryCard(
              knownChecks: known,
              attentionCount: attention,
              hasSnapshot: snapshot != null,
            ),
            const SizedBox(height: 18),
            const Text(
              'وضعیت‌ها',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ...checks.map((check) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CheckCard(
                    check: check,
                    onTap: check.destination == null
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => check.destination!),
                            ),
                  ),
                )),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'پادرا RAM Booster یا Task Killer ساختگی اجرا نمی‌کند. اندروید مدیریت حافظه و پردازش‌ها را انجام می‌دهد و بستن اجباری برنامه‌ها می‌تواند مصرف باتری را بیشتر کند.',
                        style: TextStyle(height: 1.65),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_OptimizationCheck> _checks(DeviceSnapshot? data) {
    final checks = <_OptimizationCheck>[
      _OptimizationCheck(
        title: 'آنتی‌ویروس',
        detail: 'برای بررسی فایل یا APK اسکن را اجرا کن.',
        icon: Icons.shield_outlined,
        state: _CheckState.unknown,
        destination: const AntivirusPage(),
      ),
      _OptimizationCheck(
        title: 'پاک‌سازی',
        detail: 'فایل‌های بزرگ، قدیمی و تکراری را بررسی کن.',
        icon: Icons.cleaning_services_outlined,
        state: _CheckState.unknown,
        destination: const CleanerPage(),
      ),
      _OptimizationCheck(
        title: 'برنامه‌ها',
        detail: 'فهرست برنامه‌ها و تنظیمات هر برنامه را بررسی کن.',
        icon: Icons.apps_rounded,
        state: _CheckState.unknown,
        destination: const AppsPage(),
      ),
    ];

    if (data == null) {
      return [
        ...checks,
        const _OptimizationCheck(
          title: 'باتری',
          detail: 'ابتدا بررسی کامل دستگاه را از صفحه اصلی اجرا کن.',
          icon: Icons.battery_charging_full_rounded,
          state: _CheckState.unknown,
          destination: BatteryPage(),
        ),
        const _OptimizationCheck(
          title: 'حافظه',
          detail: 'ابتدا بررسی کامل دستگاه را از صفحه اصلی اجرا کن.',
          icon: Icons.storage_rounded,
          state: _CheckState.unknown,
          destination: StoragePage(),
        ),
        const _OptimizationCheck(
          title: 'امنیت اندروید',
          detail: 'ابتدا بررسی کامل دستگاه را از صفحه اصلی اجرا کن.',
          icon: Icons.security_rounded,
          state: _CheckState.unknown,
          destination: SecurityPage(),
        ),
      ];
    }

    final batteryNeedsAttention = data.batteryLevel <= 20 &&
        data.batteryState != 'در حال شارژ' &&
        data.batteryState != 'شارژ کامل';

    final storagePercent = data.usedStoragePercent;
    final storageNeedsAttention = storagePercent != null && storagePercent >= 90;

    final patchAge = _patchAgeInDays(data.securityPatch);
    final patchNeedsAttention = patchAge != null && patchAge > 180;

    checks.addAll([
      _OptimizationCheck(
        title: 'باتری',
        detail: batteryNeedsAttention
            ? 'شارژ باتری ${data.batteryLevel}٪ است و دستگاه در حال شارژ نیست.'
            : 'شارژ ${data.batteryLevel}٪ • ${data.batteryState}',
        icon: Icons.battery_charging_full_rounded,
        state: batteryNeedsAttention ? _CheckState.attention : _CheckState.ok,
        destination: const BatteryPage(),
      ),
      _OptimizationCheck(
        title: 'حافظه',
        detail: storagePercent == null
            ? 'میزان فضای مصرف‌شده از اندروید دریافت نشد.'
            : storageNeedsAttention
                ? '${storagePercent.round()}٪ حافظه پر شده؛ بهتر است فایل‌های حجیم را بررسی کنی.'
                : '${storagePercent.round()}٪ حافظه استفاده شده است.',
        icon: Icons.storage_rounded,
        state: storagePercent == null
            ? _CheckState.unknown
            : storageNeedsAttention
                ? _CheckState.attention
                : _CheckState.ok,
        destination: const StoragePage(),
      ),
      _OptimizationCheck(
        title: 'امنیت اندروید',
        detail: data.securityPatch == null
            ? 'تاریخ وصله امنیتی گزارش نشد.'
            : patchNeedsAttention
                ? 'وصله امنیتی ${data.securityPatch} قدیمی‌تر از حدود ۶ ماه است.'
                : 'وصله امنیتی: ${data.securityPatch}',
        icon: Icons.security_rounded,
        state: data.securityPatch == null
            ? _CheckState.unknown
            : patchNeedsAttention
                ? _CheckState.attention
                : _CheckState.ok,
        destination: const SecurityPage(),
      ),
    ]);

    return checks;
  }

  int? _patchAgeInDays(String? patch) {
    if (patch == null || patch.isEmpty) return null;
    final date = DateTime.tryParse(patch);
    if (date == null) return null;
    return DateTime.now().difference(date).inDays;
  }
}

enum _CheckState { ok, attention, unknown }

class _OptimizationCheck {
  const _OptimizationCheck({
    required this.title,
    required this.detail,
    required this.icon,
    required this.state,
    this.destination,
  });

  final String title;
  final String detail;
  final IconData icon;
  final _CheckState state;
  final Widget? destination;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.knownChecks,
    required this.attentionCount,
    required this.hasSnapshot,
  });

  final int knownChecks;
  final int attentionCount;
  final bool hasSnapshot;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final headline = !hasSnapshot
        ? 'نیاز به اسکن دستگاه'
        : attentionCount == 0
            ? 'در بررسی‌های فعلی مورد فوری دیده نشد'
            : '$attentionCount مورد نیاز به توجه دارد';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .45)),
      ),
      child: Column(
        children: [
          Icon(Icons.bolt_rounded, size: 48, color: colors.primary),
          const SizedBox(height: 12),
          Text(headline, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            hasSnapshot
                ? '$knownChecks بررسی بر اساس داده‌های واقعی دستگاه انجام شده است.'
                : 'برای تحلیل باتری، حافظه و امنیت ابتدا از صفحه اصلی «بررسی کامل» را اجرا کن.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _CheckCard extends StatelessWidget {
  const _CheckCard({required this.check, this.onTap});

  final _OptimizationCheck check;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (label, icon, color) = switch (check.state) {
      _CheckState.ok => ('مناسب', Icons.check_circle_outline_rounded, colors.primary),
      _CheckState.attention => ('نیاز به توجه', Icons.warning_amber_rounded, colors.tertiary),
      _CheckState.unknown => ('نیاز به بررسی', Icons.help_outline_rounded, colors.onSurfaceVariant),
    };

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(check.icon, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(check.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(check.detail, style: TextStyle(color: colors.onSurfaceVariant, height: 1.45)),
                    const SizedBox(height: 7),
                    Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 5), Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700))]),
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
