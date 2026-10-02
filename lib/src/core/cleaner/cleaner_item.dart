class CleanerItem {
  const CleanerItem({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.category,
    required this.modifiedAt,
    this.duplicateGroup,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final CleanerCategory category;
  final DateTime modifiedAt;
  final String? duplicateGroup;

  bool get isDuplicate => duplicateGroup != null;
  double get sizeMb => sizeBytes / 1024 / 1024;
}

enum CleanerCategory {
  largeFile,
  apk,
  download,
  duplicate,
  other,
}

extension CleanerCategoryLabel on CleanerCategory {
  String get label => switch (this) {
        CleanerCategory.largeFile => 'فایل بزرگ',
        CleanerCategory.apk => 'APK',
        CleanerCategory.download => 'دانلود',
        CleanerCategory.duplicate => 'تکراری',
        CleanerCategory.other => 'سایر',
      };
}
