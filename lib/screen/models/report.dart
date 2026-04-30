import 'package:flutter/material.dart';

class Report {
  final String type;
  final String title;
  final String description;
  final String location;
  final String area;
  final double latitude;
  final double longitude;
  final String? witnesses;
  final DateTime? date;
  final TimeOfDay? time;

  Report({
    required this.type,
    required this.title,
    required this.description,
    required this.location,
    required this.area,
    required this.latitude,
    required this.longitude,
    this.witnesses,
    this.date,
    this.time,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'location': location,
      'area': area,
      'latitude': latitude,
      'longitude': longitude,
      'witnesses': witnesses,
      'date': date?.toIso8601String(),
      'time': time != null ? '${time!.hour}:${time!.minute}' : null,
    };
  }
}
