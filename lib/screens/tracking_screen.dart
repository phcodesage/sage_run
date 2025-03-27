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
  final Position initialPosition;

  const TrackingScreen({
    super.key,
    required this.initialPosition,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final TrackingService _trackingService = TrackingService();
  final ActivityService _activityService = ActivityService();
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
  double _currentPace = 0;
  bool _isPaused = false;
  DateTime? _pauseTime;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    TrackingService.initForegroundTask();
    _checkLocationPermission();
    _startTime = DateTime.now();
    _startTracking();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _locationSubscription?.cancel();
    _timer?.cancel();
    _mapController.dispose();
    _trackingService.stopTracking();
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
    _trackingService.startLocationUpdates((position) {
      setState(() {
        _routePoints.add(LatLng(position.latitude, position.longitude));
        _updateStats(position);
      });
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _duration += const Duration(seconds: 1);
        });
      }
    });
  }

  void _updateStats(Position position) {
    if (_routePoints.length > 1) {
      final lastPoint = _routePoints[_routePoints.length - 2];
      final currentPoint = _routePoints.last;
      final distance = const Distance().as(LengthUnit.Kilometer, lastPoint, currentPoint);
      _distance += distance;

      if (_duration.inSeconds > 0) {
        _currentPace = _duration.inSeconds / (_distance * 60); // minutes per kilometer
      }
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _pauseTime = DateTime.now();
        _trackingService.pauseTracking();
      } else {
        _startTime = _startTime!.add(DateTime.now().difference(_pauseTime!));
        _trackingService.resumeTracking();
      }
    });
  }

  Future<void> _stopTracking() async {
    _timer?.cancel();
    _trackingService.stopTracking();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Activity?'),
        content: const Text('Do you want to save this activity?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave == true) {
      await _saveActivity();
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _saveActivity() async {
    final activity = Activity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'Run',
      startTime: _startTime!,
      endTime: DateTime.now(),
      distance: _distance,
      routePoints: _routePoints,
    );

    await _activityService.saveActivity(activity);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  String _formatPace(double pace) {
    if (pace == 0) return '--:--';
    final minutes = pace.floor();
    final seconds = ((pace - minutes) * 60).round();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
                          'Run',
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
                          _formatDuration(_duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Distance: ${_distance.toStringAsFixed(2)} km',
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
                    onPressed: _togglePause,
                    label: Text(_isPaused ? 'RESUME' : 'PAUSE'),
                    icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                    backgroundColor: _isPaused ? Colors.green : Colors.red,
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