import 'package:flutter/material.dart';

import 'core/settings/app_settings_service.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/settings/settings_page.dart';
import 'theme/padra_theme.dart';

class PadraApp extends StatefulWidget {
  const PadraApp({super.key});

  @override
  State<PadraApp> createState() => _PadraAppState();
}

class _PadraAppState extends State<PadraApp> {
  final _settings = AppSettingsService();
  ThemeMode _themeMode = ThemeMode.system;
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final theme = await _settings.loadThemeMode();
    final onboarding = await _settings.isOnboardingDone();
    if (!mounted) return;
    setState(() {
      _themeMode = theme;
      _onboardingDone = onboarding;
    });
  }

  Future<void> _finishOnboarding() async {
    await _settings.completeOnboarding();
    if (!mounted) return;
    setState(() => _onboardingDone = true);
  }

  void _changeTheme(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          themeMode: _themeMode,
          onThemeChanged: _changeTheme,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onboardingDone = _onboardingDone;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'پادرا',
      theme: PadraTheme.light,
      darkTheme: PadraTheme.dark,
      themeMode: _themeMode,
      locale: const Locale('fa'),
      home: onboardingDone == null
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : onboardingDone
              ? Builder(
                  builder: (context) => Stack(
                    children: [
                      const DashboardPage(),
                      Positioned(
                        top: MediaQuery.paddingOf(context).top + 4,
                        left: 8,
                        child: Material(
                          color: Colors.transparent,
                          child: IconButton(
                            tooltip: 'تنظیمات',
                            onPressed: () => _openSettings(context),
                            icon: const Icon(Icons.settings_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : OnboardingPage(onDone: _finishOnboarding),
    );
  }
}
