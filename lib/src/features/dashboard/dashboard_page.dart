import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const _items = <_HealthItem>[
    _HealthItem('آنتی‌ویروس', 'بررسی نشده', Icons.shield_outlined),
    _HealthItem('پاک‌سازی', 'بررسی نشده', Icons.cleaning_services_outlined),
    _HealthItem('باتری', 'بررسی نشده', Icons.battery_charging_full_rounded),
    _HealthItem('حافظه', 'بررسی نشده', Icons.storage_rounded),
    _HealthItem('امنیت', 'بررسی نشده', Icons.security_rounded),
    _HealthItem('برنامه‌ها', 'بررسی نشده', Icons.apps_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
              onPressed: () {},
              tooltip: 'تنظیمات',
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              Container(
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
                      child: Icon(Icons.shield_outlined, size: 48, color: colors.primary),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'هنوز گوشی بررسی نشده',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'برای مشاهده وضعیت واقعی امنیت، باتری، حافظه و برنامه‌ها اسکن را شروع کن.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onSurfaceVariant, height: 1.7),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.radar_rounded),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 13),
                          child: Text('شروع بررسی کامل'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'وضعیت گوشی',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (context, index) {
                  final item = _items[index];
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
                              Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 3),
                              Text(
                                item.status,
                                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Icon(Icons.info_outline_rounded, color: colors.primary),
                  title: const Text('پادرا چه کاری انجام می‌دهد؟', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text(
                    'فقط عملیات مجاز اندروید را انجام می‌دهد و برای تنظیمات محدودشده، مسیر دقیق اصلاح را نمایش می‌دهد.',
                  ),
                ),
              ),
            ],
          ),
        ),
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
