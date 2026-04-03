import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../services/storage_provider.dart';
import '../../../../models/app_backend_models.dart';

class HealthProfileSetupScreen extends ConsumerStatefulWidget {
  const HealthProfileSetupScreen({super.key});

  @override
  ConsumerState<HealthProfileSetupScreen> createState() => _HealthProfileSetupScreenState();
}

class _HealthProfileSetupScreenState extends ConsumerState<HealthProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 6;

  // --- Form State ---
  final _nameController = TextEditingController();
  final _ageController = TextEditingController(text: '25');
  final _heightController = TextEditingController(text: '170');
  final _weightController = TextEditingController(text: '70');
  final _sleepController = TextEditingController(text: '7');
  final _waterController = TextEditingController(text: '2000');
  final _stepGoalController = TextEditingController(text: '10000');
  final _sleepGoalController = TextEditingController(text: '8');
  final _waterGoalController = TextEditingController(text: '8');
  final _calorieGoalController = TextEditingController(text: '2000');

  String _gender = 'Male';
  String _activityLevel = 'Moderate';
  bool _smoking = false;
  bool _alcohol = false;

  final List<String> _pastDiseases = [];
  final Map<String, bool> _familyHistory = {
    'Cancer': false,
    'Diabetes': false,
    'Heart Disease': false,
    'Stroke': false,
  };

  final List<String> _goals = [];

  @override
  void initState() {
    super.initState();
    final user = ref.read(firebaseServiceProvider).getCurrentUser();
    if (user != null) {
      _nameController.text = user.name;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _sleepController.dispose();
    _waterController.dispose();
    _stepGoalController.dispose();
    _sleepGoalController.dispose();
    _waterGoalController.dispose();
    _calorieGoalController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _saveProfile();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _saveProfile() async {
    final existingUser = ref.read(firebaseServiceProvider).getCurrentUser();
    if (existingUser == null) return;

    final updatedUser = existingUser.copyWith(
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text) ?? 25,
      gender: _gender,
      height: double.tryParse(_heightController.text) ?? 170.0,
      weight: double.tryParse(_weightController.text) ?? 70.0,
      activityLevel: _activityLevel,
      sleepAverage: double.tryParse(_sleepController.text) ?? 7.0,
      waterIntake: int.tryParse(_waterController.text) ?? 2000,
      smokingStatus: _smoking,
      alcoholConsumption: _alcohol,
      pastDiseases: _pastDiseases,
      familyHistory: _familyHistory,
      healthGoals: _goals,
      stepGoal: int.tryParse(_stepGoalController.text) ?? 10000,
      sleepGoal: int.tryParse(_sleepGoalController.text) ?? 8,
      waterGoal: int.tryParse(_waterGoalController.text) ?? 8,
      calorieGoal: int.tryParse(_calorieGoalController.text) ?? 2000,
      profileCompleted: true,
    );

    try {
      await ref.read(firebaseServiceProvider).updateProfile(updatedUser);
      ref.invalidate(authStateProvider);
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      debugPrint('Error saving health profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Step ${_currentStep + 1} of $_totalSteps',
          style: const TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
        ),
        centerTitle: true,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.onSurface),
                onPressed: _prevStep,
              )
            : null,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: AppTheme.navy800,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.cyanAccent),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (idx) => setState(() => _currentStep = idx),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
                _buildStep4(),
                _buildStep5(),
                _buildStep6(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: PrimaryButton(
              label: _currentStep == _totalSteps - 1 ? 'Complete Setup' : 'Continue',
              onPressed: _nextStep,
            ),
          ),
        ],
      ),
    );
  }

  // --- Step Builders ---

  Widget _buildStep1() {
    return _StepLayout(
      title: 'Personal Information',
      subtitle: 'Let\'s get to know you better for more accurate health analysis.',
      children: [
        AppTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'Enter your name',
          icon: Icons.person_rounded,
        ),
        const SizedBox(height: 20),
        _buildDropdown('Gender', _gender, ['Male', 'Female', 'Other'], (val) {
          if (val != null) setState(() => _gender = val);
        }),
        const SizedBox(height: 20),
        _buildNumericField('Age', _ageController, 'e.g. 25', 'years'),
        const SizedBox(height: 20),
        _buildNumericField('Height', _heightController, 'e.g. 175', 'cm'),
        const SizedBox(height: 20),
        _buildNumericField('Weight', _weightController, 'e.g. 70', 'kg'),
      ],
    );
  }

  Widget _buildStep2() {
    return _StepLayout(
      title: 'Lifestyle Information',
      subtitle: 'These factors significantly impact your wellness predictions.',
      children: [
        _buildDropdown('Activity Level', _activityLevel, ['Sedentary', 'Light', 'Moderate', 'Active'], (val) {
          if (val != null) setState(() => _activityLevel = val);
        }),
        const SizedBox(height: 20),
        _buildNumericField('Daily Sleep Average', _sleepController, 'e.g. 7.5', 'hrs'),
        const SizedBox(height: 20),
        _buildNumericField('Daily Water Intake', _waterController, 'e.g. 2000', 'ml'),
        const SizedBox(height: 20),
        _buildSwitch('Smoking Status', _smoking, (val) => setState(() => _smoking = val)),
        _buildSwitch('Alcohol Consumption', _alcohol, (val) => setState(() => _alcohol = val)),
      ],
    );
  }

  Widget _buildStep3() {
    return _StepLayout(
      title: 'Medical History',
      subtitle: 'Select any conditions you have been diagnosed with.',
      children: [
        ...['Diabetes', 'Hypertension', 'Heart Disease', 'Asthma', 'Thyroid'].map((d) {
          return CheckboxListTile(
            title: Text(d, style: const TextStyle(color: AppTheme.onSurface)),
            value: _pastDiseases.contains(d),
            onChanged: (val) {
              setState(() {
                if (val == true) _pastDiseases.add(d);
                else _pastDiseases.remove(d);
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppTheme.cyanAccent,
            checkColor: AppTheme.navy900,
          );
        }),
        CheckboxListTile(
          title: const Text('None', style: TextStyle(color: AppTheme.onSurface)),
          value: _pastDiseases.isEmpty,
          onChanged: (val) {
            if (val == true) setState(() => _pastDiseases.clear());
          },
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppTheme.cyanAccent,
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return _StepLayout(
      title: 'Family Medical History',
      subtitle: 'Does your immediate family have a history of these conditions?',
      children: _familyHistory.keys.map((k) {
        return _buildSwitch(k, _familyHistory[k]!, (val) {
          setState(() => _familyHistory[k] = val);
        });
      }).toList(),
    );
  }

  Widget _buildStep5() {
    return _StepLayout(
      title: 'Health Goals',
      subtitle: 'What would you like to achieve with MedMind?',
      children: [
        'Lose weight', 'Improve fitness', 'Better sleep', 'Stress reduction', 
        'Disease prevention', 'Muscle gain'
      ].map((g) {
        return FilterChip(
          label: Text(g),
          selected: _goals.contains(g),
          onSelected: (val) {
            setState(() {
              if (val) _goals.add(g);
              else _goals.remove(g);
            });
          },
          selectedColor: AppTheme.cyanAccent,
          labelStyle: TextStyle(
            color: _goals.contains(g) ? AppTheme.navy900 : AppTheme.onSurface,
          ),
        );
      }).toList(),
      isWrap: true,
    );
  }

  Widget _buildStep6() {
    return _StepLayout(
      title: 'App Preferences',
      subtitle: 'Set your daily targets for a healthier life.',
      children: [
        _buildNumericField('Daily Step Goal', _stepGoalController, 'e.g. 10000', 'steps'),
        const SizedBox(height: 20),
        _buildNumericField('Sleep Goal', _sleepGoalController, 'e.g. 8', 'hrs'),
        const SizedBox(height: 20),
        _buildNumericField('Water Goal', _waterGoalController, 'e.g. 12', 'glasses'),
        const SizedBox(height: 20),
        _buildNumericField('Calorie Target', _calorieGoalController, 'e.g. 2200', 'kcal'),
      ],
    );
  }

  // --- Helper Widgets ---

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.navy800,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outline),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppTheme.navy800,
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(color: AppTheme.onSurface)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumericField(String label, TextEditingController controller, String hint, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppTheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            suffixText: unit,
            suffixStyle: const TextStyle(color: AppTheme.cyanAccent, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(color: AppTheme.onSurface)),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.cyanAccent,
      inactiveTrackColor: AppTheme.navy800,
    );
  }
}

class _StepLayout extends StatelessWidget {
  const _StepLayout({
    required this.title,
    required this.subtitle,
    required this.children,
    this.isWrap = false,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool isWrap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(fontSize: 15, color: AppTheme.onSurfaceVariant, height: 1.4)),
          const SizedBox(height: 32),
          if (isWrap)
            Wrap(spacing: 12, runSpacing: 12, children: children)
          else
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ],
      ),
    );
  }
}
