import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class ReportsManagement extends StatelessWidget {
  const ReportsManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Reports Management",
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Pending Reports", style: AppTextStyles.sectionTitle),
            const SizedBox(height: 16),

            _reportCard(
              type: "Snatching",
              user: "Ayesha Khan",
              location: "Model Town",
              time: "2 hours ago",
            ),

            _reportCard(
              type: "Harassment",
              user: "Hamza Malik",
              location: "DHA Phase 5",
              time: "5 hours ago",
            ),

            const SizedBox(height: 24),

            Text("Verified Reports", style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),

            _verifiedCard(
              type: "Robbery",
              date: "Jan 22, 2025",
              officer: "Officer Ahmed",
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportCard({
    required String type,
    required String user,
    required String location,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: AppTextStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(type, style: AppTextStyles.bold16),
          const SizedBox(height: 6),
          Text("Reported by: $user", style: AppTextStyles.subtitle),
          Text("Location: $location", style: AppTextStyles.subtitle),
          Text("Time: $time", style: AppTextStyles.subtitle),

          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: () {},
                child: const Text("View Details"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {},
                child: const Text("Verify"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _verifiedCard({
    required String type,
    required String date,
    required String officer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: AppTextStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(type, style: AppTextStyles.bold16),
          const SizedBox(height: 6),
          Text("Verified on: $date", style: AppTextStyles.subtitle),
          Text("Reviewed by: $officer", style: AppTextStyles.subtitle),
        ],
      ),
    );
  }
}
