// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geofencing/geofencing.dart';
import 'package:geolocator/geolocator.dart';
import 'geofence_trigger.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String geofenceState = 'N/A';
  static double latitude = -6.5904005;
  static double longitude = 106.7968131;
  double radius = 150.0;
  bool? _stopUpdate;
  Position? position;

  static StreamSubscription? _locationUpdates;
  ReceivePort port = ReceivePort();
  final List<GeofenceEvent> triggers = <GeofenceEvent>[
    GeofenceEvent.enter,
    GeofenceEvent.dwell,
    GeofenceEvent.exit
  ];
  final AndroidGeofencingSettings androidSettings = AndroidGeofencingSettings(
      initialTrigger: <GeofenceEvent>[
        GeofenceEvent.enter,
        GeofenceEvent.exit,
        GeofenceEvent.dwell
      ],
      loiteringDelay: 1000 * 60);

  @override
  void initState() {
    super.initState();
    /*IsolateNameServer.registerPortWithName(
        port.sendPort, 'geofencing_send_port');
    port.listen((dynamic data) {
      print('Event: $data');
      setState(() {
        geofenceState = data;
      });
    });
    initPlatformState();*/
  }

  static Future<void> _startUpdates() async {
    print('Starting location updates');
    //var locationOptions = LocationOptions(accuracy: LocationAccuracy.high);

    _locationUpdates =
        (await Geolocator().getPositionStream()).listen(_handleLocationUpdate);
  }

  static Future<void> stopUpdates() async {
    await _locationUpdates?.cancel();
    _locationUpdates = null;
    await GeofencingManager.demoteToBackground();
  }

  static Future<void> _handleLocationUpdate(Position p) async {
    final distance = await Geolocator()
        .distanceBetween(p.latitude, p.longitude, latitude, longitude);
    print('Distance to home: $distance');
    print('Current position : $p');
    //await insertPosition(p.latitude, p.longitude);
  }

  bool _isStopped = false;
  static void localCallback(
      List<String> ids, Location l, GeofenceEvent e) async {
    if (_locationUpdates == null) {
      await _startUpdates();
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    print('Initializing...');
    await GeofencingManager.initialize();
    print('Initialization done');
  }

  Future<void> initCurrentLocation() async {
    position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    print(position);
  }

  static Future<void> insertPosition(double lat, double long) async {
    final url = "http://192.168.43.223/ssinet/api/Tracking/InsertTracking";
    Map<String, String> headers = {
      "Content-Type": "application/x-www-form-urlencoded"
    };

    Map<String, dynamic> data = {
      "ticket_id": "P232",
      "latitude": lat.toString(),
      "longitude": long.toString()
    };

    final response = await http.post(url, headers: headers, body: data);

    if (response.statusCode == 200) {
      print("position inserted");
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Flutter Geofencing Example'),
          ),
          body: Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text('Current state: $geofenceState'),
                    Center(
                      child: RaisedButton(
                        child: const Text('Register'),
                        onPressed: () {
                          GeofencingManager.registerGeofence(
                              GeofenceTrigger.homeRegion, localCallback);
                          initCurrentLocation();
                        },
                      ),
                    ),
                    Center(
                        child: RaisedButton(
                            child: const Text('Unregister'),
                            onPressed: () {
                              _stopUpdate = true;
                              print("stop update");
                              GeofencingManager.removeGeofenceById('home');
                              GeofenceTrigger.stopUpdates();
                              //GeofencingManager.demoteToBackground();
                            }))
                  ]))),
    );
  }
}
