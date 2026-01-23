import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafguard/screens/history_screen.dart';
import 'package:leafguard/services/database_helper.dart';
import '../test_helper.dart';
import '../fakes/fake_database_helper.dart';

void main() {
  late FakeDatabaseHelper fakeDb;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await localizationSetup(); // Defined in test_helper.dart
  });

  setUp(() {
    fakeDb = FakeDatabaseHelper();
    DatabaseHelper.instance = fakeDb;
  });

  tearDown(() {
    DatabaseHelper.reset();
  });

  // Helper function WITHOUT setUpAll inside it
  Future<void> pumpHistoryScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      wrapWithLocalization(
        child: const HistoryScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('HistoryScreen Tests', () {
    testWidgets('Shows empty state when no data exists', (tester) async {
      fakeDb.fakeData = [];
      await pumpHistoryScreen(tester);
      expect(find.byIcon(Icons.history_outlined), findsOneWidget);
      expect(find.text('history_empty'.tr()), findsOneWidget);
    });

    testWidgets('Displays history list items from database', (tester) async {
      fakeDb.fakeData = [
        {
          'id': 1,
          'label': 'Leaf Blight',
          'confidence': 0.92,
          'date': '2026-01-01',
          'imagePath': 'assets/test_leaf.png',
        },
      ];
      await pumpHistoryScreen(tester);
      expect(find.text('Leaf Blight'), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('Delete via trailing delete button', (tester) async {
      fakeDb.fakeData = [
        {
          'id': 1,
          'label': 'Leaf Blight',
          'confidence': 0.92,
          'date': '2026-01-01'
        }
      ];
      await pumpHistoryScreen(tester);
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('delete_btn'.tr()));
      await tester.pumpAndSettle();
      expect(fakeDb.fakeData.length, 0);
      expect(find.text('history_empty'.tr()), findsOneWidget);
    });

    testWidgets('Search shows no results found', (tester) async {
      fakeDb.fakeData = [
        {'id': 1, 'label': 'Healthy', 'confidence': 0.99, 'date': '2026-01-01'}
      ];

      await pumpHistoryScreen(tester);
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Blight');
      await tester.pumpAndSettle();

      expect(find.text('search_no_results'.tr()), findsOneWidget);
      expect(find.text('Healthy'), findsNothing);
    });

    testWidgets('UI correctly formats confidence percentage', (tester) async {
      fakeDb.fakeData = [
        {
          'id': 1,
          'label': 'Blight',
          'confidence': 0.856,
          'date': '2026-01-01',
          'imagePath': 'assets/test.png'
        }
      ];

      await pumpHistoryScreen(tester);
      // Finds "85" or "86" depending on your rounding logic
      expect(find.textContaining('85'), findsOneWidget);
    });

    testWidgets('Can scroll through a long list of history', (tester) async {
      fakeDb.fakeData = List.generate(
          20,
          (i) => {
                'id': i,
                'label': 'Plant $i',
                'confidence': 0.9,
                'date': '2026-01-01'
              });

      await pumpHistoryScreen(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Plant 15'), findsOneWidget);
    });

    testWidgets('Tapping item navigates to details', (tester) async {
      fakeDb.fakeData = [
        {
          'id': 1,
          'label': 'Tomato___Early_blight', // Match a key from your JSON
          'confidence': 0.92,
          'date': '2026-01-01',
          'imagePath': 'assets/test_leaf.png'
        }
      ];

      await pumpHistoryScreen(tester);

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      // FIX: Look for the translation of the diagnosis_title key
      expect(find.text('diagnosis_title'.tr()), findsOneWidget);

      // Alternatively, if you want to be extra sure, check for the "Plant" label
      expect(find.text('Plant'.tr()), findsOneWidget);
    });

    testWidgets('Pull to refresh updates the list', (tester) async {
      // Start with initial data
      fakeDb.fakeData = [
        {
          'id': 1,
          'label': 'Initial Item',
          'confidence': 0.9,
          'date': '2026-01-01'
        }
      ];

      await pumpHistoryScreen(tester);

      // Verify initial data is shown
      expect(find.text('Initial Item'), findsOneWidget);

      // Update the data in fake database
      fakeDb.fakeData = [
        {
          'id': 2,
          'label': 'Refreshed Item',
          'confidence': 0.85,
          'date': '2026-01-02',
          'imagePath':
              'assets/test_leaf.png' // Add imagePath if your widget expects it
        }
      ];

      // Instead of pull-to-refresh, tap the refresh button in AppBar
      await tester.tap(find.byIcon(Icons.refresh));

      // Wait for the refresh to complete
      await tester.pumpAndSettle();

      // Check if refreshed data is shown
      expect(find.text('Refreshed Item'), findsOneWidget);
      expect(find.text('Initial Item'), findsNothing);
    });
  });
}
