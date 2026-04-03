import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/medicine_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MedicineService {
  static const String medicationsBoxName = 'medicationsBox';
  static const String medicationLogsBoxName = 'medicationLogsBox';

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    await Hive.openBox(medicationsBoxName);
    await Hive.openBox(medicationLogsBoxName);
    tz.initializeTimeZones();
    
    final notifications = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    
    await notifications.initialize(settings: initSettings);
  }

  // --- CRUD Medications ---

  Future<void> addMedication(Medication medicine) async {
    final box = Hive.box(medicationsBoxName);
    await box.put(medicine.medicationID, medicine.toMap());
    await _scheduleNotification(medicine);
  }

  Future<void> updateMedication(Medication medicine) async {
    final box = Hive.box(medicationsBoxName);
    await box.put(medicine.medicationID, medicine.toMap());
    await _scheduleNotification(medicine);
  }

  List<Medication> getMedications() {
    final box = Hive.box(medicationsBoxName);
    return box.values.map((e) => Medication.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<void> deleteMedication(String id) async {
    final box = Hive.box(medicationsBoxName);
    await box.delete(id);
    await _notifications.cancel(id: id.hashCode);
  }

  // --- Daily Schedule ---

  List<Medication> getDailySchedule() {
    final meds = getMedications();
    final now = DateTime.now();
    return meds.where((m) {
      if (m.status != 'Active') return false;
      if (now.isBefore(m.startDate) || now.isAfter(m.endDate)) return false;
      // For simplicity, we assume 'Daily' means every day. 
      // 'Twice daily' logic would require multiple scheduled times, but model has only one 'time'.
      // UI shows 'Twice daily' as frequency, but only one 'time' field is in requirement.
      return true; 
    }).toList()
    ..sort((a, b) => a.time.compareTo(b.time));
  }

  // --- Next Up ---

  Medication? getNextUp() {
    final schedule = getDailySchedule();
    if (schedule.isEmpty) return null;
    
    final now = DateTime.now();
    final currentTimeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    
    // Find first one after now
    for (var med in schedule) {
      if (med.time.compareTo(currentTimeStr) > 0) {
        return med;
      }
    }
    
    // If all passed, return first of tomorrow (or first of the sorted list)
    return schedule.first;
  }

  // --- Take Medication ---

  Future<void> takeMedication(String id) async {
    final box = Hive.box(medicationsBoxName);
    final data = box.get(id);
    if (data == null) return;
    
    Medication med = Medication.fromMap(Map<String, dynamic>.from(data as Map));
    med = med.copyWith(
      lastTaken: DateTime.now(),
      quantityRemaining: med.quantityRemaining - 1,
    );
    
    await box.put(id, med.toMap());
    
    // Log it
    await logDose(MedicationLog(
      medicineName: med.name,
      timeScheduled: _getScheduledDateTime(med.time),
      timeTaken: DateTime.now(),
      status: 'taken',
    ));
  }

  // --- Adherence ---

  double calculateAdherence() {
    final logs = getLogs();
    if (logs.isEmpty) return 100.0;
    
    final taken = logs.where((l) => l.status == 'taken').length;
    return (taken / logs.length) * 100;
  }

  // --- Logs ---

  Future<void> logDose(MedicationLog log) async {
    final box = Hive.box(medicationLogsBoxName);
    await box.add(log.toMap());
  }

  List<MedicationLog> getLogs() {
    final box = Hive.box(medicationLogsBoxName);
    return box.values.map((e) => MedicationLog.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  }

  // --- Notifications ---

  Future<void> _scheduleNotification(Medication med) async {
    final timeParts = med.time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id: med.medicationID.hashCode,
      title: 'Medication Reminder',
      body: 'Time to take ${med.name} (${med.dosage})',
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'med_reminders',
          'Medication Reminders',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('notification_sound'),
        ),
        iOS: DarwinNotificationDetails(
          sound: 'notification_sound.wav',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  DateTime _getScheduledDateTime(String timeStr) {
    final parts = timeStr.split(':');
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }
}

// Providers
final medicineServiceProvider = Provider((ref) => MedicineService());

final medicationsProvider = StreamProvider<List<Medication>>((ref) {
  final service = ref.watch(medicineServiceProvider);
  return Stream.periodic(const Duration(seconds: 1), (_) => service.getMedications()).distinct();
});

final dailyScheduleProvider = Provider((ref) {
  final meds = ref.watch(medicationsProvider).value ?? [];
  // Re-filtering here for reactivity
  final now = DateTime.now();
  return meds.where((m) {
     if (m.status != 'Active') return false;
     if (now.isBefore(m.startDate) || now.isAfter(m.endDate)) return false;
     return true;
  }).toList()..sort((a, b) => a.time.compareTo(b.time));
});

final nextUpProvider = Provider((ref) {
  final schedule = ref.watch(dailyScheduleProvider);
  if (schedule.isEmpty) return null;
  final now = DateTime.now();
  final currentTimeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  for (var med in schedule) {
    if (med.time.compareTo(currentTimeStr) > 0) return med;
  }
  return schedule.first;
});

final adherenceProvider = Provider((ref) {
  final service = ref.watch(medicineServiceProvider);
  // This needs to be reactive based on logs box changes... 
  // For simplicity we'll just watch medications and assume logs change when meds change (taken)
  ref.watch(medicationsProvider); 
  return service.calculateAdherence();
});
