import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'smart_band_simulation_service.dart';

final smartBandProvider =
    StateNotifierProvider.autoDispose<SmartBandSimulationService, SmartBandState>(
  (ref) => SmartBandSimulationService(),
);
