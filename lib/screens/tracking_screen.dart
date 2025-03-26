import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../services/tracking_service.dart';
import '../services/activity_service.dart';
import '../models/activity.dart';

class TrackingScreen extends StatefulWidget {
  final String activityType;

  const TrackingScreen({
    super.key,
    required this.activityType,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final TrackingService _trackingService = TrackingService();
  final MapController _mapController = MapController();
  final Location _location = Location();
  List<LatLng> _routePoints = [];
  bool _isTracking = false;
  StreamSubscription<LocationData>? _locationSubscription;
  LatLng? _currentPosition;
  bool _showControls = true;
  DateTime? _startTime;
  double _distance = 0.0;
  LatLng? _lastPosition;
  Timer? _timer;
  Duration _duration = Duration.zero;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    TrackingService.initForegroundTask();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _locationSubscription?.cancel();
    _timer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionStatus = await _location.hasPermission();
    if (permissionStatus == PermissionStatus.denied) {
      permissionStatus = await _location.requestPermission();
      if (permissionStatus != PermissionStatus.granted) return;
    }

    _locationSubscription = _location.onLocationChanged.listen((LocationData currentLocation) {
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(
            currentLocation.latitude!,
            currentLocation.longitude!,
          );
        });
      
        if (_currentPosition != null) {
          _mapController.move(
            _currentPosition!,
            _mapController.camera.zoom,
          );
        }
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _startTracking() {
    setState(() {
      _isTracking = true;
      _routePoints = [];
      _seconds = 0;
      _distance = 0.0;
      _startTime = DateTime.now();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
      TrackingService.updateTracking(
        duration: _formatDuration(),
        distance: (_distance / 1000).toStringAsFixed(2),
      );
    });

    TrackingService.startTracking(
      duration: _formatDuration(),
      distance: '0.00',
    );

    _locationSubscription = _location.onLocationChanged.listen((LocationData currentLocation) {
      if (_isTracking) {
        setState(() {
          final newPoint = LatLng(currentLocation.latitude!, currentLocation.longitude!);
          _routePoints.add(newPoint);
          
          if (_routePoints.length > 1) {
            _distance += Geolocator.distanceBetween(
              _routePoints[_routePoints.length - 2].latitude,
              _routePoints[_routePoints.length - 2].longitude,
              newPoint.latitude,
              newPoint.longitude,
            );
          }
        });
      }
    });
  }

  void _stopTracking() {
    setState(() {
      _isTracking = false;
    });
    _timer?.cancel();
    _locationSubscription?.cancel();
    TrackingService.stopTracking();
    
    // Show confirmation dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('End Activity?'),
        content: const Text('Do you want to save this activity?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog first
              if (mounted) {
                await _saveActivity(); // Then save and navigate
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveActivity() async {
    if (_startTime == null || _routePoints.isEmpty) return;

    final activity = Activity(
      id: const Uuid().v4(),
      type: widget.activityType,
      startTime: _startTime!,
      endTime: DateTime.now(),
      distance: _distance / 1000, // Convert to kilometers
      routePoints: _routePoints,
    );

    try {
      await ActivityService().saveActivity(activity);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/'); // Navigate to home screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save activity: $e')),
        );
      }
    }
  }

  String _formatDuration() {
    final minutes = (_seconds / 60).floor();
    final remainingSeconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition ?? const LatLng(0, 0),
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.sagerun',
                ),
                if (_currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentPosition!,
                        width: 80,
                        height: 80,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: Colors.blue,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
              ],
            ),
            if (_showControls) ...[
              // Top bar with back button and activity type
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.fromLTRB(8, 48, 8, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          widget.activityType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance for back button
                    ],
                  ),
                ),
              ),
              // Stats overlay
              Positioned(
                top: 100,
                left: 16,
                right: 16,
                child: Card(
                  color: Colors.black87,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          _formatDuration(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Distance: ${(_distance / 1000).toStringAsFixed(2)} km',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Start/Stop button
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Center(
                  child: FloatingActionButton.extended(
                    onPressed: _isTracking ? _stopTracking : _startTracking,
                    label: Text(_isTracking ? 'STOP' : 'START'),
                    icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                    backgroundColor: _isTracking ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 