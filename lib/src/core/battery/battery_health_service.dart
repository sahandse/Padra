import 'package:battery_plus/battery_plus.dart';

class BatteryHealthSnapshot {
  const BatteryHealthSnapshot({
    required this.level,
    required this.state,
    required this.isBatterySaverOn,
  });

  final int level;
  final BatteryState state;
  final bool isBatterySaverOn;

  String get stateLabel => switch (state) {
        BatteryState.charging => 'در حال شارژ',
        BatteryState.discharging => 'در حال مصرف',
        BatteryState.full => 'شارژ کامل',
        BatteryState.connectedNotCharging => 'متصل، بدون شارژ',
        BatteryState.unknown => 'نامشخص',
      };
}

class BatteryHealthService {
  BatteryHealthService({Battery? battery}) : _battery = battery ?? Battery();

  final Battery _battery;

  Future<BatteryHealthSnapshot> read() async {
    final level = await _battery.batteryLevel;
    final state = await _battery.batteryState;
    final saver = await _battery.isInBatterySaveMode;

    return BatteryHealthSnapshot(
      level: level,
      state: state,
      isBatterySaverOn: saver,
    );
  }

  Stream<BatteryState> get stateChanges => _battery.onBatteryStateChanged;
}
