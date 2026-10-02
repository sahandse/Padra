enum StorageCategory {
  image,
  video,
  audio,
  document,
  apk,
  archive,
  other,
}

class StorageCategoryStat {
  const StorageCategoryStat({
    required this.category,
    required this.fileCount,
    required this.totalBytes,
  });

  final StorageCategory category;
  final int fileCount;
  final int totalBytes;
}

class StorageAnalysis {
  const StorageAnalysis({
    required this.rootPath,
    required this.scannedFiles,
    required this.scannedBytes,
    required this.categories,
    required this.largestFiles,
  });

  final String rootPath;
  final int scannedFiles;
  final int scannedBytes;
  final List<StorageCategoryStat> categories;
  final List<StorageFileEntry> largestFiles;
}

class StorageFileEntry {
  const StorageFileEntry({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.category,
    required this.modifiedAt,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final StorageCategory category;
  final DateTime modifiedAt;
}
