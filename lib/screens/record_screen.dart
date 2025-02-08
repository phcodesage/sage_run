import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'tracking_screen.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  bool _isLoading = true;
  bool _hasGpsPermission = false;
  String _selectedActivity = 'Run'; // Default to Run

  @override
  void initState() {
    super.initState();
    _checkGpsStatus();
  }

  Future<void> _checkGpsStatus() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _hasGpsPermission = false;
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      setState(() {
        _hasGpsPermission = permission == LocationPermission.always || 
                           permission == LocationPermission.whileInUse;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasGpsPermission = false;
        _isLoading = false;
      });
    }
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Audio Cues'),
              trailing: Switch(
                value: true, // Replace with actual setting
                onChanged: (value) {
                  // Implement settings change
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.speed),
              title: const Text('Units'),
              trailing: DropdownButton<String>(
                value: 'km',
                items: const [
                  DropdownMenuItem(value: 'km', child: Text('Kilometers')),
                  DropdownMenuItem(value: 'mi', child: Text('Miles')),
                ],
                onChanged: (value) {
                  // Implement unit change
                },
              ),
            ),
            // Add more settings as needed
          ],
        ),
      ),
    );
  }

  void _startTracking() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => TrackingScreen(
          activityType: _selectedActivity,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('New Activity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          // GPS Status Indicator
          Container(
            padding: const EdgeInsets.all(8),
            color: _isLoading
                ? Colors.grey
                : _hasGpsPermission
                    ? Colors.green
                    : Colors.red,
            child: Center(
              child: Text(
                _isLoading
                    ? 'Checking GPS...'
                    : _hasGpsPermission
                        ? 'GPS Ready'
                        : 'GPS Not Available',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          
          // Activity Type Selection
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Choose Activity Type',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Walk', label: Text('Walk')),
                    ButtonSegment(value: 'Run', label: Text('Run')),
                  ],
                  selected: {_selectedActivity},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedActivity = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 50),
                FilledButton.icon(
                  onPressed: _hasGpsPermission ? _startTracking : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('START'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 