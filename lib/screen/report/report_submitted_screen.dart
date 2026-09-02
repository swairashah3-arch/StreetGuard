import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../home/dashboard_screen.dart';
import '../home/report_progress_screen.dart';
import '../home/incident_history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/custom_button.dart';

class ReportSubmittedScreen extends StatefulWidget {
  final String? crimeId;

  const ReportSubmittedScreen({super.key, this.crimeId});

  @override
  State<ReportSubmittedScreen> createState() => _ReportSubmittedScreenState();
}

class _ReportSubmittedScreenState extends State<ReportSubmittedScreen> {
  String userName = "User";

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('userName');
    if (name != null) {
      setState(() => userName = name);
    }
  }

  @override
  Widget build(BuildContext context) {
    String refId = "SG-${DateTime.now().year}-${(1000 + DateTime.now().millisecond).toString()}";

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Animation / Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    size: 80,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  "Report Successfully Lodged",
                  style: AppTextStyles.display,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Your contribution helps keep the community safe. Authorities have been alerted.",
                  style: AppTextStyles.subtitle,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: AppTextStyles.premiumCard,
                  child: Column(
                    children: [
                      _statusItem(Icons.history_edu_rounded, "Tracking ID", refId, isBold: true),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1),
                      ),
                      _statusItem(Icons.update_rounded, "Current Status", "Pending Review"),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                CustomButton(
                  text: "Track Incident",
                  onPressed: () {
                    if (widget.crimeId != null && widget.crimeId!.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportProgressScreen(
                            crimeId: widget.crimeId!,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IncidentHistoryScreen(userName: userName),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DashboardScreen(userName: userName),
                      ),
                    );
                  },
                  child: Text(
                    "Return to Dashboard",
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusItem(IconData icon, String label, String value, {bool isBold = false}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 24),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            Text(
              value,
              style: AppTextStyles.body.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
