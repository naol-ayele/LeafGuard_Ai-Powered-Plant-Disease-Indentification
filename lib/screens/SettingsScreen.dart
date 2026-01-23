import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _userName = "...";
  String _userEmail = "...";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from local storage
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? "User";
      _userEmail = prefs.getString('userEmail') ?? "email@example.com";
    });
  }

  // Function to show Language Picker
  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "change_language".tr(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              ListTile(
                leading: const Text("🇺🇸", style: TextStyle(fontSize: 24)),
                title: const Text("English"),
                trailing: context.locale == const Locale('en')
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  context.setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text("🇪🇹", style: TextStyle(fontSize: 24)),
                title: const Text("Afaan Oromoo"),
                trailing: context.locale == const Locale('or')
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  context.setLocale(const Locale('or'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text("🇪🇹", style: TextStyle(fontSize: 24)),
                title: const Text("አማርኛ (Amharic)"),
                trailing: context.locale == const Locale('am')
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  context.setLocale(const Locale('am'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Function to show Change Password Dialog (Applied Change)
  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    bool isRequesting = false;
    bool isCurrentVisible = false;
    bool isNewVisible = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("change_password".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("change_password_instruction".tr(),
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 15),
              TextField(
                controller: currentPasswordController,
                obscureText: !isCurrentVisible,
                decoration: InputDecoration(
                  labelText: "current_password".tr(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(isCurrentVisible
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () => setDialogState(
                        () => isCurrentVisible = !isCurrentVisible),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPasswordController,
                obscureText: !isNewVisible,
                decoration: InputDecoration(
                  labelText: "new_password".tr(),
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(
                        isNewVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () =>
                        setDialogState(() => isNewVisible = !isNewVisible),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("cancel".tr(),
                  style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isRequesting
                  ? null
                  : () async {
                      if (currentPasswordController.text.isEmpty ||
                          newPasswordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("fill_all_fields".tr())));
                        return;
                      }

                      setDialogState(() => isRequesting = true);
                      // Assuming you have a changePassword method in AuthService
                      final res = await AuthService().changePassword(
                        currentPasswordController.text,
                        newPasswordController.text,
                      );
                      setDialogState(() => isRequesting = false);

                      if (mounted) {
                        if (res['success']) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text("password_updated".tr()),
                                backgroundColor: Colors.green),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text(res['error'] ?? "error_occurred".tr()),
                                backgroundColor: Colors.redAccent),
                          );
                        }
                      }
                    },
              child: isRequesting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text("update".tr(),
                      style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout() async {
    // Show confirmation dialog
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text("logout_title".tr()),
            content: Text("logout_confirm".tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("cancel".tr(),
                    style: const TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("logout_btn".tr(),
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await AuthService().logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("settings".tr(),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.green[700],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 65, color: Colors.green),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Edit Profile Picture")),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                )
                              ]),
                          child: Icon(Icons.camera_alt,
                              size: 18, color: Colors.green[700]),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  _userName,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                Text(
                  _userEmail,
                  style: TextStyle(fontSize: 14, color: Colors.green[100]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Settings List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSettingsItem(
                  icon: Icons.language,
                  title: "change_language".tr(),
                  onTap: _showLanguagePicker,
                ),
                // Applied Change: Change Password (Internal Settings)
                _buildSettingsItem(
                  icon: Icons.lock_outline,
                  title: "change_password".tr(),
                  onTap: _showChangePasswordDialog,
                ),
                const Divider(height: 40, thickness: 1),
                _buildSettingsItem(
                  icon: Icons.logout,
                  title: "logout_btn".tr(),
                  iconColor: Colors.redAccent,
                  textColor: Colors.redAccent,
                  onTap: _handleLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.grey.withOpacity(0.1))),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? Colors.green).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? Colors.green[700]),
        ),
        title: Text(title,
            style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
