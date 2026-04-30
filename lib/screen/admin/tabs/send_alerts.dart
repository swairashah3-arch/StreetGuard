import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class SendAlertsScreen extends StatefulWidget {
  const SendAlertsScreen({super.key});

  @override
  State<SendAlertsScreen> createState() => _SendAlertsScreenState();
}

class _SendAlertsScreenState extends State<SendAlertsScreen> {
  String alertType = "";
  final messageController = TextEditingController();
  double radius = 1.0; // 1km default

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Send Safety Alert", style: AppTextStyles.sectionTitle),
          const SizedBox(height: 20),

          const Text("Alert Type"),
          const SizedBox(height: 10),

          Wrap(
            spacing: 10,
            children: [
              _alertChip("Emergency"),
              _alertChip("Suspicious Activity"),
              _alertChip("Road Block"),
              _alertChip("Weather Alert"),
            ],
          ),

          const SizedBox(height: 20),
          const Text("Message"),
          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: AppTextStyles.cardDecoration,
            child: TextField(
              controller: messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                  hintText: "Write alert message...", border: InputBorder.none),
            ),
          ),

          const SizedBox(height: 20),
          const Text("Radius (KM)"),
          Slider(
            value: radius,
            min: 1,
            max: 20,
            divisions: 19,
            label: "${radius.toInt()} KM",
            onChanged: (v) => setState(() => radius = v),
          ),

          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            child: const Text("Send Alert"),
          ),
        ],
      ),
    );
  }

  Widget _alertChip(String label) {
    bool selected = alertType == label;

    return GestureDetector(
      onTap: () => setState(() => alertType = label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.black45,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
