// test/services/database_helper_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:leafguard/services/database_helper.dart';

// Generate mocks
@GenerateMocks([Database])
import 'database_helper_test.mocks.dart';

void main() {
  // Initialize sqflite ffi for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // Reset the singleton and close database before each test
  setUp(() async {
    DatabaseHelper.reset();
  });

  // Close database after all tests
  tearDownAll(() async {
    // Clean up any open database connections
  });

  group('DatabaseHelper Singleton Tests', () {
    test('Should return same instance', () {
      final instance1 = DatabaseHelper.instance;
      final instance2 = DatabaseHelper.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('Should allow instance injection for testing', () {
      final originalInstance = DatabaseHelper.instance;
      final testInstance = DatabaseHelper.internal();
      DatabaseHelper.instance = testInstance;

      expect(DatabaseHelper.instance, isNot(originalInstance));
      expect(DatabaseHelper.instance, testInstance);

      // Reset back
      DatabaseHelper.reset();
    });
  });

  group('Database Initialization Tests', () {
    test('Should initialize database only once', () async {
      final helper = DatabaseHelper.instance;

      // First call should initialize
      final db1 = await helper.database;

      // Second call should return same instance
      final db2 = await helper.database;

      expect(identical(db1, db2), isTrue);
    });

    test('Should create history table on database creation', () async {
      final helper = DatabaseHelper.instance;
      final db = await helper.database;

      // Verify table exists by querying it
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='history'");

      expect(tables.length, 1);
      expect(tables.first['name'], 'history');
    });

    test('Should create correct table schema', () async {
      final helper = DatabaseHelper.instance;
      final db = await helper.database;

      final tableInfo = await db.rawQuery('PRAGMA table_info(history)');

      // Check column definitions
      expect(tableInfo.length, 5); // id, label, confidence, date, imagePath

      // Verify each column
      final columns = tableInfo.map((row) => row['name'] as String).toList();
      expect(columns, contains('id'));
      expect(columns, contains('label'));
      expect(columns, contains('confidence'));
      expect(columns, contains('date'));
      expect(columns, contains('imagePath'));

      // Check primary key
      final idColumn = tableInfo.firstWhere((row) => row['name'] == 'id');
      expect(idColumn['pk'], 1);
    });
  });

  group('Database Operations Tests', () {
    late DatabaseHelper helper;

    setUp(() async {
      // Create a fresh helper instance for each test
      DatabaseHelper.reset();
      helper = DatabaseHelper.instance;
      final db = await helper.database; // Ensure database is initialized

      // Clear any existing data
      await db.delete('history');
    });

    tearDown(() async {
      // Close database to prevent state leakage
      final db = await helper.database;
      await db.close();
      DatabaseHelper.reset();
    });

    test('Should insert scan record', () async {
      final scanData = {
        'label': 'Tomato___Early_blight',
        'confidence': 0.95,
        'date': '2024-01-01 10:30:00',
        'imagePath': '/path/to/image.jpg'
      };

      final id = await helper.insertScan(scanData);

      expect(id, greaterThan(0));

      // Verify the record was inserted
      final db = await helper.database;
      final results =
          await db.query('history', where: 'id = ?', whereArgs: [id]);

      expect(results.length, 1);
      expect(results.first['label'], scanData['label']);
      expect(results.first['confidence'], scanData['confidence']);
      expect(results.first['date'], scanData['date']);
      expect(results.first['imagePath'], scanData['imagePath']);
    });

    test('Should fetch history in descending order by id', () async {
      // Insert multiple records in specific order
      final scans = [
        {
          'label': 'Scan 1',
          'confidence': 0.8,
          'date': '2024-01-01 09:00:00', // Earliest date
          'imagePath': '/path1.jpg'
        },
        {
          'label': 'Scan 2',
          'confidence': 0.9,
          'date': '2024-01-01 11:00:00', // Latest date
          'imagePath': '/path2.jpg'
        },
        {
          'label': 'Scan 3',
          'confidence': 0.7,
          'date': '2024-01-01 10:00:00', // Middle date
          'imagePath': '/path3.jpg'
        }
      ];

      // Insert in order: Scan 1, then Scan 2, then Scan 3
      final ids = <int>[];
      for (final scan in scans) {
        final id = await helper.insertScan(scan);
        ids.add(id);
      }

      final history = await helper.fetchHistory();

      // Should return all records
      expect(history.length, 3);

      // Should be in descending order by id (latest inserted first)
      // Since we inserted in order: Scan 1 (id=1), Scan 2 (id=2), Scan 3 (id=3)
      // Order should be: Scan 3 (latest id), Scan 2, Scan 1
      expect(history[0]['label'], 'Scan 3'); // Last inserted (highest id)
      expect(history[1]['label'], 'Scan 2'); // Second inserted
      expect(history[2]['label'], 'Scan 1'); // First inserted (lowest id)

      // Verify IDs are in descending order
      expect(history[0]['id'], greaterThan(history[1]['id']));
      expect(history[1]['id'], greaterThan(history[2]['id']));

      // Verify all data is intact
      for (final record in history) {
        expect(record.containsKey('id'), isTrue);
        expect(record.containsKey('label'), isTrue);
        expect(record.containsKey('confidence'), isTrue);
        expect(record.containsKey('date'), isTrue);
        expect(record.containsKey('imagePath'), isTrue);
      }
    });

    test('Should delete scan by id', () async {
      // Insert a record
      final scanData = {
        'label': 'Test Scan',
        'confidence': 0.85,
        'date': '2024-01-01 12:00:00',
        'imagePath': '/test/path.jpg'
      };

      final id = await helper.insertScan(scanData);

      // Verify it exists
      var history = await helper.fetchHistory();
      expect(history.length, 1);

      // Delete the record
      final deletedCount = await helper.deleteScan(id);
      expect(deletedCount, 1);

      // Verify it's gone
      history = await helper.fetchHistory();
      expect(history.length, 0);
    });

    test('Should return 0 when deleting non-existent scan', () async {
      final deletedCount = await helper.deleteScan(999);
      expect(deletedCount, 0);
    });

    test('Should handle inserting scan with missing optional fields', () async {
      final scanData = {
        'label': 'Test Disease',
        'confidence': 0.75,
        'date': '2024-01-01',
        // Missing imagePath - should still work
      };

      final id = await helper.insertScan(scanData);
      expect(id, greaterThan(0));

      final history = await helper.fetchHistory();
      expect(history.length, 1);
      expect(history.first['imagePath'], isNull);
    });

    test('Should handle decimal confidence values correctly', () async {
      final testCases = [
        {'confidence': 0.0, 'expected': 0.0},
        {'confidence': 0.5, 'expected': 0.5},
        {'confidence': 0.999, 'expected': 0.999},
        {'confidence': 1.0, 'expected': 1.0},
      ];

      for (final testCase in testCases) {
        // Create fresh helper for each test case
        DatabaseHelper.reset();
        helper = DatabaseHelper.instance;
        final db = await helper.database;
        await db.delete('history'); // Ensure clean state

        final scanData = {
          'label': 'Test Confidence',
          'confidence': testCase['confidence'] as double,
          'date': '2024-01-01',
          'imagePath': '/test.jpg'
        };

        await helper.insertScan(scanData);
        final history = await helper.fetchHistory();

        expect(history.length, 1);
        expect(history.first['confidence'], testCase['expected']);
      }
    });
  });

  group('Database Error Handling Tests', () {
    late DatabaseHelper helper;

    setUp(() async {
      DatabaseHelper.reset();
      helper = DatabaseHelper.instance;
      final db = await helper.database;
      await db.delete('history'); // Ensure clean state
    });

    tearDown(() async {
      final db = await helper.database;
      await db.close();
      DatabaseHelper.reset();
    });

    test('Should handle concurrent database access', () async {
      // Simulate concurrent access
      final futures = List.generate(5, (index) async {
        return helper.insertScan({
          'label': 'Concurrent Scan $index',
          'confidence': 0.5 + (index * 0.1),
          'date': '2024-01-01',
          'imagePath': '/concurrent/$index.jpg'
        });
      });

      final results = await Future.wait(futures);

      // All inserts should succeed with unique IDs
      expect(results.length, 5);
      expect(Set.from(results).length, 5); // All IDs should be unique

      final history = await helper.fetchHistory();
      expect(history.length, 5);
    });

    test('Should handle empty history gracefully', () async {
      // Database should be empty after setUp
      final history = await helper.fetchHistory();

      expect(history, isEmpty);
      expect(history, isA<List<Map<String, dynamic>>>());
    });

    test('Should handle special characters in label', () async {
      final specialLabels = [
        'Tomato___Early_blight',
        'Apple___healthy',
        'Background',
        'Test\'s Disease',
        'Test "Quoted" Disease',
        'Test&Disease',
        'Test-Disease',
        'Test.Disease',
      ];

      for (final label in specialLabels) {
        // Create fresh helper for each test case
        DatabaseHelper.reset();
        helper = DatabaseHelper.instance;
        final db = await helper.database;
        await db.delete('history'); // Ensure clean state

        await helper.insertScan({
          'label': label,
          'confidence': 0.8,
          'date': '2024-01-01',
          'imagePath': '/test.jpg'
        });

        final history = await helper.fetchHistory();
        expect(history.length, 1);
        expect(history.first['label'], label);

        // Close database
        await db.close();
      }
    });
  });

  group('Database Path Tests', () {
    setUp(() {
      DatabaseHelper.reset();
    });

    test('Should use correct database path', () async {
      final helper = DatabaseHelper.instance;
      final db = await helper.database;

      // Get the database path
      final pathResult = await db.rawQuery('PRAGMA database_list');
      final mainDb = pathResult.firstWhere((db) => db['name'] == 'main');
      final dbPath = mainDb['file'] as String;

      expect(dbPath, contains('leafguard.db'));

      await db.close();
    });
  });

  group('Database Version Tests', () {
    setUp(() {
      DatabaseHelper.reset();
    });

    test('Should open with correct version', () async {
      final helper = DatabaseHelper.instance;
      final db = await helper.database;

      final version = await db.getVersion();
      expect(version, 1);

      await db.close();
    });
  });
}
