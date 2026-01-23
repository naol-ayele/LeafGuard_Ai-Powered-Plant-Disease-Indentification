import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart'; // Required for .tr()
import '../services/database_helper.dart';
import 'dart:io';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _latestScan;

  @override
  void initState() {
    super.initState();
    _loadLatestScan();
  }

  // Reloads the latest scan from SQLite
  Future<void> _loadLatestScan() async {
    final history = await DatabaseHelper.instance.fetchHistory();
    if (history.isNotEmpty) {
      setState(() {
        _latestScan = history.first;
      });
    } else {
      setState(() {
        _latestScan = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("LeafGuard",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Language Quick-Switch Icon
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language, color: Colors.green),
            onSelected: (Locale locale) {
              context.setLocale(locale);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: Locale('en'), child: Text("English")),
              const PopupMenuItem(value: Locale('am'), child: Text("አማርኛ")),
              const PopupMenuItem(
                  value: Locale('or'), child: Text("Afaan Oromoo")),
            ],
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLatestScan,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Text("welcome_back".tr(),
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green)),
              Text("home_subtitle".tr(),
                  style: const TextStyle(fontSize: 16, color: Colors.grey)),

              const SizedBox(height: 25),

              // Guidelines Section
              Text("guide_title".tr(),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildGuideSection(),

              const SizedBox(height: 25),

              // Recent Activity Section
              Text("recent_activity".tr(),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              _latestScan == null
                  ? Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text("no_scans".tr(), textAlign: TextAlign.center),
                    )
                  : InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ResultScreen(
                              image: File(_latestScan!['imagePath']),
                              results: [
                                {
                                  'label': _latestScan!['label'],
                                  'confidence': _latestScan!['confidence']
                                }
                              ],
                            ),
                          ),
                        ).then((_) =>
                            _loadLatestScan()); // Refresh when coming back
                      },
                      child: _buildQuickCard(
                        _latestScan!['label'].toString().replaceAll('_', ' '),
                        "${"confidence_label".tr(args: [
                              (_latestScan!['confidence'] * 100)
                                  .toStringAsFixed(1)
                            ])} • ${_latestScan!['date']}",
                        Icons.history,
                        Colors.green,
                        _latestScan!['imagePath'],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: Column(
        children: [
          _guideItem(Icons.filter_center_focus, "guide_1".tr()),
          _guideItem(Icons.wb_sunny_outlined, "guide_2".tr()),
          _guideItem(Icons.crop_free, "guide_3".tr()),
          _guideItem(Icons.camera_alt, "guide_4".tr()),
        ],
      ),
    );
  }

  Widget _guideItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green[700], size: 22),
          const SizedBox(width: 15),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildQuickCard(String title, String subtitle, IconData icon,
      Color color, String imagePath) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(imagePath),
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color)),
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }
}
