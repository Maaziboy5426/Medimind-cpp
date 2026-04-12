import 'package:equatable/equatable.dart';

class UserPreferences extends Equatable {
  const UserPreferences({
    this.onboardingComplete = false,
    this.selectedNavIndex = 0,
  });

  final bool onboardingComplete;
  final int selectedNavIndex;

  UserPreferences copyWith({
    bool? onboardingComplete,
    int? selectedNavIndex,
  }) {
    return UserPreferences(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      selectedNavIndex: selectedNavIndex ?? this.selectedNavIndex,
    );
  }

  @override
  List<Object?> get props => [onboardingComplete, selectedNavIndex];
}
