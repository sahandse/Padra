import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';

import '../apps/apps_page.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  Future<void> _open(String action) async {
    await AndroidIntent(action: action).launch();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final items = <_PrivacyItem>[
      _PrivacyItem(
        title: 'مجوزهای برنامه‌ها',
        subtitle: 'دوربین، میکروفون، مکان، فایل‌ها و سایر مجوزها را از تنظیمات هر برنامه بررسی کن.',
        icon: Icons.verified_user_outlined,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AppsPage()),
        ),
      ),
      _PrivacyItem(
        title: 'Accessibility',
        subtitle: 'سرویس‌هایی که دسترسی گسترده به رابط گوشی دارند را در تنظیمات سیستم بررسی کن.',
        icon: Icons.accessibility_new_rounded,
        onTap: () => _open('android.settings.ACCESSIBILITY_SETTINGS'),
      ),
      _PrivacyItem(
        title: 'نمایش روی برنامه‌ها',
        subtitle: 'برنامه‌هایی که اجازه Overlay دارند را بررسی کن.',
        icon: Icons.layers_outlined,
        onTap: () => _open('android.settings.action.MANAGE_OVERLAY_PERMISSION'),
      ),
      _PrivacyItem(
        title: 'Privacy Dashboard',
        subtitle: 'دسترسی‌های اخیر به دوربین، میکروفون و مکان را از داشبورد حریم خصوصی اندروید ببین.',
        icon: Icons.privacy_tip_outlined,
        onTap: () => _open('android.settings.PRIVACY_SETTINGS'),
      ),
      _PrivacyItem(
        title: 'نصب از منابع ناشناس',
        subtitle: 'برنامه‌هایی که امکان نصب APK خارج از فروشگاه دارند را بررسی کن.',
        icon: Icons.android_rounded,
        onTap: () => _open('android.settings.MANAGE_UNKNOWN_APP_SOURCES'),
      ),
      _PrivacyItem(
        title: 'Notification Access',
        subtitle: 'برنامه‌هایی که می‌توانند اعلان‌های دیگر برنامه‌ها را ببینند یا مدیریت کنند بررسی کن.',
        icon: Icons.notifications_active_outlined,
        onTap: () => _open('android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS'),
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('حریم خصوصی و مجوزها')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: colors.outlineVariant.withValues(alpha: .45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.privacy_tip_outlined, size: 38, color: colors.primary),
                  const SizedBox(height: 12),
                  const Text(
                    'مرکز حریم خصوصی پادرا',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'پادرا مجوزهای حساس را برایت توضیح می‌دهد و تو را مستقیم به صفحه درست اندروید می‌برد. وجود یک مجوز به‌تنهایی به معنی خطرناک بودن برنامه نیست.',
                    style: TextStyle(color: colors.onSurfaceVariant, height: 1.7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ...items.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: colors.primaryContainer,
                    foregroundColor: colors.onPrimaryContainer,
                    child: Icon(item.icon),
                  ),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(item.subtitle, style: const TextStyle(height: 1.55)),
                  ),
                  trailing: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
                  onTap: item.onTap,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: colors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'اندروید اجازه نمی‌دهد یک برنامه معمولی همه مجوزهای سایر برنامه‌ها را بدون محدودیت بخواند یا تغییر دهد. پادرا در این موارد نتیجه حدسی نمی‌دهد و مسیر بررسی دستی را باز می‌کند.',
                        style: TextStyle(color: colors.onSurfaceVariant, height: 1.65),
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
}

class _PrivacyItem {
  const _PrivacyItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}
