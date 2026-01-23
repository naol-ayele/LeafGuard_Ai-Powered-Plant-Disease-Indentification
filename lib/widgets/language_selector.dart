import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Locale>(
          value: context.locale,
          icon: Icon(Icons.language, color: Colors.green[700], size: 20),
          elevation: 16,
          style:
              TextStyle(color: Colors.green[900], fontWeight: FontWeight.w600),
          onChanged: (Locale? newLocale) {
            if (newLocale != null) {
              context.setLocale(newLocale);
            }
          },
          items: [
            DropdownMenuItem(
              value: const Locale('en'),
              child: Text("English"),
            ),
            DropdownMenuItem(
              value: const Locale('am'), // Example: Spanish
              child: Text("አማርኛ"),
            ),
            DropdownMenuItem(
              value: const Locale('or'), // Example: French
              child: Text("Afan Oromo"),
            ),
          ],
        ),
      ),
    );
  }
}
