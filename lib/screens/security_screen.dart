
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/translations.dart';

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
    final locale = settings.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.translate('security_setup', locale)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader(AppTranslations.translate('app_lock', locale)),
          SwitchListTile(
            title: Text(AppTranslations.translate('use_pin_lock', locale)),
            subtitle: Text(AppTranslations.translate('require_pin', locale)),
            value: settings.pinEnabled,
            onChanged: (val) {
              if (val) {
                _showSetPinDialog(context, settings, locale);
              } else {
                settings.disablePin();
              }
            },
          ),
          if (settings.pinEnabled) ...[
            const Divider(),
            SwitchListTile(
              title: Text(AppTranslations.translate('biometric_lock', locale)),
              subtitle: Text(AppTranslations.translate('fingerprint_face', locale)),
              value: settings.biometricEnabled,
              onChanged: (val) => settings.setBiometricEnabled(val),
            ),
          ],
          const SizedBox(height: 30),
          _buildSectionHeader(AppTranslations.translate('data_backup', locale)),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined, color: Colors.blue),
            title: Text(AppTranslations.translate('cloud_sync', locale)),
            subtitle: Text(AppTranslations.translate('synced_firebase', locale)),
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

  void _showSetPinDialog(BuildContext context, SettingsProvider settings, String locale) {
    _pinController.clear();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppTranslations.translate('set_new_pin', locale)),
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppTranslations.translate('cancel', locale))),
            ElevatedButton(
              onPressed: () {
                if (_pinController.text.length >= 4) {
                  settings.setPin(_pinController.text);
                  Navigator.pop(ctx);
                }
              },
              child: Text(AppTranslations.translate('save', locale)),
            ),
          ],
        ),
      ),
    );
  }
}
