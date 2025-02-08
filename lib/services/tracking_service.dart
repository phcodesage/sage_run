import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class TrackingService {
  static Future<void> initForegroundTask() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'tracking_service',
        channelName: 'Tracking Service',
        channelDescription: 'Shows tracking status',
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
        interval: 1000,
        isOnceEvent: false,
        autoRunOnBoot: false,
        allowWifiLock: true,
      ),
    );
  }

  static Future<bool> startTracking({
    required String duration,
    required String distance,
  }) async {
    // Start foreground service
    await FlutterForegroundTask.startService(
      notificationTitle: 'Tracking Active',
      notificationText: 'Duration: $duration\nDistance: $distance km',
      callback: startCallback,
    );

    return FlutterForegroundTask.isRunningService;
  }

  static Future<void> updateTracking({
    required String duration,
    required String distance,
  }) async {
    if (await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.updateService(
        notificationTitle: 'Tracking Active',
        notificationText: 'Duration: $duration\nDistance: $distance km',
      );
    }
  }

  static Future<void> stopTracking() async {
    await FlutterForegroundTask.stopService();
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