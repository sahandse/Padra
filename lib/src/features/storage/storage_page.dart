import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/device/device_scan_service.dart';
import '../../core/device/device_snapshot.dart';
import '../../core/storage/storage_analysis.dart';
import '../../core/storage/storage_service.dart';

class StoragePage extends StatefulWidget {
  const StoragePage({super.key});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage> {
  final _storageService = StorageService();
  final _deviceService = DeviceScanService();

  StorageAnalysis? _analysis;
  DeviceSnapshot? _device;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDevice();
  }

  Future<void> _loadDevice() async {
    try {
      final device = await _deviceService.scan();
      if (!mounted) return;
      setState(() => _device = device);
    } catch (_) {}
  }

  Future<void> _pickAndAnalyze() async {
    final path = await FilePicker.platform.getDirectoryPath(dialogTitle: 'انتخاب پوشه برای تحلیل حافظه');
    if (path == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _storageService.analyzeDirectory(path);
      if (!mounted) return;
      setState(() => _analysis = result);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'تحلیل این پوشه کامل نشد. پوشه دیگری انتخاب کن.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final analysis = _analysis;
    final device = _device;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مدیریت حافظه')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.storage_rounded, color: colors.primary),
                        const SizedBox(width: 8),
                        const Text('فضای دستگاه', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (device?.totalStorageMb != null && device?.freeStorageMb != null) ...[
                      Text(
                        '${_gb(device!.freeStorageMb!)} GB آزاد از ${_gb(device.totalStorageMb!)} GB',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(value: (device.usedStoragePercent ?? 0) / 100),
                      const SizedBox(height: 8),
                      Text('${device.usedStoragePercent?.round() ?? 0}٪ استفاده شده', style: TextStyle(color: colors.onSurfaceVariant)),
                    ] else
                      Text('اطلاعات فضای دستگاه در دسترس نیست.', style: TextStyle(color: colors.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _pickAndAnalyze,
                icon: const Icon(Icons.folder_open_rounded),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Text(_loading ? 'در حال تحلیل…' : 'انتخاب پوشه و تحلیل'),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: colors.error)),
            ],
            if (analysis != null) ...[
              const SizedBox(height: 22),
              _SummaryCard(analysis: analysis),
              const SizedBox(height: 22),
              const Text('دسته‌بندی فضا', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              ...analysis.categories.map((item) => _CategoryTile(item: item, totalBytes: analysis.scannedBytes)),
              const SizedBox(height: 22),
              const Text('بزرگ‌ترین فایل‌ها', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              ...analysis.largestFiles.map((file) => Card(
                    child: ListTile(
                      leading: Icon(_iconFor(file.category), color: colors.primary),
                      title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(file.path, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Text(_formatBytes(file.sizeBytes), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  )),
            ],
            const SizedBox(height: 18),
            Card(
              child: ListTile(
                leading: Icon(Icons.info_outline_rounded, color: colors.primary),
                title: const Text('تحلیل بدون حذف خودکار', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('این بخش فقط فضا را تحلیل می‌کند. برای حذف فایل‌ها از بخش پاک‌سازی استفاده کن.'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _gb(double mb) => (mb / 1024).toStringAsFixed(1);
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.analysis});
  final StorageAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(child: _Metric(label: 'فایل', value: '${analysis.scannedFiles}')),
            Expanded(child: _Metric(label: 'حجم تحلیل‌شده', value: _formatBytes(analysis.scannedBytes))),
            Expanded(child: _Metric(label: 'دسته', value: '${analysis.categories.length}')),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.item, required this.totalBytes});
  final StorageCategoryStat item;
  final int totalBytes;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ratio = totalBytes <= 0 ? 0.0 : item.totalBytes / totalBytes;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Icon(_iconFor(item.category), color: colors.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(_labelFor(item.category), style: const TextStyle(fontWeight: FontWeight.w700))),
                Text(_formatBytes(item.totalBytes)),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: ratio.clamp(0, 1)),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text('${item.fileCount} فایل • ${(ratio * 100).toStringAsFixed(1)}٪', style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }
}

String _labelFor(StorageCategory category) => switch (category) {
      StorageCategory.image => 'تصاویر',
      StorageCategory.video => 'ویدیوها',
      StorageCategory.audio => 'صدا و موسیقی',
      StorageCategory.document => 'اسناد',
      StorageCategory.apk => 'فایل‌های نصب',
      StorageCategory.archive => 'فایل‌های فشرده',
      StorageCategory.other => 'سایر',
    };

IconData _iconFor(StorageCategory category) => switch (category) {
      StorageCategory.image => Icons.image_outlined,
      StorageCategory.video => Icons.movie_outlined,
      StorageCategory.audio => Icons.music_note_rounded,
      StorageCategory.document => Icons.description_outlined,
      StorageCategory.apk => Icons.android_rounded,
      StorageCategory.archive => Icons.archive_outlined,
      StorageCategory.other => Icons.insert_drive_file_outlined,
    };

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  final mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
  return '${(mb / 1024).toStringAsFixed(2)} GB';
}
