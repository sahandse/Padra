class DeviceSnapshot {
  const DeviceSnapshot({
    required this.manufacturer,
    required this.model,
    required this.androidVersion,
    required this.sdkInt,
    required this.securityPatch,
    required this.isPhysicalDevice,
    required this.batteryLevel,
    required this.batteryState,
    required this.totalStorageMb,
    required this.freeStorageMb,
  });

  final String manufacturer;
  final String model;
  final String androidVersion;
  final int sdkInt;
  final String? securityPatch;
  final bool isPhysicalDevice;
  final int batteryLevel;
  final String batteryState;
  final double? totalStorageMb;
  final double? freeStorageMb;

  double? get usedStoragePercent {
    final total = totalStorageMb;
    final free = freeStorageMb;
    if (total == null || free == null || total <= 0) return null;
    return ((total - free) / total * 100).clamp(0, 100).toDouble();
  }

  String get deviceLabel => '${manufacturer.trim()} ${model.trim()}'.trim();
}
