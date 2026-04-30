import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/quick_action_card.dart';
import '../report/serious_report_screen.dart';
import '../report/non_serious_report_screen.dart';
import '../auth/login_screen.dart';
import '../map/crime_map_screen.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;

  const DashboardScreen({super.key, required this.userName});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _publishedAlerts = [];
  bool _loadingAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final alerts = await ApiService.fetchPublishedAlerts();
      setState(() {
        _publishedAlerts = alerts;
        _loadingAlerts = false;
      });
    } catch (e) {
      setState(() => _loadingAlerts = false);
    }
  }

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium Sliver App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                'StreetGuard',
                style: AppTextStyles.title.copyWith(color: AppColors.primary),
              ),
              background: Container(color: AppColors.background),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Welcome Section
                const SizedBox(height: 8),
                Text('Hello, ${widget.userName} 👋', style: AppTextStyles.display.copyWith(fontSize: 24)),
                const SizedBox(height: 4),
                const Text('Your community is stable today.', style: AppTextStyles.subtitle),
                
                const SizedBox(height: 32),

                // Quick Actions Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    QuickActionCard(
                      icon: Icons.sos_rounded,
                      title: 'Emergency SOS',
                      subtitle: 'Instant alert',
                      color: AppColors.danger,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                                SizedBox(width: 10),
                                Text("Emergency SOS"),
                              ],
                            ),
                            content: const Text("Dispatching emergency units to your current location. Please stay safe."),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("DISMISS", style: TextStyle(color: AppColors.secondary)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    QuickActionCard(
                      icon: Icons.gavel_rounded,
                      title: 'Serious Crime',
                      subtitle: 'Legal reporting',
                      color: Colors.deepPurple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SeriousReportScreen()),
                      ),
                    ),
                    QuickActionCard(
                      icon: Icons.visibility_outlined,
                      title: 'Observe',
                      subtitle: 'Non-urgent',
                      color: AppColors.accent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NonSeriousReportScreen()),
                      ),
                    ),
                    QuickActionCard(
                      icon: Icons.map_rounded,
                      title: 'Safety Map',
                      subtitle: 'Area insights',
                      color: Colors.teal,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CrimeMapScreen()),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Community Alerts Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Community Alerts', style: AppTextStyles.sectionTitle),
                    if (!_loadingAlerts && _publishedAlerts.isNotEmpty)
                      Text(
                        '${_publishedAlerts.length} active',
                        style: AppTextStyles.caption.copyWith(color: AppColors.danger, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_loadingAlerts)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ))
                else if (_publishedAlerts.isEmpty)
                  _buildEmptyState()
                else
                  ..._publishedAlerts.take(5).map((alert) => _buildAlertCard(alert)),

                const SizedBox(height: 32),

                // Safety Tips
                _buildSafetyTips(),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.shield_rounded, color: AppColors.success.withOpacity(0.2), size: 64),
          const SizedBox(height: 16),
          const Text('All Clear', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 4),
          const Text('No active alerts in your vicinity.', style: AppTextStyles.subtitle),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final bool isSerious = alert['type'] == 'serious';
    final Color color = isSerious ? AppColors.danger : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTextStyles.premiumCard,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 6)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isSerious ? 'SERIOUS' : 'ALERT',
                              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(_timeAgo(alert['createdAt']), style: AppTextStyles.caption),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(alert['title'] ?? 'Incident', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.secondary),
                          const SizedBox(width: 4),
                          Expanded(child: Text(alert['area'] ?? 'Unknown', style: AppTextStyles.caption, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.border),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyTips() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: AppColors.warning),
              SizedBox(width: 12),
              Text('Security Insight', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          _tipItem('Avoid solo travel in unlit areas during late hours.'),
          _tipItem('Ensure your location sharing is active for verified contacts.'),
          _tipItem('Report any suspicious behavior immediately to local patrol.'),
        ],
      ),
    );
  }

  Widget _tipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }
}
