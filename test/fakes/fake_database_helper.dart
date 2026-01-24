import 'package:sqflite/sqflite.dart';
import 'package:leafguard/services/database_helper.dart';

class FakeDatabaseHelper extends DatabaseHelper {
  FakeDatabaseHelper() : super.internal();

  List<Map<String, dynamic>> fakeData = [];

  // FIX: Must match return type Future<Database>
  @override
  Future<Database> get database async => throw UnsupportedError('Fake DB only');

  @override
  Future<List<Map<String, dynamic>>> fetchHistory() async {
    return fakeData;
  }

  @override
  Future<int> deleteScan(int id) async {
    fakeData.removeWhere((e) => e['id'] == id);
    return 1;
  }

  @override
  Future<int> insertScan(Map<String, dynamic> row) async {
    fakeData.add(row);
    return 1;
  }
}
