import 'package:equatable/equatable.dart';

class Medication extends Equatable {
  final String medicationID;
  final String name;
  final String dosage;
  final String frequency; // 'Daily', 'Twice daily', 'Weekly'
  final String time; // 'HH:mm' format
  final DateTime startDate;
  final DateTime endDate;
  final int quantityRemaining;
  final int refillThreshold;
  final DateTime? lastTaken;
  final String status; // 'Active', 'Completed', 'Paused'

  const Medication({
    required this.medicationID,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.time,
    required this.startDate,
    required this.endDate,
    required this.quantityRemaining,
    required this.refillThreshold,
    this.lastTaken,
    this.status = 'Active',
  });

  Medication copyWith({
    String? medicationID,
    String? name,
    String? dosage,
    String? frequency,
    String? time,
    DateTime? startDate,
    DateTime? endDate,
    int? quantityRemaining,
    int? refillThreshold,
    DateTime? lastTaken,
    String? status,
  }) {
    return Medication(
      medicationID: medicationID ?? this.medicationID,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      time: time ?? this.time,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      quantityRemaining: quantityRemaining ?? this.quantityRemaining,
      refillThreshold: refillThreshold ?? this.refillThreshold,
      lastTaken: lastTaken ?? this.lastTaken,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicationID': medicationID,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'time': time,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'quantityRemaining': quantityRemaining,
      'refillThreshold': refillThreshold,
      'lastTaken': lastTaken?.toIso8601String(),
      'status': status,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      medicationID: map['medicationID'] ?? '',
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? 'Daily',
      time: map['time'] ?? '08:00',
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      quantityRemaining: map['quantityRemaining'] ?? 0,
      refillThreshold: map['refillThreshold'] ?? 5,
      lastTaken: map['lastTaken'] != null ? DateTime.parse(map['lastTaken']) : null,
      status: map['status'] ?? 'Active',
    );
  }

  @override
  List<Object?> get props => [
        medicationID,
        name,
        dosage,
        frequency,
        time,
        startDate,
        endDate,
        quantityRemaining,
        refillThreshold,
        lastTaken,
        status,
      ];
}

class MedicationLog extends Equatable {
  final String medicineName;
  final DateTime timeScheduled;
  final DateTime? timeTaken;
  final String status; // 'taken', 'missed'

  const MedicationLog({
    required this.medicineName,
    required this.timeScheduled,
    this.timeTaken,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'medicineName': medicineName,
      'timeScheduled': timeScheduled.toIso8601String(),
      'timeTaken': timeTaken?.toIso8601String(),
      'status': status,
    };
  }

  factory MedicationLog.fromMap(Map<String, dynamic> map) {
    return MedicationLog(
      medicineName: map['medicineName'] ?? '',
      timeScheduled: DateTime.parse(map['timeScheduled']),
      timeTaken: map['timeTaken'] != null ? DateTime.parse(map['timeTaken']) : null,
      status: map['status'] ?? 'missed',
    );
  }

  @override
  List<Object?> get props => [medicineName, timeScheduled, timeTaken, status];
}
