
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _pinController = TextEditingController();
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isBN = settings.locale.languageCode == 'bn';

    return Scaffold(
      appBar: AppBar(
        title: Text(isBN ? 'নিরাপত্তা সেটআপ' : 'Security Setup'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader(isBN ? 'অ্যাপ লক' : 'App Lock'),
          SwitchListTile(
            title: Text(isBN ? 'পিন লক ব্যবহার করুন' : 'Use PIN Lock'),
            subtitle: Text(isBN ? 'অ্যাপ খুলতে পিন কোড লাগবে' : 'Require PIN to open app'),
            value: settings.pinEnabled,
            onChanged: (val) {
              if (val) {
                _showSetPinDialog(context, settings, isBN);
              } else {
                settings.disablePin();
              }
            },
          ),
          if (settings.pinEnabled) ...[
            const Divider(),
            SwitchListTile(
              title: Text(isBN ? 'বায়োমেট্রিক লক' : 'Biometric Lock'),
              subtitle: Text(isBN ? 'ফিংগারপ্রিন্ট বা ফেস আইডি' : 'Fingerprint or Face ID'),
              value: settings.biometricEnabled,
              onChanged: (val) => settings.setBiometricEnabled(val),
            ),
          ],
          const SizedBox(height: 30),
          _buildSectionHeader(isBN ? 'ডাটা ব্যাকআপ' : 'Data Backup'),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined, color: Colors.blue),
            title: Text(isBN ? 'ক্লাউড সিঙ্ক' : 'Cloud Sync'),
            subtitle: Text(isBN ? 'আপনার ডাটা ফায়ারবেসে সুরক্ষিত' : 'Your data is synced with Firebase'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
      ),
    );
  }

  void _showSetPinDialog(BuildContext context, SettingsProvider settings, bool isBN) {
    _pinController.clear();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isBN ? 'নতুন পিন সেট করুন' : 'Set New PIN'),
          content: TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            obscureText: _isObscured,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 10),
            decoration: InputDecoration(
              counterText: '',
              suffixIcon: IconButton(
                icon: Icon(_isObscured ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _isObscured = !_isObscured),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBN ? 'বাতিল' : 'Cancel')),
            ElevatedButton(
              onPressed: () {
                if (_pinController.text.length >= 4) {
                  settings.setPin(_pinController.text);
                  Navigator.pop(ctx);
                }
              },
              child: Text(isBN ? 'নিশ্চিত' : 'Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}
