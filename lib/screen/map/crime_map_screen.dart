import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CrimeMapScreen extends StatefulWidget {
  const CrimeMapScreen({super.key});

  @override
  State<CrimeMapScreen> createState() => _CrimeMapScreenState();
}

class _CrimeMapScreenState extends State<CrimeMapScreen> {
  List<dynamic> _crimes = [];
  bool _isLoading = true;
  String? _selectedCrimeId;

  static const String baseUrl = 'http://127.0.0.1:5000/api';

  @override
  void initState() {
    super.initState();
    _fetchMapPoints();
  }

  Future<void> _fetchMapPoints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.get(
        Uri.parse('$baseUrl/crime/all-map-points'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _crimes = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error fetching map points: $e');
    }
  }

  Color _markerColor(Map crime) {
    final type = crime['type'] ?? '';
    final status = crime['workflowStatus'] ?? '';
    if (type == 'serious') return Colors.red;
    if (status == 'published' || status == 'resolved') return Colors.green;
    return Colors.orange;
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending_control_room': return 'Pending Review';
      case 'assigned_to_patrol': return 'Under Investigation';
      case 'verified_by_patrol': return 'Verified';
      case 'forwarded_to_admin': return 'Under Admin Review';
      case 'published': return 'Published';
      case 'resolved': return 'Resolved';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crime Map — Abbottabad'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchMapPoints),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(34.1688, 73.2215),
                    initialZoom: 12.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.streetguard.app',
                    ),
                    MarkerLayer(
                      markers: _crimes.map((crime) {
                        final lat = (crime['latitude'] as num?)?.toDouble() ?? 34.1688;
                        final lng = (crime['longitude'] as num?)?.toDouble() ?? 73.2215;
                        final color = _markerColor(crime);
                        final isSelected = _selectedCrimeId == crime['_id'];
                        return Marker(
                          point: LatLng(lat, lng),
                          width: isSelected ? 50 : 38,
                          height: isSelected ? 50 : 38,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedCrimeId = crime['_id']);
                              _showCrimeDetails(crime);
                            },
                            child: Icon(
                              Icons.location_pin,
                              color: color,
                              size: isSelected ? 50 : 38,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                // Legend
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Legend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        SizedBox(height: 6),
                        _LegendRow(color: Colors.red, label: 'Serious Crime'),
                        _LegendRow(color: Colors.orange, label: 'Non-Serious / Pending'),
                        _LegendRow(color: Colors.green, label: 'Resolved / Published'),
                      ],
                    ),
                  ),
                ),
                // Crime count badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_crimes.length} incidents',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showCrimeDetails(Map crime) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final type = crime['type'] ?? '';
        final status = crime['workflowStatus'] ?? '';
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_pin, color: _markerColor(crime), size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(crime['title'] ?? 'Unknown', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: type == 'serious' ? Colors.red.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(type == 'serious' ? 'Serious' : 'Non-Serious',
                      style: TextStyle(color: type == 'serious' ? Colors.red : Colors.orange, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _detailRow(Icons.place, 'Area', crime['area'] ?? 'Unknown'),
              _detailRow(Icons.info_outline, 'Status', _statusLabel(status)),
              _detailRow(Icons.gps_fixed, 'Coords',
                '${(crime['latitude'] as num?)?.toStringAsFixed(4)}, ${(crime['longitude'] as num?)?.toStringAsFixed(4)}'),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black45),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 12),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
