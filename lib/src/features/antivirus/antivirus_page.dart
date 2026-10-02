import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/history/history_service.dart';
import 'antivirus_service.dart';
import 'scan_result.dart';

class AntivirusPage extends StatefulWidget {
  const AntivirusPage({super.key});

  @override
  State<AntivirusPage> createState() => _AntivirusPageState();
}

class _AntivirusPageState extends State<AntivirusPage> {
  final AntivirusService _service = AntivirusService();
  final HistoryService _historyService = const HistoryService();
  bool _scanning = false;
  String? _error;
  ScanResult? _latest;
  List<ScanResult> _history = const [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final items = await _service.history();
    if (!mounted) return;
    setState(() => _history = items);
  }

  Future<void> _pickAndScan() async {
    if (_scanning) return;
    setState(() {
      _scanning = true;
      _error = null;
    });
    try {
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: false,
        type: FileType.any,
      );
      if (picked == null) return;
      final path = picked.files.single.path;
      if (path == null) {
        throw StateError('File path unavailable');
      }
      final result = await _service.scanFile(path);
      await _historyService.add(
        HistoryEvent(
          type: 'antivirus',
          title: 'اسکن امنیتی فایل',
          subtitle: '${result.name} • ${_verdictLabel(result.verdict)}',
          createdAt: DateTime.now(),
          value: result.sizeBytes,
        ),
      );
      if (!mounted) return;
      setState(() => _latest = result);
      await _loadHistory();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'اسکن فایل کامل نشد. دوباره تلاش کن.');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _clearHistory() async {
    await _service.clearHistory();
    if (!mounted) return;
    setState(() {
      _history = const [];
      _latest = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('آنتی‌ویروس پادرا'),
          actions: [
            if (_history.isNotEmpty)
              IconButton(
                onPressed: _clearHistory,
                tooltip: 'پاک‌کردن تاریخچه',
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.shield_rounded, size: 54, color: colors.primary),
                    const SizedBox(height: 12),
                    const Text('اسکن فایل و APK', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      'پادرا فایل را روی خود گوشی بررسی می‌کند، SHA-256 می‌سازد و نتیجه را بدون حذف خودکار نمایش می‌دهد.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onSurfaceVariant, height: 1.7),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _scanning ? null : _pickAndScan,
                        icon: _scanning
                            ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.file_open_rounded),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          child: Text(_scanning ? 'در حال اسکن…' : 'انتخاب فایل برای اسکن'),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: colors.error)),
                    ],
                  ],
                ),
              ),
            ),
            if (_latest != null) ...[
              const SizedBox(height: 18),
              _ResultCard(result: _latest!),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(child: Text('تاریخچه اسکن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                Text('${_history.length} مورد', style: TextStyle(color: colors.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 10),
            if (_history.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text('هنوز فایلی اسکن نشده است.', style: TextStyle(color: colors.onSurfaceVariant)),
                ),
              )
            else
              ..._history.take(10).map((result) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HistoryTile(result: result),
                  )),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(Icons.info_outline_rounded, color: colors.primary),
                title: const Text('نتیجه «نامشخص» یعنی چه؟', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('نبودن نشانه محلی به‌تنهایی اثبات سالم‌بودن فایل نیست. برای تشخیص قطعی‌تر باید پایگاه امضای بدافزار یا سرویس اعتبارسنجی متصل شود.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final ScanResult result;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final meta = _verdictMeta(result.verdict, colors);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(meta.icon, color: meta.color),
              const SizedBox(width: 8),
              Expanded(child: Text(meta.label, style: TextStyle(fontWeight: FontWeight.w800, color: meta.color))),
            ]),
            const SizedBox(height: 14),
            Text(result.name, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('حجم: ${_formatBytes(result.sizeBytes)}'),
            const SizedBox(height: 6),
            const Text('SHA-256', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            SelectableText(result.sha256, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
            const SizedBox(height: 12),
            ...result.reasons.map((reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('• '),
                    Expanded(child: Text(reason)),
                  ]),
                )),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.result});
  final ScanResult result;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final meta = _verdictMeta(result.verdict, colors);
    return Card(
      child: ListTile(
        leading: Icon(meta.icon, color: meta.color),
        title: Text(result.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${meta.label} • ${_formatBytes(result.sizeBytes)}'),
      ),
    );
  }
}

class _VerdictMeta {
  const _VerdictMeta(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

_VerdictMeta _verdictMeta(ScanVerdict verdict, ColorScheme colors) {
  return switch (verdict) {
    ScanVerdict.safe => _VerdictMeta('بدون نشانه محلی', Icons.verified_user_rounded, colors.primary),
    ScanVerdict.suspicious => _VerdictMeta('مشکوک', Icons.warning_amber_rounded, colors.error),
    ScanVerdict.unknown => _VerdictMeta('نامشخص', Icons.help_outline_rounded, colors.tertiary),
  };
}

String _verdictLabel(ScanVerdict verdict) => switch (verdict) {
      ScanVerdict.safe => 'بدون نشانه محلی',
      ScanVerdict.suspicious => 'مشکوک',
      ScanVerdict.unknown => 'نامشخص',
    };

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
