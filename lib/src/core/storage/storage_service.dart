import 'dart:io';

import 'package:path/path.dart' as p;

import 'storage_analysis.dart';

class StorageService {
  Future<StorageAnalysis> analyzeDirectory(String rootPath) async {
    final root = Directory(rootPath);
    if (!await root.exists()) {
      throw FileSystemException('پوشه در دسترس نیست', rootPath);
    }

    final counts = <StorageCategory, int>{};
    final sizes = <StorageCategory, int>{};
    final largest = <StorageFileEntry>[];

    var scannedFiles = 0;
    var scannedBytes = 0;

    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      try {
        final stat = await entity.stat();
        final category = _categoryFor(entity.path);
        scannedFiles++;
        scannedBytes += stat.size;
        counts[category] = (counts[category] ?? 0) + 1;
        sizes[category] = (sizes[category] ?? 0) + stat.size;

        largest.add(
          StorageFileEntry(
            path: entity.path,
            name: p.basename(entity.path),
            sizeBytes: stat.size,
            category: category,
            modifiedAt: stat.modified,
          ),
        );
      } on FileSystemException {
        continue;
      }
    }

    largest.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    final categories = StorageCategory.values
        .map(
          (category) => StorageCategoryStat(
            category: category,
            fileCount: counts[category] ?? 0,
            totalBytes: sizes[category] ?? 0,
          ),
        )
        .where((item) => item.fileCount > 0)
        .toList()
      ..sort((a, b) => b.totalBytes.compareTo(a.totalBytes));

    return StorageAnalysis(
      rootPath: rootPath,
      scannedFiles: scannedFiles,
      scannedBytes: scannedBytes,
      categories: categories,
      largestFiles: largest.take(30).toList(),
    );
  }

  StorageCategory _categoryFor(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    if (_images.contains(ext)) return StorageCategory.image;
    if (_videos.contains(ext)) return StorageCategory.video;
    if (_audio.contains(ext)) return StorageCategory.audio;
    if (_documents.contains(ext)) return StorageCategory.document;
    if (ext == '.apk' || ext == '.xapk' || ext == '.apks') {
      return StorageCategory.apk;
    }
    if (_archives.contains(ext)) return StorageCategory.archive;
    return StorageCategory.other;
  }

  static const _images = {
    '.jpg', '.jpeg', '.png', '.webp', '.gif', '.heic', '.heif', '.bmp', '.svg'
  };
  static const _videos = {
    '.mp4', '.mkv', '.mov', '.avi', '.webm', '.3gp', '.m4v', '.ts'
  };
  static const _audio = {
    '.mp3', '.m4a', '.aac', '.wav', '.flac', '.ogg', '.opus'
  };
  static const _documents = {
    '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt', '.csv', '.epub'
  };
  static const _archives = {
    '.zip', '.rar', '.7z', '.tar', '.gz', '.bz2'
  };
}
