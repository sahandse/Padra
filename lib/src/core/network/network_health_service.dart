import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkHealthSnapshot {
  const NetworkHealthSnapshot({
    required this.connections,
    required this.hasInternet,
    required this.latencyMs,
    required this.dnsResolved,
    required this.checkedAt,
  });

  final List<ConnectivityResult> connections;
  final bool hasInternet;
  final int? latencyMs;
  final bool dnsResolved;
  final DateTime checkedAt;

  String get connectionLabel {
    if (connections.contains(ConnectivityResult.wifi)) return 'Wi‑Fi';
    if (connections.contains(ConnectivityResult.mobile)) return 'دیتای موبایل';
    if (connections.contains(ConnectivityResult.ethernet)) return 'Ethernet';
    if (connections.contains(ConnectivityResult.vpn)) return 'VPN';
    if (connections.contains(ConnectivityResult.bluetooth)) return 'Bluetooth';
    if (connections.contains(ConnectivityResult.other)) return 'سایر';
    return 'بدون اتصال';
  }
}

class NetworkHealthService {
  NetworkHealthService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<NetworkHealthSnapshot> check() async {
    final connections = await _connectivity.checkConnectivity();
    final stopwatch = Stopwatch()..start();

    var dnsResolved = false;
    var hasInternet = false;
    int? latencyMs;

    try {
      final lookup = await InternetAddress.lookup('one.one.one.one')
          .timeout(const Duration(seconds: 4));
      dnsResolved = lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } catch (_) {
      dnsResolved = false;
    }

    if (dnsResolved) {
      try {
        final socket = await Socket.connect(
          '1.1.1.1',
          443,
          timeout: const Duration(seconds: 4),
        );
        latencyMs = stopwatch.elapsedMilliseconds;
        hasInternet = true;
        await socket.close();
      } catch (_) {
        hasInternet = false;
      }
    }

    stopwatch.stop();

    return NetworkHealthSnapshot(
      connections: connections,
      hasInternet: hasInternet,
      latencyMs: latencyMs,
      dnsResolved: dnsResolved,
      checkedAt: DateTime.now(),
    );
  }

  Stream<List<ConnectivityResult>> get changes =>
      _connectivity.onConnectivityChanged;
}
