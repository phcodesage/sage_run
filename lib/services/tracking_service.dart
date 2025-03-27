import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

class TrackingService {
  static void initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'tracking_channel',
        channelName: 'Activity Tracking',
        channelDescription: 'Tracking your activity in the background',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<bool> startTracking() async {
    try {
      await FlutterForegroundTask.startService(
        notificationTitle: 'Sage Run',
        notificationText: 'Tracking your activity',
      );
      return true;
    } catch (e) {
      print('Error starting tracking: $e');
      return false;
    }
  }

  void startLocationUpdates(Function(Position) onLocationUpdate) {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen(onLocationUpdate);
  }

  void pauseTracking() {
    FlutterForegroundTask.updateService(
      notificationTitle: 'Sage Run',
      notificationText: 'Activity paused',
    );
  }

  void resumeTracking() {
    FlutterForegroundTask.updateService(
      notificationTitle: 'Sage Run',
      notificationText: 'Tracking your activity',
    );
  }

  Future<void> stopTracking() async {
    await FlutterForegroundTask.stopService();
  }

  static void updateTracking({
    required String duration,
    required String distance,
  }) {
    FlutterForegroundTask.updateService(
      notificationTitle: 'Sage Run',
      notificationText: '$duration • $distance km',
    );
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(TrackingTaskHandler());
}

class TrackingTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    // Initialize task
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // Handle periodic events
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    // Cleanup
  }

  @override
  void onButtonPressed(String id) {
    // Handle notification button press
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) {
    // Handle repeat events if needed
  }
} 