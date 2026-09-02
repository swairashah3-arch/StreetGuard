import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../services/api_service.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  // Profile Data
  Map<String, dynamic>? _profile;
  int _rewardPoints = 0;
  bool _isBestCitizen = false;
  List<Map<String, dynamic>> _myReports = [];
  
  // Leaderboard Data
  List<dynamic> _leaderboard = [];
  bool _isLoading = true;
  bool _isLeaderboardLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRewardsData();
    _loadLeaderboardData();
  }

  Future<void> _loadRewardsData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await ApiService.fetchUserProfile();
      final reports = await ApiService.fetchMyReports();

      setState(() {
        _profile = profile;
        _rewardPoints = profile?['rewardPoints'] ?? 0;
        _isBestCitizen = profile?['isBestCitizenOfMonth'] ?? false;
        _myReports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLeaderboardData() async {
    setState(() => _isLeaderboardLoading = true);
    try {
      final ranking = await ApiService.fetchLeaderboard();
      setState(() {
        _leaderboard = ranking ?? [];
        _isLeaderboardLoading = false;
      });
    } catch (e) {
      setState(() => _isLeaderboardLoading = false);
    }
  }

  void _showProfileDialog() {
    if (_profile == null) return;
    
    final fullName = _profile!['fullName'] ?? 'Citizen';
    final email = _profile!['email'] ?? 'N/A';
    final phone = _profile!['phoneNumber'] ?? 'N/A';
    final cnic = _profile!['cnic'] ?? 'N/A';
    final totalReports = _profile!['totalReports'] ?? 0;
    final resolvedReports = _profile!['resolvedReports'] ?? 0;
    final sosTriggers = _profile!['sosTriggers'] ?? 0;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          fullName.substring(0, fullName.length > 0 ? 1 : 0).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text('App Utilization Stats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statWidget('Total Reports', '$totalReports', Icons.assignment_turned_in_outlined),
                      _statWidget('Resolved', '$resolvedReports', Icons.check_circle_outline),
                      _statWidget('SOS Signals', '$sosTriggers', Icons.error_outline),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text('Personal Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  _infoRow(Icons.phone_iphone_rounded, 'Phone', phone),
                  _infoRow(Icons.badge_outlined, 'CNIC Number', cnic),
                  const Divider(height: 32),
                  const Text('Your Contributions & Reports', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 12),
                  if (_myReports.isEmpty)
                    _buildEmptyHistory()
                  else
                    ..._myReports.map((report) => _buildReportRewardCard(report)),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statWidget(String label, String val, IconData icon) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 6),
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(val, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text("Rewards & Rankings", style: AppTextStyles.sectionTitle),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_profile != null)
              GestureDetector(
                onTap: _showProfileDialog,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      (_profile!['fullName'] ?? 'C').substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(text: "My Rewards"),
              Tab(text: "Leaderboard"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : TabBarView(
                children: [
                  // Tab 1: My Rewards
                  RefreshIndicator(
                    color: AppColors.accent,
                    onRefresh: _loadRewardsData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPointsBalanceCard(),
                          const SizedBox(height: 20),
                          // Premium Status Alerts list
                          _buildStatusAlertsList(),
                          const SizedBox(height: 20),
                          _buildRulesCard(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                  // Tab 2: Leaderboard
                  RefreshIndicator(
                    color: AppColors.accent,
                    onRefresh: _loadLeaderboardData,
                    child: _isLeaderboardLoading
                        ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                            itemCount: _leaderboard.isEmpty ? 2 : _leaderboard.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Top Citizens of Abbottabad', style: AppTextStyles.sectionTitle),
                                    const SizedBox(height: 4),
                                    const Text('Earn points by reporting verified safety alerts', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                    const SizedBox(height: 20),
                                  ],
                                );
                              }
                              if (_leaderboard.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 40),
                                    child: Text(
                                      'No active users on the leaderboard yet.',
                                      style: TextStyle(color: Colors.grey.shade500),
                                    ),
                                  ),
                                );
                              }
                              final citizen = _leaderboard[index - 1];
                              return _buildLeaderboardCard(citizen, index);
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatusAlertsList() {
    List<Widget> alerts = [];

    // Alert 1: Best Citizen of the Month
    if (_isBestCitizen) {
      alerts.add(_statusAlertItem(
        icon: Icons.emoji_events,
        iconColor: Colors.amber.shade800,
        backgroundColor: Colors.amber.shade50,
        borderColor: Colors.amber.shade200,
        title: 'Best Citizen of the Month!',
        description: 'You are recognized by the department as this month\'s top safety contributor.',
      ));
    }

    // Alert 2: Department Commendation Recognition
    if (_rewardPoints >= 300) {
      alerts.add(_statusAlertItem(
        icon: Icons.verified_user_rounded,
        iconColor: Colors.blue.shade800,
        backgroundColor: Colors.blue.shade50,
        borderColor: Colors.blue.shade200,
        title: 'Department Recognition Commendation',
        description: 'Awarded for active safety engagement and securing 300+ contribution points.',
      ));
    }

    // Alert 3: Milestone Target Alert
    String currentRank;
    String nextRank;
    int pointsNeeded;
    if (_rewardPoints < 100) {
      currentRank = 'Safe Guard';
      nextRank = 'Safety Shield';
      pointsNeeded = 100 - _rewardPoints;
    } else if (_rewardPoints < 300) {
      currentRank = 'Safety Shield';
      nextRank = 'Community Hero';
      pointsNeeded = 300 - _rewardPoints;
    } else {
      currentRank = 'Community Hero';
      nextRank = '';
      pointsNeeded = 0;
    }

    if (pointsNeeded > 0) {
      alerts.add(_statusAlertItem(
        icon: Icons.tour_outlined,
        iconColor: Colors.purple.shade800,
        backgroundColor: Colors.purple.shade50,
        borderColor: Colors.purple.shade200,
        title: 'Milestone Goal: $nextRank',
        description: 'You are currently a $currentRank. Earn $pointsNeeded more points to reach $nextRank!',
      ));
    } else {
      alerts.add(_statusAlertItem(
        icon: Icons.shield_rounded,
        iconColor: Colors.teal.shade800,
        backgroundColor: Colors.teal.shade50,
        borderColor: Colors.teal.shade200,
        title: 'Top Tier: $currentRank',
        description: 'Congratulations! You have reached the highest safety rank as a verified Community Hero.',
      ));
    }

    return Column(
      children: alerts.map((widget) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: widget,
        );
      }).toList(),
    );
  }

  Widget _statusAlertItem({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: iconColor),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 11.5, color: iconColor.withOpacity(0.85), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade800,
            Colors.amber.shade600,
            Colors.orangeAccent.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.shade900.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Citizen Points Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.stars, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Verified Citizen',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$_rewardPoints',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep reporting to earn points and help keep our community safe.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTextStyles.premiumCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 20),
              SizedBox(width: 10),
              Text('Points Policy Guidelines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          _ruleItem(Icons.gavel_rounded, Colors.purple, 'Street Crime Report', 'Earns 100 Points', 'For reporting verified serious public safety threats.'),
          const Divider(height: 24, color: AppColors.border),
          _ruleItem(Icons.visibility_outlined, AppColors.success, 'Observational Report', 'Earns 50 Points', 'For reporting non-urgent community observations.'),
        ],
      ),
    );
  }

  Widget _ruleItem(IconData icon, Color color, String title, String pointsStr, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: AppTextStyles.caption),
            ],
          ),
        ),
        Text(
          pointsStr,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events_outlined, color: AppColors.secondary.withOpacity(0.2), size: 54),
          const SizedBox(height: 12),
          const Text('No Points Earned Yet', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 4),
          const Text('Submit your first crime report to start earning rewards.', style: AppTextStyles.subtitle, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildReportRewardCard(Map<String, dynamic> report) {
    final bool isSerious = report['type'] == 'serious';
    final int points = isSerious ? 100 : 50;
    final Color color = isSerious ? Colors.purple : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTextStyles.premiumCard,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSerious ? Icons.gavel_rounded : Icons.visibility_outlined,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report['title'] ?? 'Incident Report',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 10, color: AppColors.secondary.withOpacity(0.8)),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(report['createdAt']),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '+$points pts',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildLeaderboardCard(dynamic citizen, int rank) {
    final name = citizen['fullName'] ?? 'Citizen';
    final points = citizen['rewardPoints'] ?? 0;
    final reports = citizen['reportCount'] ?? 0;
    final isBest = citizen['isBestCitizenOfMonth'] ?? false;

    // Activity Tier Classification
    String activityTier;
    Color activityColor;
    if (reports >= 5) {
      activityTier = 'Highly Active';
      activityColor = AppColors.success;
    } else if (reports >= 2) {
      activityTier = 'Active';
      activityColor = Colors.blue;
    } else {
      activityTier = 'New Contributor';
      activityColor = Colors.grey;
    }

    Color rankColor;
    if (rank == 1) {
      rankColor = Colors.amber.shade700;
    } else if (rank == 2) {
      rankColor = Colors.blueGrey;
    } else if (rank == 3) {
      rankColor = Colors.brown;
    } else {
      rankColor = Colors.grey.shade400;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTextStyles.premiumCard.copyWith(
        border: isBest ? Border.all(color: Colors.amber.shade400, width: 1.5) : null,
      ),
      child: Row(
        children: [
          // Circular Avatar with small overlapping rank badge overlay
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withOpacity(0.08),
                child: Text(
                  name.substring(0, name.length > 0 ? 1 : 0).toUpperCase(),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: rankColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9),
                    ),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: 16),
          // User Details & Badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Dynamic Recognition Badges
                Row(
                  children: [
                    if (isBest) ...[
                      const Icon(Icons.emoji_events, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text('Best Citizen', style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 9.5)),
                      const SizedBox(width: 10),
                    ],
                    if (points >= 300) ...[
                      const Icon(Icons.verified_user_rounded, color: Colors.blue, size: 14),
                      const SizedBox(width: 4),
                      const Text('Dept Recognised', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 9.5)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                // Detailed metrics
                Text(
                  'Reports: $reports | $activityTier',
                  style: TextStyle(color: activityColor, fontWeight: FontWeight.w600, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Points Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$points',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary),
              ),
              const Text(
                'pts',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
