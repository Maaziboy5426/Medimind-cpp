import 'dart:convert';

class UserActivityLog {
  final DateTime date;
  final int steps;
  final double distanceKm;
  final int caloriesBurned;
  final int activeMinutes;

  UserActivityLog({
    required this.date,
    required this.steps,
    required this.distanceKm,
    required this.caloriesBurned,
    required this.activeMinutes,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'steps': steps,
      'distanceKm': distanceKm,
      'caloriesBurned': caloriesBurned,
      'activeMinutes': activeMinutes,
    };
  }

  factory UserActivityLog.fromMap(Map<dynamic, dynamic> map) {
    return UserActivityLog(
      date: DateTime.parse(map['date']),
      steps: map['steps'] ?? 0,
      distanceKm: (map['distanceKm'] ?? 0.0).toDouble(),
      caloriesBurned: map['caloriesBurned'] ?? 0,
      activeMinutes: map['activeMinutes'] ?? 0,
    );
  }
}

class NutritionLog {
  final DateTime date;
  final String mealType; // Breakfast, Lunch, Dinner, Snack
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  NutritionLog({
    required this.date,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'mealType': mealType,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  factory NutritionLog.fromMap(Map<dynamic, dynamic> map) {
    return NutritionLog(
      date: DateTime.parse(map['date']),
      mealType: map['mealType'] ?? 'Snack',
      calories: map['calories'] ?? 0,
      protein: (map['protein'] ?? 0.0).toDouble(),
      carbs: (map['carbs'] ?? 0.0).toDouble(),
      fat: (map['fat'] ?? 0.0).toDouble(),
    );
  }
}

class UserSleepLog {
  final DateTime date;
  final DateTime sleepStart;
  final DateTime sleepEnd;
  final double sleepDuration; // in hours
  final double deepSleep; // in hours
  final double remSleep; // in hours

  UserSleepLog({
    required this.date,
    required this.sleepStart,
    required this.sleepEnd,
    required this.sleepDuration,
    required this.deepSleep,
    required this.remSleep,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'sleepStart': sleepStart.toIso8601String(),
      'sleepEnd': sleepEnd.toIso8601String(),
      'sleepDuration': sleepDuration,
      'deepSleep': deepSleep,
      'remSleep': remSleep,
    };
  }

  factory UserSleepLog.fromMap(Map<dynamic, dynamic> map) {
    return UserSleepLog(
      date: DateTime.parse(map['date']),
      sleepStart: DateTime.parse(map['sleepStart']),
      sleepEnd: DateTime.parse(map['sleepEnd']),
      sleepDuration: (map['sleepDuration'] ?? 0.0).toDouble(),
      deepSleep: (map['deepSleep'] ?? 0.0).toDouble(),
      remSleep: (map['remSleep'] ?? 0.0).toDouble(),
    );
  }
}

class UserHydrationLog {
  final DateTime date;
  final int waterMl;

  UserHydrationLog({
    required this.date,
    required this.waterMl,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'waterMl': waterMl,
    };
  }

  factory UserHydrationLog.fromMap(Map<dynamic, dynamic> map) {
    return UserHydrationLog(
      date: DateTime.parse(map['date']),
      waterMl: map['waterMl'] ?? 0,
    );
  }
}

class BodyMetrics {
  final DateTime date;
  final double height;
  final double weight;
  final int age;
  final double bmi;

  BodyMetrics({
    required this.date,
    required this.height,
    required this.weight,
    required this.age,
    required this.bmi,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'height': height,
      'weight': weight,
      'age': age,
      'bmi': bmi,
    };
  }

  factory BodyMetrics.fromMap(Map<dynamic, dynamic> map) {
    return BodyMetrics(
      date: DateTime.parse(map['date']),
      height: (map['height'] ?? 0.0).toDouble(),
      weight: (map['weight'] ?? 0.0).toDouble(),
      age: map['age'] ?? 0,
      bmi: (map['bmi'] ?? 0.0).toDouble(),
    );
  }
}
