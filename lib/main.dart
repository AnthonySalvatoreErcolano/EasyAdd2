import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/prefs_repository.dart';
import 'demo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Phones stay in portrait. iPads rotate freely, as the App Store expects.
  if (_isPhone()) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
  final prefs = await SharedPreferences.getInstance();
  final scene = demoScene();
  if (scene != null) await prefs.clear(); // screenshots start clean

  final container = ProviderContainer(
    overrides: [
      prefsRepositoryProvider.overrideWithValue(PrefsRepository(prefs)),
    ],
  );
  runApp(
    UncontrolledProviderScope(container: container, child: const EasyAddApp()),
  );
  if (scene != null) runDemoScene(scene, container);
}

bool _isPhone() {
  final view = PlatformDispatcher.instance.views.first;
  final shortest = view.physicalSize.shortestSide / view.devicePixelRatio;
  return shortest < 600;
}
