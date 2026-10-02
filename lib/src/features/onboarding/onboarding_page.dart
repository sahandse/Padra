import 'package:flutter/material.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onDone});

  final Future<void> Function() onDone;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;
  bool _finishing = false;

  static const _pages = [
    _OnboardingData(
      icon: Icons.shield_rounded,
      title: 'پادرا؛ امنیت و سلامت گوشی',
      body: 'وضعیت دستگاه را با داده‌های واقعی بررسی کن؛ بدون امتیاز یا هشدار ساختگی.',
    ),
    _OnboardingData(
      icon: Icons.privacy_tip_outlined,
      title: 'حریم خصوصی اولویت دارد',
      body: 'تاریخچه و تنظیمات روی خود گوشی می‌مانند و فقط وقتی لازم باشد مجوز درخواست می‌شود.',
    ),
    _OnboardingData(
      icon: Icons.tune_rounded,
      title: 'کنترل دست خودت است',
      body: 'پاک‌سازی، اسکن فایل و تغییر تنظیمات فقط با انتخاب یا تأیید خودت انجام می‌شود.',
    ),
  ];

  Future<void> _next() async {
    if (_index < _pages.length - 1) {
      await _controller.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
      return;
    }
    if (_finishing) return;
    setState(() => _finishing = true);
    await widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) {
                    final item = _pages[index];
                    return Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(38),
                            ),
                            child: Icon(item.icon, size: 62, color: colors.onPrimaryContainer),
                          ),
                          const SizedBox(height: 28),
                          Text(item.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 12),
                          Text(item.body, textAlign: TextAlign.center, style: TextStyle(height: 1.8, color: colors.onSurfaceVariant)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: i == _index ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: i == _index ? colors.primary : colors.outlineVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      )),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _finishing ? null : _next,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(_index == _pages.length - 1 ? 'شروع استفاده از پادرا' : 'ادامه'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
}
