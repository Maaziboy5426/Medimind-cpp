import 'dart:async';
import 'dart:math';

import 'package:state_notifier/state_notifier.dart';

/// Timer-based Smart Band simulation state.
class SmartBandState {
  const SmartBandState({
    this.heartRate,
    this.spO2,
    this.bodyTempC,
    this.stressIndex,
    this.batteryPercent = 100,
    this.isConnected = false,
    this.heartRateHistory = const [],
  });

  final int? heartRate;
  final int? spO2;
  final double? bodyTempC;
  final int? stressIndex;
  final int batteryPercent;
  final bool isConnected;
  final List<double> heartRateHistory;

  SmartBandState copyWith({
    int? heartRate,
    int? spO2,
    double? bodyTempC,
    int? stressIndex,
    int? batteryPercent,
    bool? isConnected,
    List<double>? heartRateHistory,
  }) {
    return SmartBandState(
      heartRate: heartRate ?? this.heartRate,
      spO2: spO2 ?? this.spO2,
      bodyTempC: bodyTempC ?? this.bodyTempC,
      stressIndex: stressIndex ?? this.stressIndex,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      isConnected: isConnected ?? this.isConnected,
      heartRateHistory: heartRateHistory ?? this.heartRateHistory,
    );
  }
}

/// Timer-based simulation: heart rate 60–110, SpO2 94–100, temp 36–38°C,
/// stress index, battery drain when connected, heart rate history for chart.
class SmartBandSimulationService extends StateNotifier<SmartBandState> {
  SmartBandSimulationService() : super(const SmartBandState()) {
    _heartRateTimer = Timer.periodic(const Duration(milliseconds: 1500), _tickHeartRate);
    _vitalsTimer = Timer.periodic(const Duration(seconds: 4), _tickVitals);
    _batteryTimer = Timer.periodic(const Duration(seconds: 30), _tickBattery);
    // Initial values when not connected (will show after first connect)
    state = state.copyWith(
      heartRate: 72,
      spO2: 98,
      bodyTempC: 36.6,
      stressIndex: 25,
      batteryPercent: 100,
    );
  }

  static const int _heartRateMin = 60;
  static const int _heartRateMax = 110;
  static const int _spO2Min = 94;
  static const int _spO2Max = 100;
  static const double _tempMin = 36.0;
  static const double _tempMax = 38.0;
  static const int _maxHistory = 40;

  final Random _rng = Random();
  late Timer _heartRateTimer;
  late Timer _vitalsTimer;
  late Timer _batteryTimer;

  void _tickHeartRate(Timer _) {
    if (!state.isConnected) return;
    final next = _heartRateMin + _rng.nextInt(_heartRateMax - _heartRateMin + 1);
    final prev = state.heartRate ?? next;
    final smoothed = (prev * 0.6 + next * 0.4).round().clamp(_heartRateMin, _heartRateMax);
    var list = List<double>.from(state.heartRateHistory);
    list.add(smoothed.toDouble());
    if (list.length > _maxHistory) list = list.sublist(list.length - _maxHistory);
    state = state.copyWith(heartRate: smoothed, heartRateHistory: list);
  }

  void _tickVitals(Timer _) {
    if (!state.isConnected) return;
    state = state.copyWith(
      spO2: _spO2Min + _rng.nextInt(_spO2Max - _spO2Min + 1),
      bodyTempC: _tempMin + _rng.nextDouble() * (_tempMax - _tempMin),
      stressIndex: _rng.nextInt(101),
    );
  }

  void _tickBattery(Timer _) {
    if (!state.isConnected || state.batteryPercent <= 0) return;
    state = state.copyWith(batteryPercent: (state.batteryPercent - 1).clamp(0, 100));
  }

  void toggleConnection() {
    final next = !state.isConnected;
    state = state.copyWith(
      isConnected: next,
      batteryPercent: next ? state.batteryPercent : 100,
    );
    if (next && state.heartRateHistory.isEmpty) {
      var list = List<double>.from(state.heartRateHistory);
      for (var i = 0; i < _maxHistory; i++) {
        list.add((_heartRateMin + _rng.nextInt(_heartRateMax - _heartRateMin + 1)).toDouble());
      }
      state = state.copyWith(heartRateHistory: list);
    }
  }

  @override
  void dispose() {
    _heartRateTimer.cancel();
    _vitalsTimer.cancel();
    _batteryTimer.cancel();
    super.dispose();
  }
}
