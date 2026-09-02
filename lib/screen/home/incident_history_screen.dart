import 'package:flutter/material.dart';
import 'package:teststreetguard/screen/auth/login_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'sos_tracker_screen.dart';
import 'report_progress_screen.dart';

class IncidentHistoryScreen extends StatefulWidget {
  final String userName;

  const IncidentHistoryScreen({super.key, required this.userName});

  @override
  State<IncidentHistoryScreen> createState() => _IncidentHistoryScreenState();
}

class _IncidentHistoryScreenState extends State<IncidentHistoryScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> myCrimes = [];

  @override
  void initState() {
    super.initState();
    fetchMyCrimes();
  }

  Future<void> fetchMyCrimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? prefs.getString('token');

      if (token == null) {
        setState(() => isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.99.58.219:5000/api/crime/my-reports'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          myCrimes = List<Map<String, dynamic>>.from(data['crimes']);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching crimes: $e');
      setState(() => isLoading = false);
    }
  }

  String _getStatusTag(String workflowStatus, String urgency) {
    switch (workflowStatus) {
      case 'pending_control_room': return 'Pending Review';
      case 'assigned_to_patrol': return 'Investigating';
      case 'verified_by_patrol': return '✅ Area Secure';
      case 'rejected_by_patrol': return 'Rejected';
      case 'forwarded_to_admin': return 'Under Admin Review';
      case 'published': return '📢 Published';
      case 'resolved': return '🏁 Resolved';
      default: return urgency == 'high' ? 'Urgent' : 'Pending';
    }
  }

  Color _getStatusColor(String workflowStatus, String urgency) {
    switch (workflowStatus) {
      case 'pending_control_room': return Colors.orange;
      case 'assigned_to_patrol': return Colors.blue;
      case 'verified_by_patrol': return Colors.green;
      case 'rejected_by_patrol': return Colors.red;
      case 'forwarded_to_admin': return Colors.deepPurple;
      case 'published': return Colors.teal;
      case 'resolved': return Colors.grey;
      default: return urgency == 'high' ? Colors.red : Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            const Text(
              "StreetGuard",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),

            // 🌟 Show the user name in AppBar
            Text(
              "•  ${widget.userName}",
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        actions: [
          Row(
            children: [
              const Icon(Icons.logout, color: Colors.redAccent, size: 22),
              const SizedBox(width: 4),

              // 🌟 Add Logout Text
              GestureDetector(
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('token');
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 16),
            ],
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ✨ Header
            const Text(
              "My Incident Reports",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),
            const Text(
              "Track the status of all your reported incidents.",
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 24),

            // 🌟 Incident List
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (myCrimes.isEmpty)
              const Center(
                child: Text(
                  "No incidents reported yet.",
                  style: TextStyle(color: Colors.black54),
                ),
              )
            else
              ...myCrimes.map((crime) => GestureDetector(
                onTap: () {
                  final type = crime['type'] ?? 'general';
                  if (type == 'sos') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SosTrackerScreen(
                          crimeId: crime['_id'] ?? '',
                          isSilent: crime['isSilent'] ?? false,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportProgressScreen(
                          crimeId: crime['_id'] ?? '',
                        ),
                      ),
                    );
                  }
                },
                child: _incidentCard(
                  title: crime['title'] ?? 'Unknown',
                  area: crime['area'] ?? '',
                  location: crime['location'] ?? '',
                  description: crime['description'] ?? '',
                  time: crime['timeAgo'] ?? '',
                  tag: _getStatusTag(crime['workflowStatus'] ?? crime['status'] ?? '', crime['urgency'] ?? ''),
                  tagColor: _getStatusColor(crime['workflowStatus'] ?? crime['status'] ?? '', crime['urgency'] ?? ''),
                ),
              )),
          ],
        ),
      ),
    );
  }

  // 🌟 INCIDENT CARD
  Widget _incidentCard({
    required String title,
    required String area,
    required String location,
    required String description,
    required String time,
    required String tag,
    required Color tagColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tagColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: tagColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(area, style: AppTextStyles.subtitle),
          const SizedBox(height: 4),
          Text(location, style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 8),
          Text(time, style: AppTextStyles.subtitle),
        ],
      ),
    );
  }
}
