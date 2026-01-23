import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added for Session Management
import '../services/api_service.dart'; // Added for Backend Integration

class ResultScreen extends StatelessWidget {
  final File image;
  final List<Map<String, dynamic>> results;

  const ResultScreen({
    super.key,
    required this.image,
    required this.results,
  });

  // Automatically saves the scan to the Node.js backend
  Future<void> _saveToBackend(
      Map<String, dynamic> top, Map<String, dynamic> info) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      // Only upload if a token exists (Security Domain)
      if (token != null && token.isNotEmpty) {
        await ApiService().uploadScan(
          imageFile: image,
          label: top['label'],
          confidence: (top['confidence'] as num).toDouble(),
          status: info['status'] ?? "Unknown",
          plant: info['plant'] ?? "Unknown",
          cause: info['causes'] ?? "N/A",
          symptoms: info['symptoms'] ?? "N/A",
          treatment: info['treatment'] ?? "N/A",
          token: token,
        );
        debugPrint("Scan successfully synchronized with server.");
      }
    } catch (e) {
      debugPrint("Background Sync Error: $e");
    }
  }

  // Loads translated disease information from local JSON files
  Future<Map<String, dynamic>> _loadInfo(
      BuildContext context, String label) async {
    try {
      String langCode = context.locale.languageCode;
      final String response =
          await rootBundle.loadString('assets/translations/$langCode.json');
      final Map<String, dynamic> data = json.decode(response);

      final resultInfo = data[label] ??
          {
            "plant": "unknown".tr(),
            "status": "unknown".tr(),
            "causes": "N/A",
            "symptoms": "info_not_found".tr(),
            "treatment": "consult_expert".tr()
          };

      // Trigger background upload once info is loaded and verified
      if (label != "Background") {
        _saveToBackend(results.first, resultInfo);
      }

      return resultInfo;
    } catch (e) {
      debugPrint("Error loading translated JSON: $e");
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Error Check
    if (results.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("error_title".tr())),
        body: Center(child: Text("no_results".tr())),
      );
    }

    final top = results.first;

    // 2. NO LEAF DETECTED LOGIC (Background Class)
    if (top['label'] == "Background") {
      return _buildNoLeafUI(context);
    }

    // 3. NORMAL DIAGNOSIS UI
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Diagnosis Result'.tr()),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            onSelected: (Locale locale) => context.setLocale(locale),
            itemBuilder: (context) => [
              const PopupMenuItem(value: Locale('en'), child: Text("English")),
              const PopupMenuItem(
                  value: Locale('am'), child: Text("አማርኛ (Amharic)")),
              const PopupMenuItem(
                  value: Locale('or'), child: Text("Afaan Oromoo")),
            ],
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadInfo(context, top['label']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final info = snapshot.data ?? {};
          final bool isHealthy = info['status'] == "Healthy" ||
              info['status'] == "ጤናማ" ||
              info['status'] == "Fayyaa";

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildImageHeader(),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              _buildResultTitle(top, info, isHealthy),
              const SizedBox(height: 25),
              _buildQuickInfoRow(info),
              const SizedBox(height: 20),
              _sectionHeader(
                Icons.search,
                "Symptoms".tr(),
                trailing: IconButton(
                  icon: const Icon(Icons.volume_up, color: Colors.blue),
                  onPressed: () => TtsService().speak(
                      info['symptoms'] ?? "", context.locale.languageCode),
                ),
              ),
              _contentBox(info['symptoms']),
              const SizedBox(height: 15),
              _sectionHeader(
                Icons.medication,
                "Treatment".tr(),
                color: Colors.green[800]!,
                trailing: IconButton(
                  icon: const Icon(Icons.volume_up, color: Colors.green),
                  onPressed: () => TtsService().speak(
                      info['treatment'] ?? "", context.locale.languageCode),
                ),
              ),
              _contentBox(info['treatment']),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildNoLeafUI(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("invalid_subject".tr()),
          backgroundColor: Colors.orange[800],
          foregroundColor: Colors.white),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.center_focus_weak,
                  size: 100, color: Colors.orange[300]),
              const SizedBox(height: 20),
              Text("no_leaf_detected".tr(),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text("no_leaf_desc".tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black54)),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.camera_alt),
                label: Text("try_again".tr()),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageHeader() {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Image.file(image,
          height: 250, width: double.infinity, fit: BoxFit.cover),
    );
  }

  Widget _buildResultTitle(
      Map<String, dynamic> top, Map<String, dynamic> info, bool isHealthy) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(top['label'].replaceAll('_', ' '),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              Text(
                "${'confidence_level'.tr()}: ${(top['confidence'] * 100).toStringAsFixed(1)}%",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isHealthy ? Colors.green : Colors.redAccent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(info['status'] ?? "",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildQuickInfoRow(Map<String, dynamic> info) {
    return Row(
      children: [
        _infoTile(Icons.eco, "Plant".tr(), info['plant'] ?? ""),
        const SizedBox(width: 12),
        _infoTile(Icons.bug_report, "Cause".tr(), info['causes'] ?? ""),
      ],
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.green[700]),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title,
      {Color color = Colors.black, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const Spacer(),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _contentBox(dynamic content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: content is List
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content
                  .map((e) => Text("• $e",
                      style: const TextStyle(fontSize: 15, height: 1.4)))
                  .toList(),
            )
          : Text(content?.toString() ?? "N/A",
              style: const TextStyle(fontSize: 15, height: 1.4)),
    );
  }
}

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> speak(String text, String langCode) async {
    String ttsLang =
        langCode == 'am' ? 'am-ET' : (langCode == 'or' ? 'om-ET' : 'en-US');

    await _flutterTts.setLanguage(ttsLang);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  void stop() => _flutterTts.stop();
}
