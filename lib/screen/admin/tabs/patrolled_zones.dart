import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../admin_dashboard.dart';

class PatrolledZonesScreen extends StatefulWidget {
  const PatrolledZonesScreen({super.key});

  @override
  State<PatrolledZonesScreen> createState() => _PatrolledZonesScreenState();
}

class _PatrolledZonesScreenState extends State<PatrolledZonesScreen> {
  final TextEditingController zoneController = TextEditingController();
  double radius = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboard()),
            );
          },
        ),
        title: const Text("Patrolled Zones",
            style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Create Patrolled Zones", style: AppTextStyles.sectionTitle),
            const SizedBox(height: 14),

            const Text("Area Name"),
            const SizedBox(height: 6),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: AppTextStyles.cardDecoration,
              child: TextField(
                controller: zoneController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Enter area or street…",
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text("Radius (KM)"),
            Slider(
              value: radius,
              min: 0.5,
              max: 10,
              divisions: 19,
              label: "${radius.toStringAsFixed(1)} KM",
              onChanged: (v) => setState(() => radius = v),
            ),

            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () {},
                  child: const Text("Create Patrol Zone")),
            ),

            const SizedBox(height: 30),

            Text("Active Patrol Zones", style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),

            _zoneCard("Model Town", "Radius: 1.5 KM"),
            _zoneCard("Iqbal Town", "Radius: 2.0 KM"),
          ],
        ),
      ),
    );
  }

  Widget _zoneCard(String title, String detail) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppTextStyles.cardDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bold16),
              Text(detail, style: AppTextStyles.subtitle),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.delete, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}
