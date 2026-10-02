import 'package:flutter/material.dart';

import '../../core/history/history_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _service = const HistoryService();
  List<HistoryEvent> _events = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final events = await _service.load();
    if (!mounted) return;
    setState(() {
      _events = events;
      _loading = false;
    });
  }

  Future<void> _clear() async {
    await _service.clear();
    if (!mounted) return;
    setState(() => _events = const []);
  }

  int get _freedBytes => _events
      .where((e) => e.type == 'cleaner' && e.value != null)
      .fold<int>(0, (sum, e) => sum + e.value!.toInt());

  int get _deviceScans => _events.where((e) => e.type == 'device').length;
  int get _securityEvents => _events.where((e) => e.type == 'antivirus').length;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تاریخچه و گزارش‌ها'),
          actions: [
            if (_events.isNotEmpty)
              IconButton(
                tooltip: 'پاک‌کردن تاریخچه',
                onPressed: _clear,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            children: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 56),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                Row(
                  children: [
                    Expanded(child: _StatCard(label: 'بررسی دستگاه', value: '$_deviceScans')),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(label: 'رویداد امنیتی', value: '$_securityEvents')),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(label: 'فضای آزادشده', value: _formatBytes(_freedBytes))),
                  ],
                ),
                const SizedBox(height: 18),
                const Text('خط زمانی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                if (_events.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'هنوز رویدادی ثبت نشده است. بعد از اسکن دستگاه، اسکن امنیتی یا پاک‌سازی، گزارش‌ها اینجا نمایش داده می‌شوند.',
                        style: TextStyle(color: colors.onSurfaceVariant, height: 1.7),
                      ),
                    ),
                  )
                else
                  ..._events.map((event) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colors.primaryContainer,
                              foregroundColor: colors.onPrimaryContainer,
                              child: Icon(_iconFor(event.type)),
                            ),
                            title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text('${event.subtitle}\n${_formatDate(event.createdAt)}'),
                            isThreeLine: true,
                          ),
                        ),
                      )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(String type) => switch (type) {
        'device' => Icons.radar_rounded,
        'cleaner' => Icons.cleaning_services_rounded,
        'antivirus' => Icons.shield_rounded,
        'network' => Icons.language_rounded,
        _ => Icons.history_rounded,
      };

  static String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}/${two(local.month)}/${two(local.day)} • ${two(local.hour)}:${two(local.minute)}';
  }

  static String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
    if (bytes >= 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '$bytes B';
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Column(
          children: [
            Text(value, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
