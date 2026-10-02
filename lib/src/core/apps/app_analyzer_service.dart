import 'package:installed_apps/installed_apps.dart';

class AppAnalyzerService {
  const AppAnalyzerService();

  Future<AppInventory> scan() async {
    final apps = await InstalledApps.getInstalledApps(
      excludeSystemApps: false,
      excludeNonLaunchableApps: false,
      withIcon: false,
    );

    final userApps = apps.where((app) => !app.isSystemApp).toList(growable: false);
    final systemApps = apps.where((app) => app.isSystemApp).toList(growable: false);
    final launchableApps = apps.where((app) => app.isLaunchableApp).toList(growable: false);

    userApps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return AppInventory(
      allApps: apps,
      userApps: userApps,
      systemApps: systemApps,
      launchableApps: launchableApps,
    );
  }

  Future<void> openSettings(String packageName) async {
    InstalledApps.openSettings(packageName);
  }
}

class AppInventory {
  const AppInventory({
    required this.allApps,
    required this.userApps,
    required this.systemApps,
    required this.launchableApps,
  });

  final List<AppInfo> allApps;
  final List<AppInfo> userApps;
  final List<AppInfo> systemApps;
  final List<AppInfo> launchableApps;
}
