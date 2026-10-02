import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/core/background/background_health_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundHealthService.initialize();
  runApp(const PadraApp());
}
