import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> localizationSetup() async {
  // Initialize FFI for sqflite testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  SharedPreferences.setMockInitialValues({});

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter/assets'), (message) async => null);

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('tflite_flutter'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'loadModel') {
        return {'success': true};
      }
      if (methodCall.method == 'run') {
        return {'success': true};
      }
      return null;
    },
  );

  // Mock Camera Channel to prevent crashes during main app initialization
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/camera'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'availableCameras') {
        return <Map<String, dynamic>>[];
      }
      return null;
    },
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => '.');

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter/assets'), (message) async => null);

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('tflite_flutter'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'loadModel') return {'success': true};
      if (methodCall.method == 'run') return [0.1, 0.9, 0.0]; // Mock prediction
      return null;
    },
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/camera'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'availableCameras')
        return <Map<String, dynamic>>[];
      return null;
    },
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/camera'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'availableCameras') {
        return <Map<String, dynamic>>[
          {
            'name': '0',
            'lensDirection': 1, // back
            'sensorOrientation': 90,
          }
        ];
      }
      if (methodCall.method == 'create') {
        return {'cameraId': 0};
      }
      if (methodCall.method == 'initialize') {
        return {'previewWidth': 1920, 'previewHeight': 1080};
      }
      return null;
    },
  );
}

// Helper function to mock camera initialization for tests
void mockCameraInitialization() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/camera'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'availableCameras') {
        return <Map<String, dynamic>>[
          {
            'name': '0',
            'lensDirection': 1, // back
            'sensorOrientation': 90,
          }
        ];
      }
      if (methodCall.method == 'create') {
        return {'cameraId': 0};
      }
      if (methodCall.method == 'initialize') {
        return {'previewWidth': 1920, 'previewHeight': 1080};
      }
      return null;
    },
  );
}

class FakeAssetLoader extends AssetLoader {
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    // Add ALL translation keys needed for your tests
    return {
      // Common keys
      "create_account": "Create Account",
      "join_community": "Join our community",
      "full_name": "Full Name",
      "email": "Email",
      "password": "Password",
      "register_btn": "Register",
      "already_have_account": "Already have an account?",
      "registration_success": "Registration successful",
      "enter_name": "Enter your name",
      "email_required": "Email is required",
      "password_short": "Password too short",
      "registration_failed": "Registration failed",

      // History screen keys
      "history_title": "History",
      "refresh_btn": "Refresh",
      "history_empty": "No scans yet",
      "history_empty_desc": "Scan your first plant to see results here",
      "delete_title": "Delete Scan",
      "delete_confirm_msg": "Are you sure you want to delete this scan?",
      "cancel_btn": "Cancel",
      "delete_btn": "Delete",
      "search_hint": "Search scans...",
      "search_no_results": "No results found",
      "search_try_again": "Try a different search term",

      // Result screen keys - FIXED KEYS
      "Diagnosis Result": "Diagnosis Result",
      "diagnosis_title": "Diagnosis Result",
      "Plant": "Plant",
      "Symptoms": "Symptoms",
      "Treatment": "Treatment",
      "error_title": "Error",
      "no_results": "No results available",
      "invalid_subject": "Invalid Subject",
      "no_leaf_detected": "No Leaf Detected",
      "no_leaf_desc":
          "The image doesn't appear to contain a plant leaf. Please try again with a clearer image.",
      "try_again": "Try Again",
      "confidence_level": "Confidence",
      "Cause": "Cause",

      // Disease-specific keys - FIXED to match your ResultScreen code
      "Tomato___Early_blight.plant": "Tomato",
      "Tomato___Early_blight.status": "Diseased",
      "Tomato___Early_blight.causes": "Fungal infection",
      "Tomato___Early_blight.symptoms": "Brown spots on leaves",
      "Tomato___Early_blight.treatment": "Apply fungicide",

      "Apple___healthy.plant": "Apple",
      "Apple___healthy.status": "Healthy",
      "Apple___healthy.causes": "N/A",
      "Apple___healthy.symptoms": "No symptoms",
      "Apple___healthy.treatment": "Regular maintenance",

      // Add other disease keys as needed for your tests
      "Background.plant": "Background",
      "Background.status": "Invalid",
      "Background.causes": "No leaf detected",
      "Background.symptoms": "Image does not contain plant leaf",
      "Background.treatment": "Retake photo",

      // Add keys for other test cases
      "Perfect_Match.plant": "Plant",
      "Perfect_Match.status": "Healthy",
      "Perfect_Match.causes": "N/A",
      "Perfect_Match.symptoms": "No symptoms",
      "Perfect_Match.treatment": "Regular maintenance",

      "Uncertain_Match.plant": "Plant",
      "Uncertain_Match.status": "Unknown",
      "Uncertain_Match.causes": "Unknown",
      "Uncertain_Match.symptoms": "Unknown",
      "Uncertain_Match.treatment": "Unknown",

      // Login screen keys (if not already present)
      "login_btn": "Login",
      "forgot_password": "Forgot Password?",
      "dont_have_account": "Don't have an account?",
      "login_error": "Login failed",
      "email_invalid": "Invalid email",
      "password_required": "Password is required",

      "settings": "Settings",
      "change_language": "Change Language",
      "change_password": "Change Password",
      "logout_btn": "Logout",
      "current_password": "Current Password",
      "new_password": "New Password",
      "update": "Update",
      "cancel": "Cancel",
      "password_updated": "Password updated successfully",
      "fill_all_fields": "Please fill all fields",
      "logout_confirm": "Are you sure you want to logout?",
      // Navigation and Onboarding completion keys
      "nav_home": "Home",
      "nav_scan": "Scan",
      "nav_history": "History",
      "nav_settings": "Settings",
      "welcome_back": "Welcome Back",
      "home_subtitle": "Check your plants",
      "recent_activity": "Recent Activity",
      "guide_title": "Guide",
      "guide_1": "Step 1",
      "guide_2": "Step 2",
      "guide_3": "Step 3",
      "guide_4": "Step 4",
      "no_scans": "No scans yet",

      // Settings Screen specific keys
      "change_password_instruction": "Enter your current and new password",

      "logout_title": "Logout",

      "error_occurred": "An error occurred",

      "confidence_label": "{0}%",
    };
  }
}

Widget wrapWithLocalization(
    {required Widget child, Map<String, WidgetBuilder>? routes}) {
  return EasyLocalization(
    path: 'assets/translations',
    supportedLocales: const [Locale('en')],
    startLocale: const Locale('en'),
    saveLocale: false, // Important for tests to prevent disk writes
    useOnlyLangCode: true,
    assetLoader: FakeAssetLoader(),
    child: Builder(
      builder: (context) => MaterialApp(
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: child,
        routes: routes ?? {}, // Pass routes here so Navigator finds them
      ),
    ),
  );
}
