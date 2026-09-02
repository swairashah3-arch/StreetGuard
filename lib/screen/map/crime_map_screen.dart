import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class CrimeMapScreen extends StatefulWidget {
  const CrimeMapScreen({super.key});

  @override
  State<CrimeMapScreen> createState() => _CrimeMapScreenState();
}

class _CrimeMapScreenState extends State<CrimeMapScreen> {
  List<dynamic> _crimes = [];
  bool _isLoading = true;
  String? _selectedCrimeId;
  String? _selectedSectorName;
  final MapController _mapController = MapController();

  final List<Map<String, dynamic>> _sectors = [
    {'name': 'Saddar', 'center': const LatLng(34.1485, 73.1972)},
    {'name': 'Mandian', 'center': const LatLng(34.1950, 73.2380)},
    {'name': 'Jinnahabad', 'center': const LatLng(34.1680, 73.2250)},
    {'name': 'Supply Area', 'center': const LatLng(34.1800, 73.2180)},
    {'name': 'Kakul', 'center': const LatLng(34.1880, 73.2500)},
    {'name': 'Nawanshehr', 'center': const LatLng(34.1620, 73.2450)},
  ];

  static const String baseUrl = 'http://10.99.58.219:5000/api';

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
    if (status == 'pending_control_room' || status == 'assigned_to_patrol' || status == 'forwarded_to_admin') {
      return Colors.orange; // Pending
    }
    return Colors.green; // Resolved / Published
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

  int _getSectorCrimeCount(Map<String, dynamic> sector) {
    int count = 0;
    final LatLng center = sector['center'] as LatLng;
    for (var crime in _crimes) {
      final double lat = (crime['latitude'] as num?)?.toDouble() ?? 0.0;
      final double lng = (crime['longitude'] as num?)?.toDouble() ?? 0.0;
      if (lat == 0.0 || lng == 0.0) continue;
      
      final double distance = Geolocator.distanceBetween(
        center.latitude,
        center.longitude,
        lat,
        lng,
      );
      // Count crimes within 1.5 km (1500 meters) of the sector center
      if (distance <= 1500) {
        count++;
      }
    }
    return count;
  }

  Color _getZoneColor(int crimeCount) {
    if (crimeCount >= 4) {
      return const Color.fromARGB(45, 244, 67, 54); // Transparent Red
    } else if (crimeCount >= 2) {
      return const Color.fromARGB(45, 255, 152, 0); // Transparent Orange
    } else {
      return const Color.fromARGB(35, 76, 175, 80); // Transparent Green
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
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(34.1688, 73.2215),
                    initialZoom: 12.5,
                    onTap: (tapPosition, point) {
                      for (var sector in _sectors) {
                        final center = sector['center'] as LatLng;
                        final double distance = Geolocator.distanceBetween(
                          center.latitude,
                          center.longitude,
                          point.latitude,
                          point.longitude,
                        );
                        if (distance <= 1500) {
                          setState(() {
                            _selectedSectorName = sector['name'];
                          });
                          _mapController.move(center, 13.8);
                          return;
                        }
                      }
                      setState(() {
                        _selectedSectorName = null;
                        _selectedCrimeId = null;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.streetguard.app',
                    ),
                     MarkerLayer(
                       markers: _sectors.map((sector) {
                         final count = _getSectorCrimeCount(sector);
                         final color = _getZoneColor(count);
                         final isSelected = _selectedSectorName == sector['name'];
                         return Marker(
                           point: sector['center'] as LatLng,
                           width: isSelected ? 220 : 185,
                           height: isSelected ? 220 : 185,
                           child: IgnorePointer(
                             ignoring: true,
                             child: AnimatedContainer(
                               duration: const Duration(milliseconds: 250),
                               decoration: BoxDecoration(
                                 shape: BoxShape.circle,
                                 gradient: RadialGradient(
                                   colors: [
                                     isSelected ? color.withOpacity(0.5) : color.withOpacity(0.38),
                                     isSelected ? color.withOpacity(0.2) : color.withOpacity(0.12),
                                     Colors.transparent,
                                   ],
                                   stops: const [0.0, 0.6, 1.0],
                                 ),
                               ),
                               child: Center(
                                 child: Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                   decoration: BoxDecoration(
                                     color: Colors.white.withOpacity(0.65),
                                     borderRadius: BorderRadius.circular(10),
                                     boxShadow: [
                                       BoxShadow(
                                         color: Colors.black.withOpacity(0.04),
                                         blurRadius: 2,
                                       )
                                     ],
                                   ),
                                   child: Text(
                                     sector['name'],
                                     style: TextStyle(
                                       color: count >= 4
                                           ? Colors.red.shade900
                                           : (count >= 2 ? Colors.orange.shade900 : Colors.green.shade900),
                                       fontSize: isSelected ? 11 : 9.5,
                                       fontWeight: FontWeight.bold,
                                       letterSpacing: 0.5,
                                     ),
                                   ),
                                 ),
                               ),
                             ),
                           ),
                         );
                       }).toList(),
                     ),
                    MarkerLayer(
                      markers: _crimes.where((crime) {
                        if (_selectedSectorName == null) return false;
                        final sector = _sectors.firstWhere((s) => s['name'] == _selectedSectorName);
                        final center = sector['center'] as LatLng;
                        final lat = (crime['latitude'] as num?)?.toDouble() ?? 0.0;
                        final lng = (crime['longitude'] as num?)?.toDouble() ?? 0.0;
                        final distance = Geolocator.distanceBetween(center.latitude, center.longitude, lat, lng);
                        return distance <= 1500;
                      }).map((crime) {
                        final lat = (crime['latitude'] as num?)?.toDouble() ?? 34.1688;
                        final lng = (crime['longitude'] as num?)?.toDouble() ?? 73.2215;
                        final color = _markerColor(crime);
                        final isSelected = _selectedCrimeId == crime['_id'];
                        return Marker(
                          point: LatLng(lat, lng),
                          width: isSelected ? 32 : 20,
                          height: isSelected ? 32 : 20,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedCrimeId = crime['_id']);
                              _showCrimeDetails(crime);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: isSelected ? 3.0 : 2.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: isSelected ? 12 : 6,
                                    spreadRadius: isSelected ? 3 : 1,
                                  )
                                ],
                              ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Markers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 4),
                        const _LegendRow(color: Colors.red, label: 'Serious'),
                        const _LegendRow(color: Colors.orange, label: 'Pending'),
                        const _LegendRow(color: Colors.green, label: 'Resolved'),
                        const Divider(height: 12, thickness: 1),
                        const Text('Safety Zones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 4),
                        _LegendRow(color: Colors.red.withOpacity(0.3), label: 'High Crime'),
                        _LegendRow(color: Colors.orange.withOpacity(0.3), label: 'Moderate'),
                        _LegendRow(color: Colors.green.withOpacity(0.3), label: 'Safe Area'),
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
                      _selectedSectorName == null
                          ? '${_crimes.length} incidents'
                          : 'Select a marker in $_selectedSectorName',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
                if (_selectedSectorName != null)
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Zone: $_selectedSectorName',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedSectorName = null;
                                  _selectedCrimeId = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 14),
                              ),
                            ),
                          ],
                        ),
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
