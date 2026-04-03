class AppUser {
  final String uid;
  final String email;
  final String name;
  final double height;
  final double weight;
  final int age;
  final String gender;
  final int stepGoal;
  final int sleepGoal;
  final int waterGoal;
  final int calorieGoal;
  final bool profileCompleted;

  // New Profile Fields
  final String activityLevel;
  final double sleepAverage;
  final int waterIntake;
  final bool smokingStatus;
  final bool alcoholConsumption;
  final List<String> pastDiseases;
  final Map<String, bool> familyHistory;
  final List<String> healthGoals;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    this.height = 175.0,
    this.weight = 70.0,
    this.age = 25,
    this.gender = 'Other',
    this.stepGoal = 10000,
    this.sleepGoal = 8,
    this.waterGoal = 8,
    this.calorieGoal = 2000,
    this.profileCompleted = false,
    this.activityLevel = 'Moderate',
    this.sleepAverage = 7.0,
    this.waterIntake = 2000,
    this.smokingStatus = false,
    this.alcoholConsumption = false,
    this.pastDiseases = const [],
    this.familyHistory = const {},
    this.healthGoals = const [],
  });

  AppUser copyWith({
    String? uid,
    String? email,
    String? name,
    double? height,
    double? weight,
    int? age,
    String? gender,
    int? stepGoal,
    int? sleepGoal,
    int? waterGoal,
    int? calorieGoal,
    bool? profileCompleted,
    String? activityLevel,
    double? sleepAverage,
    int? waterIntake,
    bool? smokingStatus,
    bool? alcoholConsumption,
    List<String>? pastDiseases,
    Map<String, bool>? familyHistory,
    List<String>? healthGoals,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      stepGoal: stepGoal ?? this.stepGoal,
      sleepGoal: sleepGoal ?? this.sleepGoal,
      waterGoal: waterGoal ?? this.waterGoal,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      activityLevel: activityLevel ?? this.activityLevel,
      sleepAverage: sleepAverage ?? this.sleepAverage,
      waterIntake: waterIntake ?? this.waterIntake,
      smokingStatus: smokingStatus ?? this.smokingStatus,
      alcoholConsumption: alcoholConsumption ?? this.alcoholConsumption,
      pastDiseases: pastDiseases ?? this.pastDiseases,
      familyHistory: familyHistory ?? this.familyHistory,
      healthGoals: healthGoals ?? this.healthGoals,
    );
  }

  double get bmi => weight / ((height / 100) * (height / 100));

  factory AppUser.fromMap(Map<String, dynamic> data, String documentId) {
    return AppUser(
      uid: documentId,
      email: data['email'] ?? '',
      name: data['name'] ?? 'User',
      height: (data['height'] ?? 175.0).toDouble(),
      weight: (data['weight'] ?? 70.0).toDouble(),
      age: data['age'] ?? 25,
      gender: data['gender'] ?? 'Other',
      stepGoal: data['stepGoal'] ?? 10000,
      sleepGoal: data['sleepGoal'] ?? 8,
      waterGoal: data['waterGoal'] ?? 8,
      calorieGoal: data['calorieGoal'] ?? 2000,
      profileCompleted: data['profileCompleted'] ?? false,
      activityLevel: data['activityLevel'] ?? 'Moderate',
      sleepAverage: (data['sleepAverage'] ?? 7.0).toDouble(),
      waterIntake: data['waterIntake'] ?? 2000,
      smokingStatus: data['smokingStatus'] ?? false,
      alcoholConsumption: data['alcoholConsumption'] ?? false,
      pastDiseases: List<String>.from(data['pastDiseases'] ?? []),
      familyHistory: Map<String, bool>.from(data['familyHistory'] ?? {}),
      healthGoals: List<String>.from(data['healthGoals'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'height': height,
      'weight': weight,
      'age': age,
      'gender': gender,
      'stepGoal': stepGoal,
      'sleepGoal': sleepGoal,
      'waterGoal': waterGoal,
      'calorieGoal': calorieGoal,
      'profileCompleted': profileCompleted,
      'activityLevel': activityLevel,
      'sleepAverage': sleepAverage,
      'waterIntake': waterIntake,
      'smokingStatus': smokingStatus,
      'alcoholConsumption': alcoholConsumption,
      'pastDiseases': pastDiseases,
      'familyHistory': familyHistory,
      'healthGoals': healthGoals,
      'bmi': bmi,
    };
  }
}


class HealthMetric {
  final String id;
  final int heartRate;
  final int spO2;
  final double bodyTempC;
  final int stressIndex;
  final DateTime timestamp;

  HealthMetric({
    required this.id,
    required this.heartRate,
    required this.spO2,
    required this.bodyTempC,
    required this.stressIndex,
    required this.timestamp,
  });

  factory HealthMetric.fromMap(Map<String, dynamic> data, String documentId) {
    return HealthMetric(
      id: documentId,
      heartRate: data['heartRate'] ?? 72,
      spO2: data['spO2'] ?? 98,
      bodyTempC: (data['bodyTempC'] ?? 36.6).toDouble(),
      stressIndex: data['stressIndex'] ?? 20,
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] is String ? DateTime.parse(data['timestamp']) : data['timestamp'] as DateTime)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'heartRate': heartRate,
      'spO2': spO2,
      'bodyTempC': bodyTempC,
      'stressIndex': stressIndex,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ActivityLog {
  final String id;
  final int steps;
  final int calories;
  final double distance;
  final int activeMinutes;
  final DateTime date;

  ActivityLog({
    required this.id,
    required this.steps,
    required this.calories,
    required this.distance,
    required this.activeMinutes,
    required this.date,
  });

  factory ActivityLog.fromMap(Map<String, dynamic> data, String documentId) {
    return ActivityLog(
      id: documentId,
      steps: data['steps'] ?? 0,
      calories: data['calories'] ?? 0,
      distance: (data['distance'] ?? 0.0).toDouble(),
      activeMinutes: data['activeMinutes'] ?? 0,
      date: data['date'] != null 
          ? (data['date'] is String ? DateTime.parse(data['date']) : data['date'] as DateTime)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'steps': steps,
      'calories': calories,
      'distance': distance,
      'activeMinutes': activeMinutes,
      'date': date.toIso8601String(),
    };
  }
}

class SleepLog {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int score;

  SleepLog({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.score,
  });

  double get durationHours => endTime.difference(startTime).inMinutes / 60.0;

  factory SleepLog.fromMap(Map<String, dynamic> data, String documentId) {
    return SleepLog(
      id: documentId,
      startTime: data['startTime'] != null 
          ? (data['startTime'] is String ? DateTime.parse(data['startTime']) : data['startTime'] as DateTime)
          : DateTime.now().subtract(const Duration(hours: 8)),
      endTime: data['endTime'] != null 
          ? (data['endTime'] is String ? DateTime.parse(data['endTime']) : data['endTime'] as DateTime)
          : DateTime.now(),
      score: data['score'] ?? 85,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'score': score,
    };
  }
}

class HydrationLog {
  final String id;
  final int amountMl;
  final DateTime time;

  HydrationLog({required this.id, required this.amountMl, required this.time});

  factory HydrationLog.fromMap(Map<String, dynamic> data, String documentId) {
    return HydrationLog(
      id: documentId,
      amountMl: data['amountMl'] ?? 0,
      time: data['time'] != null 
          ? (data['time'] is String ? DateTime.parse(data['time']) : data['time'] as DateTime)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amountMl': amountMl, 
      'time': time.toIso8601String()
    };
  }
}

class Medicine {
  final String id;
  final String name;
  final String dosage;
  final String time;
  final String frequency;
  final bool isTaken;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.time,
    required this.frequency,
    this.isTaken = false,
  });

  factory Medicine.fromMap(Map<String, dynamic> data, String documentId) {
    return Medicine(
      id: documentId,
      name: data['name'] ?? '',
      dosage: data['dosage'] ?? '',
      time: data['time'] ?? '',
      frequency: data['frequency'] ?? '',
      isTaken: data['isTaken'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'time': time,
      'frequency': frequency,
      'isTaken': isTaken,
    };
  }
}

class Appointment {
  final String id;
  final String doctorName;
  final String specialization;
  final DateTime dateTime;
  final String status;

  Appointment({
    required this.id,
    required this.doctorName,
    required this.specialization,
    required this.dateTime,
    required this.status,
  });

  factory Appointment.fromMap(Map<String, dynamic> data, String documentId) {
    return Appointment(
      id: documentId,
      doctorName: data['doctorName'] ?? '',
      specialization: data['specialization'] ?? '',
      dateTime: data['dateTime'] != null 
          ? (data['dateTime'] is String ? DateTime.parse(data['dateTime']) : data['dateTime'] as DateTime)
          : DateTime.now(),
      status: data['status'] ?? 'Scheduled',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorName': doctorName,
      'specialization': specialization,
      'dateTime': dateTime.toIso8601String(),
      'status': status,
    };
  }
}

class CommunityPost {
  final String postID;
  final String userID;
  final String username;
  final String avatar;
  final String content;
  final String topic;
  final int likesCount;
  final DateTime createdAt;

  CommunityPost({
    required this.postID,
    required this.userID,
    required this.username,
    required this.avatar,
    required this.content,
    required this.topic,
    required this.likesCount,
    required this.createdAt,
  });

  factory CommunityPost.fromMap(Map<String, dynamic> data) {
    return CommunityPost(
      postID: data['postID'] ?? '',
      userID: data['userID'] ?? '',
      username: data['username'] ?? 'Anonymous',
      avatar: data['avatar'] ?? '',
      content: data['content'] ?? '',
      topic: data['topic'] ?? 'General',
      likesCount: data['likesCount'] ?? 0,
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postID': postID,
      'userID': userID,
      'username': username,
      'avatar': avatar,
      'content': content,
      'topic': topic,
      'likesCount': likesCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class CommunityComment {
  final String commentID;
  final String postID;
  final String userID;
  final String username;
  final String avatar;
  final String content;
  final DateTime createdAt;

  CommunityComment({
    required this.commentID,
    required this.postID,
    required this.userID,
    required this.username,
    required this.avatar,
    required this.content,
    required this.createdAt,
  });

  factory CommunityComment.fromMap(Map<String, dynamic> data) {
    return CommunityComment(
      commentID: data['commentID'] ?? '',
      postID: data['postID'] ?? '',
      userID: data['userID'] ?? '',
      username: data['username'] ?? 'Anonymous',
      avatar: data['avatar'] ?? '',
      content: data['content'] ?? '',
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commentID': commentID,
      'postID': postID,
      'userID': userID,
      'username': username,
      'avatar': avatar,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ExpertAdvice {
  final String adviceID;
  final String title;
  final String content;
  final String author;
  final String topic;

  ExpertAdvice({
    required this.adviceID,
    required this.title,
    required this.content,
    required this.author,
    required this.topic,
  });

  factory ExpertAdvice.fromMap(Map<String, dynamic> data) {
    return ExpertAdvice(
      adviceID: data['adviceID'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      author: data['author'] ?? '',
      topic: data['topic'] ?? '',
    );
  }
}

class SupportGroup {
  final String groupID;
  final String name;
  final String description;

  SupportGroup({
    required this.groupID,
    required this.name,
    required this.description,
  });

  factory SupportGroup.fromMap(Map<String, dynamic> data) {
    return SupportGroup(
      groupID: data['groupID'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
    );
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final bool isUnlocked;
  final DateTime? unlockedDate;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.isUnlocked,
    this.unlockedDate,
  });

  factory Achievement.fromMap(Map<String, dynamic> data, String documentId) {
    return Achievement(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      isUnlocked: data['isUnlocked'] ?? false,
      unlockedDate: data['unlockedDate'] != null 
          ? (data['unlockedDate'] is String ? DateTime.parse(data['unlockedDate']) : data['unlockedDate'] as DateTime)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isUnlocked': isUnlocked,
      'unlockedDate': unlockedDate?.toIso8601String(),
    };
  }
}

class Meal {
  final String id;
  final String name;
  final int calories;
  final DateTime timestamp;

  Meal({
    required this.id,
    required this.name,
    required this.calories,
    required this.timestamp,
  });

  factory Meal.fromMap(Map<String, dynamic> data, String documentId) {
    return Meal(
      id: documentId,
      name: data['name'] ?? '',
      calories: data['calories'] ?? 0,
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] is String ? DateTime.parse(data['timestamp']) : data['timestamp'] as DateTime)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

