import 'dart:io';
import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import 'result_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _historyItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.fetchHistory();
    setState(() {
      _historyItems = data;
      _isLoading = false;
    });
  }

  Future<void> _deleteItem(int id) async {
    await DatabaseHelper.instance.deleteScan(id);
    _loadHistory(); // Refresh the list after deletion
  }

  // Confirmation Dialog Function
  Future<bool?> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("delete_title".tr()), // Key: delete_title
        content: Text("delete_confirm_msg".tr()), // Key: delete_confirm_msg
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("cancel_btn".tr()), // Key: cancel_btn
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text("delete_btn".tr(),
                style: const TextStyle(color: Colors.white)), // Key: delete_btn
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("history_title".tr()), // Key: history_title
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: "refresh_btn".tr(), // Key: refresh_btn
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historyItems.isEmpty
              ? _buildEmptyState()
              : _buildHistoryList(_historyItems),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text("No scans yet",
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Your plant diagnoses will appear here.",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<Map<String, dynamic>> items) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Dismissible(
          key: Key(item['id'].toString()),
          direction: DismissDirection.endToStart, // Swipe left to delete
          confirmDismiss: (direction) async {
            // Reuses the same confirmation logic for swipes
            return await _showDeleteConfirmation(context);
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) => _deleteItem(item['id']),
          child: Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item['imagePath'] != null &&
                        File(item['imagePath']).existsSync()
                    ? Image.file(File(item['imagePath']),
                        width: 50, height: 50, fit: BoxFit.cover)
                    : Container(
                        width: 50,
                        height: 50,
                        color: Colors.green[100],
                        child: const Icon(Icons.eco, color: Colors.green)),
              ),
              title: Text(item['label'],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  "${item['date']}\nConfidence: ${(item['confidence'] * 100).toStringAsFixed(1)}%"),

              // Option 2: Visible Delete Button
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () async {
                  final confirm = await _showDeleteConfirmation(context);
                  if (confirm == true) {
                    _deleteItem(item['id']);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Scan deleted"),
                          duration: Duration(seconds: 2)),
                    );
                  }
                },
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResultScreen(
                      image: File(item['imagePath']),
                      results: [
                        {
                          'label': item['label'],
                          'confidence': item['confidence']
                        }
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
