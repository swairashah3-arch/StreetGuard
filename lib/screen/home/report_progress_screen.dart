import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../services/api_service.dart';

class ReportProgressScreen extends StatefulWidget {
  final String crimeId;

  const ReportProgressScreen({
    super.key,
    required this.crimeId,
  });

  @override
  State<ReportProgressScreen> createState() => _ReportProgressScreenState();
}

class _ReportProgressScreenState extends State<ReportProgressScreen> {
  Timer? _pollTimer;
  Map<String, dynamic>? _reportDetails;
  bool _isLoading = true;
  String _status = 'pending_control_room';

  @override
  void initState() {
    super.initState();
    _fetchDetails();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchDetails();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    try {
      final details = await ApiService.fetchSosStatus(widget.crimeId); // Reusing fetch status API
      if (details != null && mounted) {
        setState(() {
          _reportDetails = details;
          _status = details['workflowStatus'] ?? 'pending_control_room';
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching progress: $e");
    }
  }

  int _getActiveStep() {
    switch (_status) {
      case 'pending_control_room':
        return 0;
      case 'assigned_to_patrol':
        return 1;
      case 'verified_by_patrol':
      case 'rejected_by_patrol':
        return 2;
      case 'forwarded_to_admin':
      case 'published':
      case 'resolved':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int activeStep = _getActiveStep();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Report Tracker", style: AppTextStyles.sectionTitle),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReportSummaryCard(),
                    _buildArrivalEtaCard(),
                    const SizedBox(height: 32),
                    const Text("Investigation Progress", style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 24),
                    _buildStepper(activeStep),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildArrivalEtaCard() {
    if (_reportDetails == null) return const SizedBox.shrink();
    final eta = _reportDetails!['estimatedEta'];
    final arrived = _reportDetails!['patrolArrived'] ?? false;
    
    if (_status == 'pending_control_room') return const SizedBox.shrink();
    if (_status == 'resolved' || _status == 'published') return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: arrived ? Colors.green.shade50 : AppColors.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: arrived ? Colors.green.shade200 : AppColors.accent.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            arrived ? Icons.verified_user_rounded : Icons.radar_rounded,
            color: arrived ? Colors.green.shade700 : AppColors.accent,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  arrived ? "Patrol Arrived" : "Patrol En Route",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: arrived ? Colors.green.shade900 : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  arrived
                      ? "The dispatched patrol unit has arrived at the crime spot."
                      : "ETA: Patrolling team arriving in approximately $eta mins.",
                  style: TextStyle(
                    fontSize: 11,
                    color: arrived ? Colors.green.shade800 : AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSummaryCard() {
    if (_reportDetails == null) return const SizedBox.shrink();

    final title = _reportDetails!['title'] ?? 'Unknown Incident';
    final location = _reportDetails!['location'] ?? 'Unknown Location';
    final type = _reportDetails!['type'] ?? 'general';
    final desc = _reportDetails!['description'] ?? 'No description provided.';
    final dateStr = _reportDetails!['createdAt'] != null
        ? DateTime.parse(_reportDetails!['createdAt']).toLocal().toString().split('.')[0]
        : 'Recently';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: type == 'serious' ? AppColors.danger.withOpacity(0.1) : AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: type == 'serious' ? AppColors.danger : AppColors.accent,
                  ),
                ),
              ),
              Text(dateStr, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.title.copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.secondary),
              const SizedBox(width: 6),
              Expanded(child: Text(location, style: AppTextStyles.body.copyWith(color: AppColors.secondary, fontSize: 13))),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(desc, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildStepper(int activeStep) {
    final patrolName = _reportDetails?['assignedPatrolTeam']?['fullName'] ?? 'Patrol Unit';
    final area = _reportDetails?['assignedPatrolTeam']?['allocatedArea'] ?? '';
    final eta = _reportDetails?['estimatedEta'];
    final arrived = _reportDetails?['patrolArrived'] ?? false;

    // Define steps
    final List<Map<String, String>> steps = [
      {
        'title': 'Report Submitted',
        'desc': 'Successfully lodged. Sent to the Control Room for validation.'
      },
      {
        'title': 'Patrol Unit Dispatched',
        'desc': _status == 'pending_control_room'
            ? 'Waiting for Control Room to assign a local patrol team.'
            : 'Assigned to: $patrolName${area.isNotEmpty ? " ($area)" : ""}. Team is dispatched to check the area.'
      },
      {
        'title': 'On-Site Verification',
        'desc': arrived
            ? '🚨 Patrol unit has arrived on-site!'
            : _status == 'pending_control_room' || _status == 'assigned_to_patrol'
                ? (eta != null ? 'Unit en route. Arriving in $eta mins.' : 'Unit will verify the situation on-site upon arrival.')
                : _status == 'rejected_by_patrol'
                    ? 'Verification complete. Report marked as unverified/rejected.'
                    : 'Incident successfully verified on-site by patrol team.'
      },
      {
        'title': 'Investigation Complete / Resolved',
        'desc': _status == 'resolved'
            ? 'Situation fully resolved and closed by Administration.'
            : _status == 'published'
                ? 'Report published to the citizen safety heatmap.'
                : 'Action pending. Under Admin review.'
      }
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final isCompleted = activeStep > index;
        final isActive = activeStep == index;
        final isLast = index == steps.length - 1;

        Color markerColor = AppColors.secondary.withOpacity(0.3);
        if (isCompleted) markerColor = AppColors.success;
        if (isActive) markerColor = AppColors.accent;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: markerColor.withOpacity(0.15),
                    border: Border.all(color: markerColor, width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: markerColor,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 50,
                    color: isCompleted ? AppColors.success : AppColors.secondary.withOpacity(0.2),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    steps[index]['title']!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isActive ? AppColors.accent : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[index]['desc']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? AppColors.primary.withOpacity(0.7) : AppColors.secondary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
