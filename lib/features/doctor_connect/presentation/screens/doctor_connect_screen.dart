import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medmind/core/theme/app_theme.dart';
import 'package:medmind/services/storage_provider.dart';
import 'package:medmind/services/firebase_backend_service.dart';
import 'package:medmind/models/app_backend_models.dart';
import 'package:medmind/shared/widgets/widgets.dart';

class DoctorConnectScreen extends ConsumerStatefulWidget {
  const DoctorConnectScreen({super.key});

  @override
  ConsumerState<DoctorConnectScreen> createState() => _DoctorConnectScreenState();
}

class _DoctorConnectScreenState extends ConsumerState<DoctorConnectScreen> with SingleTickerProviderStateMixin {
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
    final appointments = ref.watch(appointmentsStreamProvider).value ?? [];
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
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildUpcomingSection(appointments),
                              const SizedBox(height: 24),
                              _buildRecentConsultations(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBookNewAppointment(),
                              const SizedBox(height: 24),
                              _buildDoctorNetwork(),
                              const SizedBox(height: 24),
                              _buildHealthRecordsAccess(),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    ..._buildMobileLayout(appointments),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return const Padding(
      padding: EdgeInsets.only(left: 4.0),
      child: Text(
        "Connect with healthcare professionals",
        style: TextStyle(
          color: AppTheme.onSurfaceVariant,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<Widget> _buildMobileLayout(List<Appointment> appointments) {
    return [
      _buildUpcomingSection(appointments),
      const SizedBox(height: 24),
      _buildBookNewAppointment(),
      const SizedBox(height: 24),
      _buildRecentConsultations(),
      const SizedBox(height: 24),
      _buildDoctorNetwork(),
      const SizedBox(height: 24),
      _buildHealthRecordsAccess(),
    ];
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

  Widget _buildUpcomingSection(List<Appointment> appointments) {
    final displayAppointments = appointments.isNotEmpty ? appointments : [
       Appointment(id: '1', doctorName: "Dr. Sarah Johnson", specialization: "Cardiologist", dateTime: DateTime.now().add(const Duration(days: 2, hours: 3)), status: "Confirmed"),
       Appointment(id: '2', doctorName: "Dr. Michael Chen", specialization: "Dermatologist", dateTime: DateTime.now().add(const Duration(days: 5)), status: "Pending"),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Upcoming Appointments"),
        ...displayAppointments.map((appt) => Column(
          children: [
            _buildAppointmentCard(appt),
            const SizedBox(height: 16),
          ],
        )),
      ],
    );
  }

  Widget _buildAppointmentCard(Appointment appt) {
    return _buildCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.navy600,
                child: const Icon(Icons.person, color: AppTheme.cyanAccent, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appt.doctorName,
                      style: const TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      appt.specialization,
                      style: const TextStyle(
                        color: AppTheme.cyanAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: appt.status,
                color: appt.status == "Confirmed" ? AppTheme.success : Colors.orangeAccent,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: AppTheme.outline),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: AppTheme.onSurfaceVariant, size: 18),
              const SizedBox(width: 8),
              Text(
                "${appt.dateTime.day}/${appt.dateTime.month}/${appt.dateTime.year}",
                style: const TextStyle(color: AppTheme.onSurface, fontSize: 14),
              ),
              const SizedBox(width: 20),
              const Icon(Icons.access_time_rounded, color: AppTheme.onSurfaceVariant, size: 18),
              const SizedBox(width: 8),
              Text(
                "${appt.dateTime.hour}:${appt.dateTime.minute.toString().padLeft(2, '0')}",
                style: const TextStyle(color: AppTheme.onSurface, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.onSurface,
                    side: const BorderSide(color: AppTheme.outline),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Reschedule"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cyanAccent,
                    foregroundColor: AppTheme.navy900,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Join Call", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentConsultations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Recent Consultations"),
        _buildCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => Divider(color: AppTheme.outline, height: 1),
            itemBuilder: (context, index) {
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.navy600,
                  child: const Icon(Icons.history, color: AppTheme.onSurfaceVariant, size: 20),
                ),
                title: const Text("Dr. Robert Wilson", style: TextStyle(color: AppTheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
                subtitle: const Text("General Practitioner • 12 Feb 2024", style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13)),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.onSurfaceVariant),
                onTap: () {},
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookNewAppointment() {
    return _buildCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Book New Appointment",
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Find a specialist and schedule a consultation in minutes.",
            style: TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: "Find a Doctor",
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorNetwork() {
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("My Doctor Network"),
         Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             for (int i = 0; i < 4; i++)
               CircleAvatar(
                 radius: 30,
                 backgroundColor: AppTheme.navy600,
                 child: const Icon(Icons.person, color: AppTheme.cyanAccent),
               ),
           ],
         ),
      ],
    );
  }

  Widget _buildHealthRecordsAccess() {
    return _buildCard(
      child: Column(
        children: [
           Row(
             children: [
               const Icon(Icons.folder_shared_rounded, color: AppTheme.cyanAccent),
               const SizedBox(width: 12),
               const Text("Shared Records", style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold)),
             ],
           ),
           const SizedBox(height: 12),
           const Text("4 doctors have access to your health records.", style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13)),
           const SizedBox(height: 16),
           TextButton(
             onPressed: () {},
             child: const Text("Manage Access", style: TextStyle(color: AppTheme.cyanAccent)),
           ),
        ],
      ),
    );
  }
}
