import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'scan_result.dart';

class AntivirusService {
  static const _historyKey = 'antivirus_scan_history_v1';
  static const _maxHistory = 50;

  Future<ScanResult> scanFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const FileSystemException('File not found');
    }

    final length = await file.length();
    final digest = await sha256.bind(file.openRead()).first;
    final name = p.basename(path);
    final reasons = <String>[];
    var verdict = ScanVerdict.unknown;

    if (length == 0) {
      verdict = ScanVerdict.suspicious;
      reasons.add('فایل خالی است و ساختار معتبری برای بررسی ندارد.');
    } else if (name.toLowerCase().endsWith('.apk')) {
      if (length < 16 * 1024) {
        verdict = ScanVerdict.suspicious;
        reasons.add('حجم APK غیرعادی و بسیار کم است.');
      } else {
        verdict = ScanVerdict.unknown;
        reasons.add('هش فایل محاسبه شد؛ برای تشخیص بدافزار قطعی به پایگاه امضا یا سرویس اعتبارسنجی نیاز است.');
      }
    } else {
      verdict = ScanVerdict.unknown;
      reasons.add('نشانه محلی قطعی از بدافزار پیدا نشد، اما اسکن امضامحور هنوز متصل نشده است.');
    }

    final result = ScanResult(
      path: path,
      name: name,
      sizeBytes: length,
      sha256: digest.toString(),
      scannedAt: DateTime.now(),
      verdict: verdict,
      reasons: reasons,
    );

    await _saveResult(result);
    return result;
  }

  Future<List<ScanResult>> history() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? const [];
    final items = <ScanResult>[];
    for (final entry in raw) {
      try {
        final decoded = jsonDecode(entry) as Map<String, dynamic>;
        items.add(ScanResult.fromJson(decoded));
      } catch (_) {
        // Ignore malformed history entries rather than breaking the page.
      }
    }
    items.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return items;
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  Future<void> _saveResult(ScanResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey)?.toList() ?? <String>[];
    raw.insert(0, jsonEncode(result.toJson()));
    if (raw.length > _maxHistory) {
      raw.removeRange(_maxHistory, raw.length);
    }
    await prefs.setStringList(_historyKey, raw);
  }
}
