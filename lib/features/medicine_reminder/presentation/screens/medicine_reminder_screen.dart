import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medmind/core/theme/app_theme.dart';
import 'package:medmind/services/storage_provider.dart';
import 'package:medmind/models/app_backend_models.dart' as am;
import 'package:medmind/models/medicine_models.dart';
import 'package:medmind/services/medicine_service.dart';
import 'package:medmind/shared/widgets/widgets.dart';
import 'package:intl/intl.dart';

class MedicineReminderScreen extends ConsumerStatefulWidget {
  const MedicineReminderScreen({super.key});

  @override
  ConsumerState<MedicineReminderScreen> createState() => _MedicineReminderScreenState();
}

class _MedicineReminderScreenState extends ConsumerState<MedicineReminderScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final medicationsAsync = ref.watch(medicationsProvider);
    final medications = medicationsAsync.value ?? [];
    
    final nextUp = ref.watch(nextUpProvider);
    final schedule = ref.watch(dailyScheduleProvider);
    final adherence = ref.watch(adherenceProvider);
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.navy900,
            AppTheme.navy800,
          ],
        ),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSubtitle(),
                  const SizedBox(height: 24),
                  if (medications.isEmpty && !medicationsAsync.isLoading)
                    _buildEmptyState()
                  else if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildNextDoseCard(nextUp),
                              const SizedBox(height: 24),
                              _buildDailySchedule(schedule),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMedicationInsights(adherence),
                              const SizedBox(height: 24),
                              _buildRefillReminders(medications),
                              const SizedBox(height: 24),
                              _buildAddMedicationButton(),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    ..._buildMobileLayout(nextUp, schedule, adherence, medications),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
     return Center(
       child: Column(
         children: [
           const SizedBox(height: 60),
           Icon(Icons.medication_outlined, size: 80, color: AppTheme.onSurfaceVariant.withOpacity(0.3)),
           const SizedBox(height: 20),
           const Text("No medications added yet", style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 18)),
           const SizedBox(height: 30),
           _buildAddMedicationButton(),
         ],
       ),
     );
  }

  List<Widget> _buildMobileLayout(Medication? nextUp, List<Medication> schedule, double adherence, List<Medication> medications) {
    return [
      _buildNextDoseCard(nextUp),
      const SizedBox(height: 24),
      _buildDailySchedule(schedule),
      const SizedBox(height: 24),
      _buildMedicationInsights(adherence),
      const SizedBox(height: 24),
      _buildRefillReminders(medications),
      const SizedBox(height: 32),
      _buildAddMedicationButton(),
    ];
  }

  Widget _buildSubtitle() {
    return const Padding(
      padding: EdgeInsets.only(left: 4.0),
      child: Text(
        "Never miss a dose again",
        style: TextStyle(
          color: AppTheme.onSurfaceVariant,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: child,
    );
  }

  Widget _buildNextDoseCard(Medication? nextDose) {
    if (nextDose == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Next Up"),
        _buildCard(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.cyanAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.medication, color: AppTheme.cyanAccent, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nextDose.name,
                      style: const TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${nextDose.dosage} • ${nextDose.time}",
                      style: const TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _takeDose(nextDose),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cyanAccent,
                  foregroundColor: AppTheme.navy900,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text("Take", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailySchedule(List<Medication> schedule) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Daily Schedule"),
        if (schedule.isEmpty)
           const Padding(
             padding: EdgeInsets.all(16.0),
             child: Text("Nothing scheduled for today", style: TextStyle(color: AppTheme.onSurfaceVariant)),
           ),
        ...schedule.map((med) => Column(
          children: [
            _buildMedicationTile(med),
            const SizedBox(height: 12),
          ],
        )),
      ],
    );
  }

  Widget _buildMedicationTile(Medication med) {
    final isTakenToday = med.lastTaken != null && 
        med.lastTaken!.year == DateTime.now().year &&
        med.lastTaken!.month == DateTime.now().month &&
        med.lastTaken!.day == DateTime.now().day;

    return _buildCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isTakenToday ? AppTheme.cyanAccent.withOpacity(0.2) : AppTheme.navy600,
            child: Icon(
              isTakenToday ? Icons.check_circle_rounded : Icons.access_time_filled, 
              color: isTakenToday ? AppTheme.cyanAccent : AppTheme.onSurfaceVariant, 
              size: 20
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: isTakenToday ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  "${med.dosage} • ${med.frequency}",
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                med.time,
                style: const TextStyle(
                  color: AppTheme.cyanAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isTakenToday)
                const Text(
                  "Taken",
                  style: TextStyle(color: AppTheme.cyanAccent, fontSize: 10),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _takeDose(Medication med) async {
    await ref.read(medicineServiceProvider).takeMedication(med.medicationID);
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text("Dose of ${med.name} taken!"),
           backgroundColor: AppTheme.cyanAccent,
           behavior: SnackBarBehavior.floating,
         )
       );
    }
  }

  Widget _buildMedicationInsights(double score) {
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppTheme.cyanAccent, size: 18),
            const SizedBox(width: 8),
            const Text(
              "Dose Adherence",
              style: TextStyle(
                color: AppTheme.cyanAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Weekly Score", style: TextStyle(color: AppTheme.onSurface, fontSize: 14)),
                  Text("${score.toInt()}%", style: const TextStyle(color: AppTheme.cyanAccent, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: score / 100,
                  minHeight: 8,
                  backgroundColor: AppTheme.navy600,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.cyanAccent),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                score >= 90 
                  ? "Great job! Your adherence is excellent." 
                  : "Try to stay consistent with your medication.",
                style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRefillReminders(List<Medication> medications) {
    final lowStockMeds = medications.where((m) => m.quantityRemaining <= m.refillThreshold).toList();

    if (lowStockMeds.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Refills Needed"),
        ...lowStockMeds.map((med) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined, color: Colors.orangeAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text("${med.name} (${med.dosage})", style: const TextStyle(color: AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                    Text("${med.quantityRemaining} left", style: const TextStyle(color: Colors.orangeAccent, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: "Order Refill",
                  onPressed: () {},
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildAddMedicationButton() {
     return PrimaryButton(
       label: "Add New Medication",
       onPressed: () => _showAddMedicationSheet(context),
     );
  }

  void _showAddMedicationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMedicationSheet(),
    );
  }
}

class _AddMedicationSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends ConsumerState<_AddMedicationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _quantityController = TextEditingController(text: '30');
  final _thresholdController = TextEditingController(text: '5');
  
  String _frequency = 'Daily';
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.navy800,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Add New Medication",
                style: TextStyle(color: AppTheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildTextField("Medicine Name", _nameController),
              const SizedBox(height: 16),
              _buildTextField("Dosage (e.g. 500mg)", _dosageController),
              const SizedBox(height: 16),
              const Text("Frequency", style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _frequency,
                dropdownColor: AppTheme.navy700,
                decoration: _inputDecoration(""),
                style: const TextStyle(color: AppTheme.onSurface),
                items: ['Daily', 'Twice daily', 'Weekly'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: (v) => setState(() => _frequency = v!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTimePicker()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDatePicker("Start Date", _startDate, (d) => setState(() => _startDate = d))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField("Qty Remaining", _quantityController, isNumber: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField("Refill at", _thresholdController, isNumber: true)),
                ],
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: "Save Medication",
                onPressed: _save,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: AppTheme.onSurface),
          decoration: _inputDecoration(label),
          validator: (v) => v == null || v.isEmpty ? "Required" : null,
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Time", style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(context: context, initialTime: _time);
            if (picked != null) setState(() => _time = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: AppTheme.navy700, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.outline)),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: AppTheme.cyanAccent, size: 20),
                const SizedBox(width: 12),
                Text(_time.format(context), style: const TextStyle(color: AppTheme.onSurface)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime date, Function(DateTime) onPicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
            if (picked != null) onPicked(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: AppTheme.navy700, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.outline)),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppTheme.cyanAccent, size: 20),
                const SizedBox(width: 12),
                Text(DateFormat('MMM dd').format(date), style: const TextStyle(color: AppTheme.onSurface)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: AppTheme.navy700,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.outline)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.outline)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cyanAccent)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final medication = Medication(
        medicationID: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        dosage: _dosageController.text,
        frequency: _frequency,
        time: "${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}",
        startDate: _startDate,
        endDate: _endDate,
        quantityRemaining: int.parse(_quantityController.text),
        refillThreshold: int.parse(_thresholdController.text),
      );

      await ref.read(medicineServiceProvider).addMedication(medication);
      if (mounted) Navigator.pop(context);
    }
  }
}
