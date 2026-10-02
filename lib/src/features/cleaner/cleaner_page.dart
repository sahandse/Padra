import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/cleaner/cleaner_item.dart';
import '../../core/cleaner/cleaner_service.dart';
import '../../core/history/history_service.dart';

class CleanerPage extends StatefulWidget {
  const CleanerPage({super.key});

  @override
  State<CleanerPage> createState() => _CleanerPageState();
}

class _CleanerPageState extends State<CleanerPage> {
  final CleanerService _service = CleanerService();
  final HistoryService _history = const HistoryService();
  CleanerScanResult? _result;
  final Set<String> _selected = {};
  bool _scanning = false;
  bool _deleting = false;
  String? _error;

  Future<void> _pickAndScan() async {
    if (_scanning) return;
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'پوشه موردنظر برای بررسی را انتخاب کن',
    );
    if (path == null || !mounted) return;

    setState(() {
      _scanning = true;
      _error = null;
      _selected.clear();
    });

    try {
      final result = await _service.scanDirectory(path);
      if (!mounted) return;
      setState(() => _result = result);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'این پوشه کامل قابل خواندن نیست. یک پوشه دیگر انتخاب کن.');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  int get _selectedBytes {
    final result = _result;
    if (result == null) return 0;
    return result.items
        .where((item) => _selected.contains(item.path))
        .fold(0, (sum, item) => sum + item.sizeBytes);
  }

  Future<void> _deleteSelected() async {
    final result = _result;
    if (result == null || _selected.isEmpty || _deleting) return;

    final count = _selected.length;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف فایل‌های انتخاب‌شده؟'),
        content: Text(
          '$count فایل با حجم حدود ${_formatBytes(_selectedBytes)} حذف می‌شود. این عملیات قابل بازگشت نیست.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;

    setState(() => _deleting = true);
    final targets = result.items.where((item) => _selected.contains(item.path));
    final freed = await _service.deleteSelected(targets);
    if (freed > 0) {
      await _history.add(
        HistoryEvent(
          type: 'cleaner',
          title: 'پاک‌سازی انجام شد',
          subtitle: '${_formatBytes(freed)} فضا با تأیید کاربر آزاد شد.',
          createdAt: DateTime.now(),
          value: freed,
        ),
      );
    }
    if (!mounted) return;

    setState(() {
      _selected.clear();
      _deleting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_formatBytes(freed)} فضا آزاد شد.')),
    );

    try {
      final refreshed = await _service.scanDirectory(result.rootPath);
      if (!mounted) return;
      setState(() => _result = refreshed);
    } catch (_) {
      // If the directory is no longer available, keep the previous result visible.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final result = _result;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('پاک‌سازی هوشمند')),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.cleaning_services_rounded, color: colors.primary),
                                const SizedBox(width: 8),
                                const Text(
                                  'تحلیل امن فایل‌ها',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'پادرا فقط پوشه‌ای را بررسی می‌کند که خودت انتخاب می‌کنی. چیزی بدون انتخاب و تأیید تو حذف نمی‌شود.',
                              style: TextStyle(color: colors.onSurfaceVariant, height: 1.7),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _scanning ? null : _pickAndScan,
                                icon: _scanning
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.folder_open_rounded),
                                label: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(_scanning ? 'در حال بررسی…' : 'انتخاب پوشه و شروع بررسی'),
                                ),
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 10),
                              Text(_error!, style: TextStyle(color: colors.error)),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (result != null) ...[
                      const SizedBox(height: 16),
                      _SummaryCard(result: result),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'موارد پیدا شده',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                          ),
                          Text('${result.items.length} مورد'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (result.items.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline_rounded, color: colors.primary),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text('در این پوشه فایل بزرگ، APK یا فایل تکراری قابل پیشنهاد پیدا نشد.'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...result.items.map((item) {
                          final checked = _selected.contains(item.path);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: CheckboxListTile(
                              value: checked,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selected.add(item.path);
                                  } else {
                                    _selected.remove(item.path);
                                  }
                                });
                              },
                              secondary: CircleAvatar(
                                child: Icon(_iconFor(item.category)),
                              ),
                              title: Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                '${item.category.label} • ${_formatBytes(item.sizeBytes)}\n${item.path}',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          );
                        }),
                    ],
                  ],
                ),
              ),
              if (_selected.isNotEmpty)
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border(top: BorderSide(color: colors.outlineVariant)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _deleting ? null : _deleteSelected,
                        icon: _deleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_outline_rounded),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'حذف ${_selected.length} مورد • ${_formatBytes(_selectedBytes)}',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(CleanerCategory category) => switch (category) {
        CleanerCategory.largeFile => Icons.video_file_outlined,
        CleanerCategory.apk => Icons.android_rounded,
        CleanerCategory.download => Icons.download_rounded,
        CleanerCategory.duplicate => Icons.copy_all_rounded,
        CleanerCategory.other => Icons.insert_drive_file_outlined,
      };

  static String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '$bytes B';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.result});

  final CleanerScanResult result;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('خلاصه بررسی', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            _SummaryRow('فایل‌های بررسی‌شده', '${result.scannedFiles}'),
            _SummaryRow('حجم کل پوشه', _CleanerPageState._formatBytes(result.totalBytes)),
            _SummaryRow('موارد پیشنهادی', '${result.items.length}'),
            _SummaryRow('حجم موارد پیشنهادی', _CleanerPageState._formatBytes(result.reclaimableBytes)),
            const SizedBox(height: 8),
            Text(
              'حجم پیشنهادی به معنی «زباله قطعی» نیست؛ قبل از حذف، فایل‌ها را خودت انتخاب می‌کنی.',
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
