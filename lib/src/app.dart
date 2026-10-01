import 'package:flutter/material.dart';

import 'features/dashboard/dashboard_page.dart';
import 'theme/padra_theme.dart';

class PadraApp extends StatelessWidget {
  const PadraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'پادرا',
      theme: PadraTheme.light,
      darkTheme: PadraTheme.dark,
      themeMode: ThemeMode.system,
      locale: const Locale('fa'),
      home: const DashboardPage(),
    );
  }
}
