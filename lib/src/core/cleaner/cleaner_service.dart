import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'cleaner_item.dart';

class CleanerScanResult {
  const CleanerScanResult({
    required this.rootPath,
    required this.items,
    required this.totalBytes,
    required this.scannedFiles,
  });

  final String rootPath;
  final List<CleanerItem> items;
  final int totalBytes;
  final int scannedFiles;

  int get reclaimableBytes => items.fold(0, (sum, item) => sum + item.sizeBytes);
}

class CleanerService {
  static const int _largeFileThreshold = 100 * 1024 * 1024;
  static const int _maxDuplicateHashFileSize = 1024 * 1024 * 1024;

  Future<CleanerScanResult> scanDirectory(String rootPath) async {
    final root = Directory(rootPath);
    if (!await root.exists()) {
      throw FileSystemException('پوشه در دسترس نیست', rootPath);
    }

    final files = <File>[];
    int scannedFiles = 0;
    int totalBytes = 0;

    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      try {
        final length = await entity.length();
        scannedFiles++;
        totalBytes += length;
        files.add(entity);
      } on FileSystemException {
        continue;
      }
    }

    final sizeGroups = <int, List<File>>{};
    for (final file in files) {
      try {
        final length = await file.length();
        if (length > 0 && length <= _maxDuplicateHashFileSize) {
          sizeGroups.putIfAbsent(length, () => []).add(file);
        }
      } on FileSystemException {
        continue;
      }
    }

    final duplicateGroupsByPath = <String, String>{};
    for (final entry in sizeGroups.entries.where((e) => e.value.length > 1)) {
      final hashGroups = <String, List<File>>{};
      for (final file in entry.value) {
        try {
          final digest = await sha256.bind(file.openRead()).first;
          hashGroups.putIfAbsent(digest.toString(), () => []).add(file);
        } catch (_) {
          continue;
        }
      }
      for (final group in hashGroups.entries.where((e) => e.value.length > 1)) {
        final groupId = '${entry.key}-${group.key.substring(0, 12)}';
        for (final file in group.value) {
          duplicateGroupsByPath[file.path] = groupId;
        }
      }
    }

    final items = <CleanerItem>[];
    for (final file in files) {
      try {
        final stat = await file.stat();
        final lowerName = p.basename(file.path).toLowerCase();
        final inDownloads = p.split(file.path).any(
              (segment) => segment.toLowerCase() == 'download' || segment.toLowerCase() == 'downloads',
            );
        final duplicateGroup = duplicateGroupsByPath[file.path];

        final category = duplicateGroup != null
            ? CleanerCategory.duplicate
            : lowerName.endsWith('.apk')
                ? CleanerCategory.apk
                : stat.size >= _largeFileThreshold
                    ? CleanerCategory.largeFile
                    : inDownloads
                        ? CleanerCategory.download
                        : CleanerCategory.other;

        if (category == CleanerCategory.other) continue;

        items.add(
          CleanerItem(
            path: file.path,
            name: p.basename(file.path),
            sizeBytes: stat.size,
            category: category,
            modifiedAt: stat.modified,
            duplicateGroup: duplicateGroup,
          ),
        );
      } catch (_) {
        continue;
      }
    }

    items.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    return CleanerScanResult(
      rootPath: rootPath,
      items: items,
      totalBytes: totalBytes,
      scannedFiles: scannedFiles,
    );
  }

  Future<int> deleteSelected(Iterable<CleanerItem> items) async {
    var freed = 0;
    for (final item in items) {
      final file = File(item.path);
      if (!await file.exists()) continue;
      try {
        final size = await file.length();
        await file.delete();
        freed += size;
      } on FileSystemException {
        continue;
      }
    }
    return freed;
  }
}
