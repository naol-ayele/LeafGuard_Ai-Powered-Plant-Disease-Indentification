import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:easy_localization/easy_localization.dart'; // Added
import '../../services/screens/onboarding_screen.dart';
import '../../services/screens/login_screen.dart';
import '../../services/screens/register_screen.dart';
import 'navigation.dart';
import '../../services/ml/tflite_service.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  try {
    final results = await Future.wait([
      availableCameras(),
      SharedPreferences.getInstance(),
      TFLiteService().loadModel(),
    ]);

    cameras = results[0] as List<CameraDescription>;
    final prefs = results[1] as SharedPreferences;

    // Check both Onboarding and Login status for robust Session Management
    final bool showOnboarding = prefs.getBool('showOnboarding') ?? true;
    final String? token = prefs.getString('token');
    final bool isLoggedIn = token != null && token.isNotEmpty;

    FlutterNativeSplash.remove();

    runApp(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('am'), Locale('or')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: LeafGuardApp(
          showOnboarding: showOnboarding,
          isLoggedIn: isLoggedIn,
        ),
      ),
    );
  }