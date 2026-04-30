import 'package:flutter/material.dart';
import 'package:teststreetguard/screen/auth/login_screen.dart';

import '../../theme/app_colors.dart';
import 'tabs/reports_management.dart';
import 'tabs/send_alerts.dart';
import 'tabs/patrolled_zones.dart';
import 'tabs/analytics_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final double gap = 14;

    return Scaffold(
      backgroundColor: AppColors.background,

      // ------------------ HEADER ------------------
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined,
                  size: 28, color: AppColors.primary),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "StreetGuard Admin",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Law Enforcement Dashboard",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ),

        actions: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text("Officer John",
                  style: TextStyle(color: Colors.black87, fontSize: 13)),
              Text("test@example.com",
                  style: TextStyle(color: Colors.black54, fontSize: 11)),
            ],
          ),
          const SizedBox(width: 10),

          // Logout button matching user dashboard
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black26),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text("Logout",
                  style: TextStyle(color: Colors.black87)),
            ),
          ),
        ],
      ),

      // ------------------ BODY ------------------
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ------------------ STATS GRID ------------------
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                crossAxisSpacing: gap,
                mainAxisSpacing: gap,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.4,
                children: [
                  _statCard("Pending Reports", "24", Icons.error_outline),
                  _statCard("Verified", "142", Icons.check_circle_outline),
                  _statCard("Today's Reports", "18",
                      Icons.show_chart_outlined),
                  _statCard("Hotspots", "7",
                      Icons.location_on_outlined),
                ],
              ),

              const SizedBox(height: 20),

              // ------------------ QUICK ACTIONS ------------------
              const Text(
                "Quick Actions",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _actionCard(
                    context,
                    label: "Reports\nManagement",
                    icon: Icons.assignment_outlined,
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ReportsManagement()),
                      );
                    },
                  ),
                  _actionCard(
                    context,
                    label: "Send\nAlerts",
                    icon: Icons.notifications_active_outlined,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SendAlertsScreen()),
                      );
                    },
                  ),
                  _actionCard(
                    context,
                    label: "Patrolled\nZones",
                    icon: Icons.shield_outlined,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PatrolledZonesScreen()),
                      );
                    },
                  ),
                  _actionCard(
                    context,
                    label: "Analytics",
                    icon: Icons.analytics_outlined,
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AnalyticsScreen()),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // ------------------ OPTIONAL PREVIEW ------------------
              const Text("Recent Reports",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),

              _miniReport("Snatching", "Model Town", "2 hrs ago"),
              const SizedBox(height: 10),
              _miniReport("Harassment", "DHA Phase 4", "5 hrs ago"),
              const SizedBox(height: 10),
              _miniReport("Theft", "Iqbal Town", "8 hrs ago"),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------ WIDGETS ------------------

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 8),
                Text(value,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Icon(icon, size: 26, color: Colors.black26),
        ],
      ),
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: (MediaQuery.of(context).size.width - 40) / 2,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _miniReport(String type, String area, String time) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(type,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(area, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 4),
              Text(time, style: const TextStyle(color: Colors.black45)),
            ],
          )
        ],
      ),
    );
  }
}
