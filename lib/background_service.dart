import 'dart:async';
import 'dart:ui';
import 'dart:math';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:torch_light/torch_light.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Called when a notification action is tapped while the app is in background.
/// Must be a top-level function with the vm:entry-point pragma.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  if (response.actionId == 'stop_action') {
    // Turn off the torch before stopping
    try {
      await TorchLight.disableTorch();
    } catch (_) {}
    // Stop the background service
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }
}

@pragma('vm:entry-point')
Future<void> initializeService() async {
  print("FLUTTER_BACKGROUND_SERVICE: initializeService called");
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'shake_torch_service', // id
    'ShakeTorch Service', // title
    description: 'Running in background to detect shakes', // description
    importance: Importance.low, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: true,
      isForegroundMode: true,

      notificationChannelId: 'shake_torch_service',
      initialNotificationTitle: 'ShakeTorch Service',
      initialNotificationContent: 'Shake detection is active',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false, // iOS limits background processing
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  print("FLUTTER_BACKGROUND_SERVICE: Service configured");
  service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  print("FLUTTER_BACKGROUND_SERVICE: onStart called");
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  // Bring up notifications purely for the foreground service requirement
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize with our background action handler
  await flutterLocalNotificationsPlugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_bg_service_small'),
    ),
    onDidReceiveNotificationResponse: (response) async {
      if (response.actionId == 'stop_action') {
        try {
          await TorchLight.disableTorch();
        } catch (_) {}
        service.stopSelf();
      }
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Create the notification channel (ensure it exists)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'shake_torch_service', // id
    'ShakeTorch Service', // title
    description: 'Running in background to detect shakes', // description
    importance: Importance.low, // importance must be at low or higher level
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // Build the close action that broadcasts to StopServiceReceiver
  const AndroidNotificationAction closeAction = AndroidNotificationAction(
    'stop_action',
    'Close',
    showsUserInterface: false,
    cancelNotification: true,
  );

  // Show the notification with the app logo as the large icon and a close button
  await flutterLocalNotificationsPlugin.show(
    id: 888,
    title: 'ShakeTorch',
    body: 'Shake detection is active',
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        'shake_torch_service',
        'ShakeTorch Service',
        channelDescription: 'Running in background to detect shakes',
        icon: 'ic_bg_service_small',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ongoing: true,
        autoCancel: false,
        actions: [closeAction],
        styleInformation: const BigTextStyleInformation(
          'Shake your phone to toggle the flashlight.',
        ),
      ),
    ),
  );

  // Variables for Shake Detection
  DateTime? lastShakeTime;
  bool isTorchOn = false;
  double shakeThreshold = 5.0; // Default sensitivity

  // Initialize SharedPreferences
  try {
    final prefs = await SharedPreferences.getInstance();
    shakeThreshold = prefs.getDouble('shake_sensitivity') ?? 5.0;
    print("FLUTTER_BACKGROUND_SERVICE: Loaded sensitivity: $shakeThreshold");
  } catch (e) {
    print("FLUTTER_BACKGROUND_SERVICE: Error loading prefs: $e");
  }

  service.on('setTorch').listen((event) {
    if (event != null && event['state'] != null) {
      isTorchOn = event['state'];
    }
  });

  service.on('setSensitivity').listen((event) {
    if (event != null && event['sensitivity'] != null) {
      shakeThreshold = (event['sensitivity'] as num).toDouble();
      print("FLUTTER_BACKGROUND_SERVICE: Updated sensitivity: $shakeThreshold");
    }
  });

  // Sensors
  // userAccelerometerEvents streams events excluding gravity.
  // Using 20ms interval (approx 50Hz) for better responsiveness
  userAccelerometerEventStream(
    samplingPeriod: const Duration(milliseconds: 20),
  ).listen((UserAccelerometerEvent event) async {
    // print("Sensor event: ${event.x}, ${event.y}, ${event.z}"); // Uncomment for verbose logging
    double magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    // Threshold for shake.
    // Use dynamic shakeThreshold
    if (magnitude > shakeThreshold) {
      final now = DateTime.now();
      if (lastShakeTime == null ||
          now.difference(lastShakeTime!) > const Duration(milliseconds: 1000)) {
        lastShakeTime = now;

        try {
          if (isTorchOn) {
            await TorchLight.disableTorch();
            isTorchOn = false;
          } else {
            await TorchLight.enableTorch();
            isTorchOn = true;
          }

          // Notify UI of status change if needed
          service.invoke('update', {"isTorchOn": isTorchOn});
        } catch (e) {
          print("Error toggling torch: $e");
        }
      }
    }
  });
}
