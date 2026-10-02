import 'dart:async';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';

import '../../core/network/network_health_service.dart';

class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  final NetworkHealthService _service = NetworkHealthService();
  NetworkHealthSnapshot? _snapshot;
  StreamSubscription? _subscription;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _check();
    _subscription = _service.changes.listen((_) => _check());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot = await _service.check();
      if (!mounted) return;
      setState(() => _snapshot = snapshot);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'بررسی شبکه کامل نشد.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openNetworkSettings() async {
    const intent = AndroidIntent(action: 'android.settings.WIRELESS_SETTINGS');
    await intent.launch();
  }

  Future<void> _openWifiSettings() async {
    const intent = AndroidIntent(action: 'android.settings.WIFI_SETTINGS');
    await intent.launch();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final snapshot = _snapshot;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('سلامت شبکه و اینترنت')),
        body: RefreshIndicator(
          onRefresh: _check,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        snapshot?.hasInternet == true
                            ? Icons.language_rounded
                            : Icons.public_off_rounded,
                        size: 54,
                        color: snapshot?.hasInternet == true
                            ? colors.primary
                            : colors.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _loading
                            ? 'در حال بررسی شبکه…'
                            : snapshot?.hasInternet == true
                                ? 'اینترنت در دسترس است'
                                : 'دسترسی اینترنت تأیید نشد',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _error ??
                            'پادرا نوع اتصال، DNS و یک اتصال واقعی شبکه را جداگانه بررسی می‌کند.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          height: 1.6,
                          color: _error == null
                              ? colors.onSurfaceVariant
                              : colors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (snapshot != null) ...[
                const SizedBox(height: 12),
                _InfoCard(
                  children: [
                    _InfoRow('نوع اتصال', snapshot.connectionLabel),
                    _InfoRow(
                      'DNS',
                      snapshot.dnsResolved ? 'پاسخ می‌دهد' : 'پاسخ تأیید نشد',
                    ),
                    _InfoRow(
                      'اینترنت',
                      snapshot.hasInternet ? 'فعال' : 'تأیید نشد',
                    ),
                    _InfoRow(
                      'تأخیر پایه',
                      snapshot.latencyMs == null
                          ? 'نامشخص'
                          : '${snapshot.latencyMs} ms',
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'ابزارهای شبکه',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: _check,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('بررسی دوباره'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _openWifiSettings,
                        icon: const Icon(Icons.wifi_rounded),
                        label: const Text('تنظیمات Wi‑Fi'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _openNetworkSettings,
                        icon: const Icon(Icons.settings_ethernet_rounded),
                        label: const Text('تنظیمات شبکه'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline_rounded, color: colors.primary),
                  title: const Text(
                    'پادرا سرعت را افزایش نمی‌دهد',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'این بخش فقط وضعیت واقعی اتصال را بررسی می‌کند و نتیجه‌ای مثل «بوست اینترنت» نمایش نمی‌دهد.',
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
