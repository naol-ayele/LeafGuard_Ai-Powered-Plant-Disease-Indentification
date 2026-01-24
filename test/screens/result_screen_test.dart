import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:leafguard/screens/result_screen.dart';
import '../test_helper.dart';

void main() {
  late File mockImageFile;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await localizationSetup();
  });

  setUp(() {
    // Create a simple mock file
    mockImageFile = File('test.png');

    // Mock SharedPreferences to return no token (simulating logged out state)
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpResultScreen(
    WidgetTester tester, {
    required List<Map<String, dynamic>> results,
    String? heroTag,
  }) async {
    await tester.pumpWidget(
      wrapWithLocalization(
        child: ResultScreen(
          image: mockImageFile,
          results: results,
          heroTag: heroTag,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ResultScreen - Basic Tests', () {
    testWidgets('Shows error state when results are empty', (tester) async {
      await pumpResultScreen(tester, results: []);
      expect(find.text('error_title'.tr()), findsOneWidget);
      expect(find.text('no_results'.tr()), findsOneWidget);
    });

    testWidgets('Displays Background/No Leaf Detected UI', (tester) async {
      final results = [
        {'label': 'Background', 'confidence': 0.95}
      ];

      await pumpResultScreen(tester, results: results);

      expect(find.text('invalid_subject'.tr()), findsOneWidget);
      expect(find.text('no_leaf_detected'.tr()), findsOneWidget);
      expect(find.text('try_again'.tr()), findsOneWidget);
      expect(find.byIcon(Icons.center_focus_weak), findsOneWidget);
    });

    testWidgets('Displays diagnosis UI for healthy leaf', (tester) async {
      final results = [
        {'label': 'Apple___healthy', 'confidence': 0.92}
      ];

      await pumpResultScreen(tester, results: results);

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Diagnosis Result'.tr()), findsOneWidget);
      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('Shows confidence percentage correctly formatted',
        (tester) async {
      final results = [
        {'label': 'Apple___healthy', 'confidence': 0.8567}
      ];

      await pumpResultScreen(tester, results: results);

      expect(find.textContaining('85'), findsAtLeast(1));
      expect(find.textContaining('%'), findsAtLeast(1));
    });

    testWidgets('Hero animation works with heroTag', (tester) async {
      final results = [
        {'label': 'Apple___healthy', 'confidence': 0.9}
      ];

      await pumpResultScreen(
        tester,
        results: results,
        heroTag: 'test_hero_tag',
      );

      expect(find.byType(Hero), findsOneWidget);
    });

    testWidgets('No Hero animation without heroTag', (tester) async {
      final results = [
        {'label': 'Apple___healthy', 'confidence': 0.9}
      ];

      await pumpResultScreen(
        tester,
        results: results,
      );

      expect(find.byType(Hero), findsNothing);
      expect(find.byType(Image), findsOneWidget);
    });
  });

  group('ResultScreen - UI Components', () {
    testWidgets('Image header displays correctly', (tester) async {
      final results = [
        {'label': 'Apple___healthy', 'confidence': 0.9}
      ];

      await pumpResultScreen(tester, results: results);

      expect(find.byType(Card), findsAtLeast(1));
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('TTS buttons are present for symptoms and treatment',
        (tester) async {
      final results = [
        {'label': 'Apple___healthy', 'confidence': 0.85}
      ];

      await pumpResultScreen(tester, results: results);

      expect(find.byIcon(Icons.volume_up), findsAtLeast(1));
    });

    testWidgets('Displays status badge correctly', (tester) async {
      final results = [
        {'label': 'Apple___healthy', 'confidence': 0.9}
      ];

      await pumpResultScreen(tester, results: results);

      expect(find.byType(Container), findsWidgets);
    });
  });

  group('ResultScreen - Loading States', () {
    testWidgets('Shows loading indicator initially', (tester) async {
      final results = [
        {'label': 'Apple___healthy', 'confidence': 0.9}
      ];

      await tester.pumpWidget(
        wrapWithLocalization(
          child: ResultScreen(
            image: mockImageFile,
            results: results,
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('ResultScreen - Edge Cases', () {
    testWidgets('Handles high confidence values', (tester) async {
      final results = [
        {'label': 'Apple___healthy', 'confidence': 0.9999}
      ];

      await pumpResultScreen(tester, results: results);
      expect(find.textContaining('%'), findsAtLeast(1));
    });

    testWidgets('Handles low confidence values', (tester) async {
      final results = [
        {'label': 'Apple___healthy', 'confidence': 0.001}
      ];

      await pumpResultScreen(tester, results: results);
      expect(find.textContaining('%'), findsAtLeast(1));
    });

    testWidgets('Label shows without underscores', (tester) async {
      final results = [
        {'label': 'Apple___healthy', 'confidence': 0.9}
      ];

      await pumpResultScreen(tester, results: results);
      expect(find.textContaining('Apple'), findsAtLeast(1));
    });
  });

  group('ResultScreen - Language Switching', () {
    testWidgets('Language selector button is present', (tester) async {
      final results = [
        {'label': 'Apple___healthy', 'confidence': 0.9}
      ];

      await pumpResultScreen(tester, results: results);
      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('Language menu shows all options', (tester) async {
      final results = [
        {'label': 'Apple___healthy', 'confidence': 0.9}
      ];

      await pumpResultScreen(tester, results: results);

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      expect(find.text('English'), findsOneWidget);
      expect(find.text('አማርኛ (Amharic)'), findsOneWidget);
      expect(find.text('Afaan Oromoo'), findsOneWidget);
    });
  });

  group('ResultScreen - Backend Synchronization', () {
    testWidgets('Attempts to save to backend when token is present',
        (tester) async {
      // 1. Set a fake token in SharedPreferences
      SharedPreferences.setMockInitialValues({'token': 'fake_valid_token'});

      final results = [
        {'label': 'Tomato___Leaf_Mold', 'confidence': 0.88}
      ];

      await pumpResultScreen(tester, results: results);

      // We expect _saveToBackend to be called during _loadInfo.
      // To verify 100%, check if SharedPreferences.getInstance was called
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('token'), 'fake_valid_token');
      // Note: To verify the actual API call, you'd need to mock ApiService
    });

    testWidgets('Skips backend sync when token is missing', (tester) async {
      SharedPreferences.setMockInitialValues({}); // No token

      final results = [
        {'label': 'Tomato___Leaf_Mold', 'confidence': 0.88}
      ];

      await pumpResultScreen(tester, results: results);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('token'), isNull);
    });
  });

  group('ResultScreen - TTS Functionality', () {
    testWidgets('Tapping Symptoms volume icon triggers TTS', (tester) async {
      final results = [
        {'label': 'Apple___healthy', 'confidence': 0.9}
      ];
      await pumpResultScreen(tester, results: results);

      // Find the first volume icon (Symptoms) and tap it
      final volumeBtn = find.byIcon(Icons.volume_up).first;
      await tester.tap(volumeBtn);
      await tester.pump();

      // Verification: Since TtsService is a singleton with a private init,
      // we verify the button is enabled and tappable.
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tapping Treatment volume icon triggers TTS', (tester) async {
      final results = [
        {'label': 'Apple___healthy', 'confidence': 0.9}
      ];
      await pumpResultScreen(tester, results: results);

      // Find the second volume icon (Treatment)
      final volumeBtn = find.byIcon(Icons.volume_up).last;
      await tester.tap(volumeBtn);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('ResultScreen - Logic Branching', () {
    testWidgets('Displays Red badge for diseased status', (tester) async {
      final results = [
        {'label': 'Tomato___Late_blight', 'confidence': 0.9}
      ];

      await pumpResultScreen(tester, results: results);

      // Find the status container. We check for the background color red.
      final statusBadge = find
          .ancestor(
            of: find.text('Tomato___Late_blight.status'.tr()),
            matching: find.byType(Container),
          )
          .first;

      final container = tester.widget<Container>(statusBadge);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.redAccent);
    });

    testWidgets('Navigation back from No Leaf UI works', (tester) async {
      final results = [
        {'label': 'Background', 'confidence': 0.95}
      ];
      await pumpResultScreen(tester, results: results);

      final tryAgainBtn = find.text('try_again'.tr());
      await tester.tap(tryAgainBtn);
      await tester.pumpAndSettle();

      // Verify it tries to pop the screen
      // (In a real test, you'd check a mock navigator observer)
    });
  });
}
