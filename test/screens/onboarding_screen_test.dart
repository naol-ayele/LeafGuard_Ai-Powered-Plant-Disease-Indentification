import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafguard/screens/onboarding_screen.dart'; // Adjust path
import 'package:shared_preferences/shared_preferences.dart';
import '../test_helper.dart';

// Create a fake MainNavigation that doesn't trigger CameraScreen
class FakeMainNavigation extends StatelessWidget {
  const FakeMainNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Fake Main Navigation')),
    );
  }
}

void main() {
  setUp(() async {
    // Initializes SharedPreferences with an empty state for every test
    SharedPreferences.setMockInitialValues({});

    await localizationSetup();
  });

  Future<void> pumpOnboarding(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return wrapWithLocalization(child: const OnboardingScreen());
          },
        ),
        onGenerateRoute: (settings) {
          // Intercept navigation to MainNavigation to avoid CameraScreen initialization
          if (settings.name == null ||
              settings.name!.contains('main') ||
              settings.name!.contains('navigation')) {
            return MaterialPageRoute(
                builder: (_) => const FakeMainNavigation());
          }
          return null;
        },
        navigatorObservers: [FakeNavigatorObserver()],
      ),
    );
    await tester.pumpAndSettle();
  }

  group('OnboardingScreen Tests', () {
    testWidgets('Initializes on the first page', (tester) async {
      await pumpOnboarding(tester);

      expect(find.text("Instant Detection"), findsOneWidget);
      expect(find.text("Next"), findsOneWidget);
      expect(find.text("Skip"), findsOneWidget);
    });

    testWidgets('Tapping Next navigates through pages', (tester) async {
      await pumpOnboarding(tester);

      // Page 1 -> Page 2
      await tester.tap(find.text("Next"));
      await tester.pumpAndSettle();
      expect(find.text("Expert Cures"), findsOneWidget);

      // Page 2 -> Page 3
      await tester.tap(find.text("Next"));
      await tester.pumpAndSettle();
      expect(find.text("Healthy Harvest"), findsOneWidget);

      // On last page, "Next" should become "Get Started"
      expect(find.text("Get Started"), findsOneWidget);
      expect(find.text("Skip"), findsNothing);
    });

    testWidgets('Swiping changes pages', (tester) async {
      await pumpOnboarding(tester);

      // Swipe Left to go to next page
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text("Expert Cures"), findsOneWidget);
    });

    testWidgets('Finishing onboarding sets SharedPreferences flag',
        (tester) async {
      await pumpOnboarding(tester);

      // Skip to the end (using the Skip button)
      await tester.tap(find.text("Skip"));

      // Wait for the navigation to complete but don't trigger CameraScreen
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      final prefs = await SharedPreferences.getInstance();
      // Verify that 'showOnboarding' is now false
      expect(prefs.getBool('showOnboarding'), isFalse);
    });
  });
}

// Helper class to intercept navigation
class FakeNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Intercept navigation pushes
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    // Intercept navigation replacements
  }
}
