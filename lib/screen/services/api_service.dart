import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report.dart';

class ApiService {
  static const String _base = 'http://127.0.0.1:5000/api';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token') ?? prefs.getString('token');
  }

  // Submit report — sends multipart/form-data, works on Web + Mobile
  static Future<void> submitReport(Report report, {XFile? imageFile}) async {
    final token = await _getToken();
    if (token == null) throw Exception('User not authenticated');

    final uri = Uri.parse('$_base/crime/report');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['type'] = report.type;
    request.fields['title'] = report.title;
    request.fields['description'] = report.description;
    request.fields['location'] = report.location;
    request.fields['area'] = report.area;
    request.fields['latitude'] = report.latitude.toString();
    request.fields['longitude'] = report.longitude.toString();
    if (report.witnesses != null) request.fields['witnesses'] = report.witnesses!;

    // Attach image as bytes (works on both Web and Mobile)
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      final ext = imageFile.name.split('.').last.toLowerCase();
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: imageFile.name,
      ));
    }

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 201) {
      throw Exception('Failed to submit report: $body');
    }
  }

  // Fetch published/all alerts for citizen map/feed
  static Future<List<Map<String, dynamic>>> fetchPublishedAlerts() async {
    final response = await http.get(
      Uri.parse('$_base/crime/all-map-points'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // Fetch citizen's own submitted reports
  static Future<List<Map<String, dynamic>>> fetchMyReports() async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$_base/crime/my-reports'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['crimes']);
    }
    return [];
  }
}
