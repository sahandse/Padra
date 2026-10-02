import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:disk_space_plus/disk_space_plus.dart';

import 'device_snapshot.dart';

class DeviceScanService {
  DeviceScanService({
    DeviceInfoPlugin? deviceInfo,
    Battery? battery,
    DiskSpacePlus? diskSpace,
  })  : _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
        _battery = battery ?? Battery(),
        _diskSpace = diskSpace ?? DiskSpacePlus();

  final DeviceInfoPlugin _deviceInfo;
  final Battery _battery;
  final DiskSpacePlus _diskSpace;

  Future<DeviceSnapshot> scan() async {
    final android = await _deviceInfo.androidInfo;
    final batteryLevel = await _battery.batteryLevel;
    final batteryState = await _battery.batteryState;

    double? totalStorageMb;
    double? freeStorageMb;
    try {
      totalStorageMb = await _diskSpace.getTotalDiskSpace;
      freeStorageMb = await _diskSpace.getFreeDiskSpace;
    } catch (_) {
      // Storage can be unavailable on some devices/ROMs. Keep it unknown rather
      // than inventing a value or failing the whole scan.
    }

    return DeviceSnapshot(
      manufacturer: android.manufacturer,
      model: android.model,
      androidVersion: android.version.release,
      sdkInt: android.version.sdkInt,
      securityPatch: android.version.securityPatch,
      isPhysicalDevice: android.isPhysicalDevice,
      batteryLevel: batteryLevel,
      batteryState: _batteryStateLabel(batteryState),
      totalStorageMb: totalStorageMb,
      freeStorageMb: freeStorageMb,
    );
  }

  String _batteryStateLabel(BatteryState state) {
    return switch (state) {
      BatteryState.charging => 'در حال شارژ',
      BatteryState.full => 'شارژ کامل',
      BatteryState.discharging => 'در حال مصرف',
      BatteryState.connectedNotCharging => 'متصل، بدون شارژ',
      BatteryState.unknown => 'نامشخص',
    };
  }
}
