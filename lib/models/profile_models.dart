import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String userID;
  final String name;
  final String email;
  final int age;
  final String gender;
  final double height; // cm
  final double weight; // kg
  final String activityLevel;
  final double sleepAverage;
  final bool smokingStatus;
  final bool alcoholConsumption;
  final String? profilePicture;

  const UserProfile({
    required this.userID,
    required this.name,
    required this.email,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.activityLevel,
    required this.sleepAverage,
    required this.smokingStatus,
    required this.alcoholConsumption,
    this.profilePicture,
  });

  double get bmi {
    if (height == 0) return 0.0;
    final hm = height / 100;
    return weight / (hm * hm);
  }

  UserProfile copyWith({
    String? userID,
    String? name,
    String? email,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? activityLevel,
    double? sleepAverage,
    bool? smokingStatus,
    bool? alcoholConsumption,
    String? profilePicture,
  }) {
    return UserProfile(
      userID: userID ?? this.userID,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      sleepAverage: sleepAverage ?? this.sleepAverage,
      smokingStatus: smokingStatus ?? this.smokingStatus,
      alcoholConsumption: alcoholConsumption ?? this.alcoholConsumption,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'name': name,
      'email': email,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel,
      'sleepAverage': sleepAverage,
      'smokingStatus': smokingStatus,
      'alcoholConsumption': alcoholConsumption,
      'profilePicture': profilePicture,
    };
  }

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    return UserProfile(
      userID: map['userID'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      age: map['age'] ?? 25,
      gender: map['gender'] ?? 'Other',
      height: (map['height'] ?? 175.0).toDouble(),
      weight: (map['weight'] ?? 70.0).toDouble(),
      activityLevel: map['activityLevel'] ?? 'Moderate',
      sleepAverage: (map['sleepAverage'] ?? 7.0).toDouble(),
      smokingStatus: map['smokingStatus'] ?? false,
      alcoholConsumption: map['alcoholConsumption'] ?? false,
      profilePicture: map['profilePicture'],
    );
  }

  @override
  List<Object?> get props => [
        userID,
        name,
        email,
        age,
        gender,
        height,
        weight,
        activityLevel,
        sleepAverage,
        smokingStatus,
        alcoholConsumption,
        profilePicture,
      ];
}
