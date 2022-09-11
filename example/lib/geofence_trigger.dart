import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geofencing/geofencing.dart';
import 'package:geolocator/geolocator.dart';

import 'common.dart';

abstract class GeofenceTrigger {
  // State needed to post notifications.
  static final _notificationPlugin = FlutterLocalNotificationsPlugin();
  static final _androidInitSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  static final _iosInitSettings = IOSInitializationSettings();
  static final _initializationSettings =
      InitializationSettings(_androidInitSettings, _iosInitSettings);
  static final _androidNot = AndroidNotificationDetails('garage_door_opener',
      'garage_door_opener', 'Show when garage door is opened from geofencing');
  static final _iosNot = IOSNotificationDetails();
  static final _platNot = NotificationDetails(_androidNot, _iosNot);

  static Future<void> postNotification(
          int id, String title, String body) async =>
      await _notificationPlugin.show(id, title, body, _platNot);

  // Geofencing state.
  static final _androidSettings = AndroidGeofencingSettings(initialTrigger: [
    GeofenceEvent.enter,
    GeofenceEvent.exit,
  ], notificationResponsiveness: 0, loiteringDelay: 0);

  static bool _isInitialized = false;
  static StreamSubscription? _locationUpdates;

  static Future<void> _initialize() async {
    if (!_isInitialized) {
      await initialize();
      _notificationPlugin.initialize(_initializationSettings);
      _isInitialized = true;
    }
  }

  static Future<void> _startUpdates() async {
    print('Starting location updates');
    await GeofencingManager.promoteToForeground();
    _locationUpdates =
        (await Geolocator().getPositionStream()).listen(_handleLocationUpdate);
  }

  static Future<void> stopUpdates() async {
    await _locationUpdates?.cancel();
    _locationUpdates = null;
    print("stopped");
    //await GeofencingManager.demoteToBackground();
  }

  static Future<void> _handleLocationUpdate(Position p) async {
    final home = homeRegion.location;
    final distance = await Geolocator().distanceBetween(
        p.latitude, p.longitude, home.latitude, home.longitude);
    print('Distance to home: $distance');
    //await postNotification(0, 'Test Notif', 'Test Notif!');
  }

  static final homeRegion = GeofenceRegion(
      'home',
      -6.5922092,
      106.7913849,
      200.0,
      <GeofenceEvent>[
        GeofenceEvent.enter,
        GeofenceEvent.exit,
      ],
      androidSettings: _androidSettings);

  static Future<void> homeGeofenceCallback(
      List<String> id, Location location, GeofenceEvent event) async {
    await _initialize();
    // if (_locationUpdates != null) {
    await _startUpdates();
    //}
    print(event);
    /*if (event == GeofenceEvent.enter) {
      await _startUpdates();
    } else if ((event == GeofenceEvent.exit) && (_locationUpdates != null)) {
      //await postNotification(0, 'Leaving home geofence', 'Stopped frequent location updates.');
      await _stopUpdates();
    }*/
  }
}
