import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';
import '../services/tracking_service.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final MapController _mapController = MapController();
  final Location _location = Location();
  bool _isTracking = false;
  List<LatLng> _routePoints = [];
  Timer? _timer;
  int _seconds = 0;
  double _distance = 0.0;
  StreamSubscription<LocationData>? _locationSubscription;
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    TrackingService.initForegroundTask();
    _checkLocationPermission();
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

    _location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        _currentPosition = LatLng(
          currentLocation.latitude!,
          currentLocation.longitude!,
        );
      });
      
      if (_isTracking) {
        _mapController.move(
          _currentPosition!,
          _mapController.camera.zoom,
        );
      }
    });
  }

  void _startTracking() {
    setState(() {
      _isTracking = true;
      _routePoints = [];
      _seconds = 0;
      _distance = 0.0;
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
  }

  String _formatDuration() {
    final minutes = (_seconds / 60).floor();
    final remainingSeconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _locationSubscription?.cancel();
    TrackingService.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Your Run'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
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
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _formatDuration(),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Distance: ${(_distance / 1000).toStringAsFixed(2)} km',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isTracking ? _stopTracking : _startTracking,
        label: Text(_isTracking ? 'Stop' : 'Start'),
        icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
} 