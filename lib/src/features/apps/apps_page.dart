import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';

import '../../core/apps/app_analyzer_service.dart';

class AppsPage extends StatefulWidget {
  const AppsPage({super.key});

  @override
  State<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends State<AppsPage> {
  final _service = const AppAnalyzerService();

  AppInventory? _inventory;
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.scan();
      if (!mounted) return;
      setState(() => _inventory = result);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'خواندن فهرست برنامه‌ها کامل نشد.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<AppInfo> get _visibleApps {
    final apps = _inventory?.userApps ?? const <AppInfo>[];
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return apps;
    return apps
        .where(
          (app) =>
              app.name.toLowerCase().contains(query) ||
              app.packageName.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final inventory = _inventory;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('برنامه‌ها')),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline_rounded, color: colors.error),
                        const SizedBox(height: 8),
                        Text(_error!),
                        const SizedBox(height: 10),
                        FilledButton(onPressed: _load, child: const Text('تلاش دوباره')),
                      ],
                    ),
                  ),
                )
              else if (inventory != null) ...[
                Row(
                  children: [
                    Expanded(child: _StatCard(label: 'کاربری', value: inventory.userApps.length.toString())),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(label: 'سیستمی', value: inventory.systemApps.length.toString())),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(label: 'قابل اجرا', value: inventory.launchableApps.length.toString())),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'جستجو در برنامه‌ها',
                    prefixIcon: Icon(Icons.search_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'نمایش برنامه به معنی خطرناک بودن آن نیست؛ پادرا در این صفحه فقط موجودی واقعی دستگاه را نشان می‌دهد.',
                  style: TextStyle(fontSize: 12, height: 1.6, color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                ..._visibleApps.map(
                  (app) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colors.primaryContainer,
                        foregroundColor: colors.onPrimaryContainer,
                        child: const Icon(Icons.android_rounded),
                      ),
                      title: Text(app.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${app.packageName}\nنسخه ${app.versionName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: () => _service.openSettings(app.packageName),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
