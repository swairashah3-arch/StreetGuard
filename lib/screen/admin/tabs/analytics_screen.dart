import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../admin_dashboard.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // ------------------- APP BAR (Back to Dashboard) -------------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          ),
        ),
        title: const Text(
          "Crime Analytics",
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),

      // ------------------- MAIN BODY -------------------
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Text("Overall Statistics", style: AppTextStyles.sectionTitle),
            const SizedBox(height: 16),

            // KPI CARDS (Metrics)
            _metricCard("Total Reports", "1,248"),
            _metricCard("Serious Crimes", "324"),
            _metricCard("Non-Serious Crimes", "924"),
            _metricCard("Pending Verifications", "59"),

            const SizedBox(height: 24),

            // Crime Breakdown Graph
            Text("Crime Type Breakdown",
                style: AppTextStyles.sectionTitle),
            const SizedBox(height: 14),

            _bar("Harassment", 0.65),
            _bar("Snatching", 0.45),
            _bar("Theft", 0.30),
            _bar("Violence", 0.22),
            _bar("Robbery", 0.18),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ------------------- METRIC CARD -------------------
  Widget _metricCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTextStyles.cardDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.bold16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------- BAR GRAPH -------------------
  Widget _bar(String label, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bold16),
          const SizedBox(height: 6),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(8),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
