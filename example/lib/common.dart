import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:geofencing/geofencing.dart';

Future<String> getFileData(String path) async =>
    await rootBundle.loadString(path);

Future<void> initialize() async {
  print('initializing');
  await GeofencingManager.initialize();
}
