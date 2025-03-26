import 'package:latlong2/latlong.dart';

class Activity {
  final String id;
  final String type;
  final DateTime startTime;
  final DateTime endTime;
  final double distance; // in kilometers
  final List<LatLng> routePoints;

  Activity({
    required this.id,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.distance,
    required this.routePoints,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'distance': distance,
      'routePoints': routePoints.map((point) => {
        'latitude': point.latitude,
        'longitude': point.longitude,
      }).toList(),
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      type: json['type'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      distance: json['distance'],
      routePoints: (json['routePoints'] as List).map((point) => 
        LatLng(point['latitude'], point['longitude'])
      ).toList(),
    );
  }
} 