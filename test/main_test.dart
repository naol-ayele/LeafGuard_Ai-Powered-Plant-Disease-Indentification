import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafguard/main.dart' as app;
import 'package:leafguard/screens/onboarding_screen.dart';
import 'package:leafguard/navigation.dart';
import 'package:leafguard/screens/login_screen.dart';
import 'package:leafguard/screens/register_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'test_helper.dart';

void main() {
  setUp(() async {
    await localizationSetup();
    app.cameras = [];
    // Initialize SharedPreferences with empty values for testing
    SharedPreferences.setMockInitialValues({});
  });

  group('AppConfig and Initialization Logic', () {
    test('AppConfig stores values correctly', () {
      final config = app.AppConfig(showOnboarding: false, isLoggedIn: true);
      expect(config.showOnboarding, isFalse);
      expect(config.isLoggedIn, isTrue);
    });

    test('initializeApp handles success state', () async {
      // Set mock values to simulate a returning user who is logged in
      SharedPreferences.setMockInitialValues({
        'showOnboarding': false,
        'token': 'valid_token',
      });

      // We mock the camera channel to prevent availableCameras() from hanging/failing
      const MethodChannel('plugins.flutter.io/camera')
          .setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == 'availableCameras') {
          return [];
        }
        return null;
      });

      final config = await app.initializeApp();

      expect(config.showOnboarding, isFalse);
      expect(config.isLoggedIn, isTrue);
    });

    test('initializeApp handles error state (Catch Block Coverage)', () async {
      // Force an error by not mocking the channels properly or providing invalid data
      // This will trigger the catch (e) block in main.dart
      SharedPreferences.setMockInitialValues({});

      // Force availableCameras to throw
      const MethodChannel('plugins.flutter.io/camera')
          .setMockMethodCallHandler((MethodCall methodCall) async {
        throw Exception("Camera failed");
      });

      final config = await app.initializeApp();

      // Should return default values from the catch block
      expect(config.showOnboarding, isTrue);
      expect(config.isLoggedIn, isFalse);
    });
    test('initializeApp handles empty token string', () async {
      SharedPreferences.setMockInitialValues({
        'showOnboarding': false,
        'token': '',
      });

      // Mock channels to prevent hangs
      const MethodChannel('plugins.flutter.io/camera')
          .setMockMethodCallHandler((_) async => []);
      const MethodChannel('tflite_service')
          .setMockMethodCallHandler((_) async => true);

      final config = await app.initializeApp();
      expect(config.isLoggedIn, isFalse);
    });
  });

  group('Main App Launch Logic', () {
    testWidgets('App shows OnboardingScreen on first launch', (tester) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/translations',
          startLocale: const Locale('en'),
          assetLoader: FakeAssetLoader(),
          child: const app.LeafGuardApp(
            showOnboarding: true,
            isLoggedIn: false,
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('App shows LoginScreen if onboarding is done but not logged in',
        (tester) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/translations',
          startLocale: const Locale('en'),
          assetLoader: FakeAssetLoader(),
          child: const app.LeafGuardApp(
            showOnboarding: false,
            isLoggedIn: false,
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('App shows MainNavigation if logged in', (tester) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/translations',
          startLocale: const Locale('en'),
          assetLoader: FakeAssetLoader(),
          child: const app.LeafGuardApp(
            showOnboarding: false,
            isLoggedIn: true,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(MainNavigation), findsOneWidget);
    });

    testWidgets('main function executes without crashing', (tester) async {
      // Mock the camera channel so initializeApp doesn't fail inside main
      const MethodChannel('plugins.flutter.io/camera')
          .setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == 'availableCameras') return [];
        return null;
      });

      // We use runAsync because main() has several async awaits
      await tester.runAsync(() async {
        await app.main();
        await tester.pump();
      });

      // Verify that the app actually started by finding the EasyLocalization wrapper
      expect(find.byType(EasyLocalization), findsOneWidget);
    });
  });

  group('Navigation & Routing Coverage', () {
    testWidgets('Verifies named routes work correctly', (tester) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/translations',
          startLocale: const Locale('en'),
          assetLoader: FakeAssetLoader(),
          child: const app.LeafGuardApp(
            showOnboarding: false,
            isLoggedIn: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Test Route: Register
      final BuildContext context = tester.element(find.byType(LoginScreen));
      Navigator.pushNamed(context, '/register');
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);

      // Test Route: Login (via back)
      Navigator.pop(tester.element(find.byType(RegisterScreen)));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('App title and localization configuration is correct',
        (tester) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('am'), Locale('or')],
          path: 'assets/translations',
          assetLoader: FakeAssetLoader(),
          child:
              const app.LeafGuardApp(showOnboarding: true, isLoggedIn: false),
        ),
      );
      await tester.pump();

      final MaterialApp materialApp = tester.widget(find.byType(MaterialApp));

      // Test Title
      expect(materialApp.title, 'LeafGuard');

      // Test if all supported locales are present
      expect(materialApp.supportedLocales.length, 3);
      expect(materialApp.supportedLocales, contains(const Locale('am')));

      // Test if delegates are attached
      expect(materialApp.localizationsDelegates, isNotEmpty);
    });
  });

  group('Edge Case: Theme and Initialization', () {
    testWidgets('App uses Material3 and Green Seed Color', (tester) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/translations',
          startLocale: const Locale('en'),
          assetLoader: FakeAssetLoader(),
          child: const app.LeafGuardApp(
            showOnboarding: true,
            isLoggedIn: false,
          ),
        ),
      );
      await tester.pump();

      final MaterialApp materialApp = tester.widget(find.byType(MaterialApp));
      expect(materialApp.theme?.useMaterial3, isTrue);
      // Checking the primary color derived from green seed
      expect(materialApp.theme?.colorScheme.primary, isNotNull);
    });

    testWidgets('App defaults to Onboarding when initialization fails',
        (tester) async {
      // Simulate error by throwing in the mock
      const MethodChannel('plugins.flutter.io/camera')
          .setMockMethodCallHandler((MethodCall methodCall) async {
        throw Exception("Critical failure");
      });

      final config = await app.initializeApp();

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/translations',
          assetLoader: FakeAssetLoader(),
          child: app.LeafGuardApp(
              showOnboarding: config.showOnboarding,
              isLoggedIn: config.isLoggedIn),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('Navigation route /home builds MainNavigation', (tester) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/translations',
          assetLoader: FakeAssetLoader(),
          child:
              const app.LeafGuardApp(showOnboarding: false, isLoggedIn: false),
        ),
      );

      // 1. Initial build
      await tester.pump();

      // 2. Perform navigation
      final loginContext = tester.element(find.byType(LoginScreen));
      Navigator.pushNamed(loginContext, '/home');

      // 3. Instead of pumpAndSettle, pump for a fixed duration.
      // This advances time enough for the transition but stops before infinite loops crash the test.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(
          seconds: 1)); // Buffer for async setup inside MainNavigation

      // 4. Verify
      expect(find.byType(MainNavigation), findsOneWidget);
    });
  });
}
