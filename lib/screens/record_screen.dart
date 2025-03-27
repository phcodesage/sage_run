import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/tracking_service.dart';
import 'tracking_screen.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final TrackingService _trackingService = TrackingService();
  Position? _currentPosition;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      _getCurrentLocation();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required for tracking')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _startTracking() async {
    if (_currentPosition == null) {
      await _getCurrentLocation();
    }

    if (_currentPosition != null) {
      final success = await _trackingService.startTracking();
      if (success && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrackingScreen(
              initialPosition: _currentPosition!,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          if (_currentPosition != null)
            FlutterMap(
              options: MapOptions(
                center: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                zoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.sagerun',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          
          // Overlay UI
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        icon: Icons.timer,
                        label: 'Time',
                        value: '0:00:00',
                      ),
                      _buildStatItem(
                        icon: Icons.directions_run,
                        label: 'Distance',
                        value: '0.0 km',
                      ),
                      _buildStatItem(
                        icon: Icons.speed,
                        label: 'Pace',
                        value: '--:-- /km',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Start Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _startTracking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Start Activity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
} 