enum ScanVerdict { safe, suspicious, unknown }

class ScanResult {
  const ScanResult({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.sha256,
    required this.scannedAt,
    required this.verdict,
    required this.reasons,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final String sha256;
  final DateTime scannedAt;
  final ScanVerdict verdict;
  final List<String> reasons;

  bool get isApk => name.toLowerCase().endsWith('.apk');

  Map<String, Object?> toJson() => {
        'path': path,
        'name': name,
        'sizeBytes': sizeBytes,
        'sha256': sha256,
        'scannedAt': scannedAt.toIso8601String(),
        'verdict': verdict.name,
        'reasons': reasons,
      };

  factory ScanResult.fromJson(Map<String, Object?> json) {
    return ScanResult(
      path: json['path'] as String,
      name: json['name'] as String,
      sizeBytes: json['sizeBytes'] as int,
      sha256: json['sha256'] as String,
      scannedAt: DateTime.parse(json['scannedAt'] as String),
      verdict: ScanVerdict.values.byName(json['verdict'] as String),
      reasons: (json['reasons'] as List<Object?>).cast<String>(),
    );
  }
}
