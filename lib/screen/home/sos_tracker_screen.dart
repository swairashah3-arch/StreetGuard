import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../services/api_service.dart';

class SosTrackerScreen extends StatefulWidget {
  final String crimeId;
  final bool isSilent;

  const SosTrackerScreen({
    super.key,
    required this.crimeId,
    required this.isSilent,
  });

  @override
  State<SosTrackerScreen> createState() => _SosTrackerScreenState();
}

class _SosTrackerScreenState extends State<SosTrackerScreen> {
  Timer? _statusPollTimer;
  Map<String, dynamic>? _sosDetails;
  bool _isLoading = true;
  String _status = 'pending_control_room';
  bool _isDimmed = false;
  int _unlockTapsCount = 0;
  Timer? _tapResetTimer;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    
    // Set up status polling every 5 seconds
    _statusPollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchStatus();
    });

    // If silent, automatically dim the screen after a 4-second confirmation preview
    if (widget.isSilent) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _isDimmed = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    _tapResetTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchStatus() async {
    try {
      final details = await ApiService.fetchSosStatus(widget.crimeId);
      if (details != null && mounted) {
        setState(() {
          _sosDetails = details;
          _status = details['workflowStatus'] ?? 'pending_control_room';
          _isLoading = false;
        });

        // Vibrate to alert user when status updates from pending to assigned/resolved (if not silent)
        if (!widget.isSilent && _status != 'pending_control_room') {
          HapticFeedback.heavyImpact();
        }
      }
    } catch (e) {
      print("Error polling status: $e");
    }
  }

  void _handleDimScreenTap() {
    _unlockTapsCount++;
    _tapResetTimer?.cancel();
    
    if (_unlockTapsCount >= 3) {
      setState(() {
        _isDimmed = false;
        _unlockTapsCount = 0;
      });
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
      _tapResetTimer = Timer(const Duration(seconds: 2), () {
        _unlockTapsCount = 0;
      });
    }
  }

  int _getStatusStep() {
    switch (_status) {
      case 'pending_control_room':
        return 0;
      case 'assigned_to_patrol':
        return 1;
      case 'verified_by_patrol':
      case 'forwarded_to_admin':
      case 'published':
        return 2;
      case 'resolved':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDimmed) {
      return _buildDimmedStealthScreen();
    }

    final int currentStep = _getStatusStep();
    final bool isResolved = _status == 'resolved';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("SOS Emergency Link", style: AppTextStyles.sectionTitle),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: isResolved, // Only allow back navigation if resolved
        leading: isResolved
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Confirmation status card
              _buildConfirmationCard(),
              _buildArrivalEtaCard(),
              const SizedBox(height: 32),

              // Emergency Dispatch workflow title
              const Text('Dispatcher Status Tracker', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 16),

              // Visual timeline vertical steps
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.danger))
                    : _buildStatusTimeline(currentStep),
              ),

              // Close / Dismiss button (visible only if resolved, or optional cancel for citizens)
              if (isResolved)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              else
                Column(
                  children: [
                    if (widget.isSilent)
                      TextButton.icon(
                        onPressed: () => setState(() => _isDimmed = true),
                        icon: const Icon(Icons.screen_lock_portrait_rounded, size: 18),
                        label: const Text('Re-enter Dim Mode'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade100),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_tethering_rounded, color: AppColors.danger, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Live Location Sharing Active',
                            style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alert Sent Successfully',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isSilent
                      ? 'Silent Background Mode Enabled'
                      : 'Authorities and nearby patrols notified.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildArrivalEtaCard() {
    if (_sosDetails == null) return const SizedBox.shrink();
    final eta = _sosDetails!['estimatedEta'];
    final arrived = _sosDetails!['patrolArrived'] ?? false;
    
    if (_status == 'pending_control_room') return const SizedBox.shrink();
    if (_status == 'resolved') return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: arrived ? Colors.green.shade50 : AppColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: arrived ? Colors.green.shade200 : AppColors.danger.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            arrived ? Icons.verified_user_rounded : Icons.radar_rounded,
            color: arrived ? Colors.green.shade700 : AppColors.danger,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  arrived ? "Patrol Arrived" : "Emergency Patrol En Route",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: arrived ? Colors.green.shade900 : AppColors.danger,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  arrived
                      ? "The dispatched patrol unit has arrived at your location."
                      : "ETA: Responders arriving in approximately $eta mins.",
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

  Widget _buildStatusTimeline(int currentStep) {
    final patrolName = _sosDetails?['assignedPatrolTeam']?['fullName'] ?? 'Patrol Team';
    final area = _sosDetails?['assignedPatrolTeam']?['allocatedArea'] ?? '';
    final eta = _sosDetails?['estimatedEta'];
    final arrived = _sosDetails?['patrolArrived'] ?? false;

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        _timelineStep(
          stepIndex: 0,
          currentStep: currentStep,
          title: 'Emergency SOS Broadcasted',
          subtitle: 'SOS packet successfully dispatched to Control Room.',
        ),
        _timelineStep(
          stepIndex: 1,
          currentStep: currentStep,
          title: 'Patrol Dispatcher Contacted',
          subtitle: currentStep >= 1
              ? 'Control Room reviewed alert. Assigned: $patrolName${area.isNotEmpty ? " ($area)" : ""}.'
              : 'Waiting for Control Room to delegate a local patrol unit.',
        ),
        _timelineStep(
          stepIndex: 2,
          currentStep: currentStep,
          title: 'Responders En Route / Checking',
          subtitle: arrived
              ? '🚨 Patrol unit has arrived at your location!'
              : currentStep >= 2
                  ? 'Patrol unit has reached your vicinity and is performing checks.'
                  : eta != null
                      ? 'Dispatched unit is arriving in approximately $eta minutes.'
                      : 'Unit will initiate search upon arrival.',
        ),
        _timelineStep(
          stepIndex: 3,
          currentStep: currentStep,
          title: 'Incident Resolved',
          subtitle: currentStep >= 3
              ? 'Threat resolved. Patrol marked situation safe.'
              : 'Stay in a secure location until marked resolved.',
          isLast: true,
        ),
      ],
    );
  }

  Widget _timelineStep({
    required int stepIndex,
    required int currentStep,
    required String title,
    required String subtitle,
    bool isLast = false,
  }) {
    final bool isCompleted = currentStep > stepIndex;
    final bool isActive = currentStep == stepIndex;

    Color markerColor = AppColors.secondary.withOpacity(0.3);
    if (isCompleted) markerColor = AppColors.success;
    if (isActive) markerColor = AppColors.danger;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left timeline column
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: markerColor.withOpacity(0.15),
                border: Border.all(color: markerColor, width: 2),
              ),
              child: Center(
                child: Container(
                  width: 10,
                  height: 10,
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
                height: 60,
                color: isCompleted ? AppColors.success : AppColors.secondary.withOpacity(0.2),
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Content column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isActive ? AppColors.danger : AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
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
  }

  Widget _buildDimmedStealthScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _handleDimScreenTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.white.withOpacity(0.06),
                  size: 40,
                ),
                const SizedBox(height: 16),
                Text(
                  'Silent Alert Sent in Background',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.08),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap screen 3 times to view details',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.05),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
