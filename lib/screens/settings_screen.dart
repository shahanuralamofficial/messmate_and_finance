import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/finance_provider.dart';
import '../utils/translations.dart';
import '../widgets/bottom_nav_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final financeProvider = Provider.of<FinanceProvider>(context);
    final isBangla = settings.locale.languageCode == 'bn';
    final locale = settings.locale.languageCode;
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          AppTranslations.translate('settings', locale),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: const CircleAvatar(
                radius: 25,
                backgroundColor: Colors.black,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                authProvider.userModel?.displayName ?? (isBangla ? 'ব্যবহারকারী' : 'User'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(isBangla ? 'আপনার প্রোফাইল পরিচালনা করুন' : 'Manage your profile'),
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(AppTranslations.translate('preferences', locale), isDark),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                _buildDropdownTile(
                  icon: Icons.account_balance_wallet,
                  title: AppTranslations.translate('currency', locale),
                  value: '${settings.currency} (${settings.currencySymbol})',
                  onChanged: (val) {
                    if (val == 'BDT') settings.setCurrency('BDT', '৳', context);
                    if (val == 'USD') settings.setCurrency('USD', '\$', context);
                  },
                  items: const [
                    DropdownMenuItem(value: 'BDT', child: Text('BDT (৳)')),
                    DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                  ],
                ),
                const Divider(height: 1),
                _buildDropdownTile(
                  icon: Icons.language,
                  title: AppTranslations.translate('language', locale),
                  value: settings.locale.languageCode == 'bn' ? 'Bengali' : 'English',
                  onChanged: (val) {
                    settings.setLanguage(val == 'Bengali' ? 'bn' : 'en', context);
                  },
                  items: const [
                    DropdownMenuItem(value: 'Bengali', child: Text('বাংলা')),
                    DropdownMenuItem(value: 'English', child: Text('English')),
                  ],
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode),
                  title: Text(AppTranslations.translate('dark_mode', locale)),
                  value: themeProvider.isDarkMode,
                  onChanged: (val) {
                    themeProvider.setTheme(val ? AppTheme.dark : AppTheme.light);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(AppTranslations.translate('security', locale), isDark),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: Text(AppTranslations.translate('app_lock', locale)),
                  subtitle: Text(settings.pinEnabled 
                    ? (isBangla ? 'সক্রিয়' : 'Enabled') 
                    : (isBangla ? 'নিষ্ক্রিয়' : 'Disabled')),
                  trailing: TextButton(
                    onPressed: () => _showPinDialog(context, settings, isBangla),
                    child: Text(settings.pinEnabled 
                      ? (isBangla ? 'পরিবর্তন করুন' : 'Change') 
                      : (isBangla ? 'সেট করুন' : 'Set PIN')),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: Text(isBangla ? 'বায়োমেট্রিক লগইন' : 'Biometric Login'),
                  value: settings.biometricEnabled,
                  onChanged: (val) async {
                    final auth = LocalAuthentication();
                    if (await auth.canCheckBiometrics) {
                      settings.setBiometricEnabled(val);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(AppTranslations.translate('data', locale), isDark),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: const Icon(Icons.cloud_sync),
              title: Text(isBangla ? 'ক্লাউড সিঙ্ক' : 'Cloud Sync'),
              onTap: () async {
                if (authProvider.isAuthenticated) {
                  await financeProvider.loadUserData(authProvider.user!.uid);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isBangla ? 'সিঙ্ক সফল হয়েছে' : 'Sync Successful')));
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 4),
    );
  }

  void _showPinDialog(BuildContext context, SettingsProvider settings, bool isBangla) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isBangla ? 'পিন সেট করুন' : 'Set PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isBangla ? '৪-৬ ডিজিটের পিন দিন' : 'Enter 4-6 digit PIN',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: InputDecoration(
                hintText: '****',
                counterText: "",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(isBangla ? 'বাতিল' : 'Cancel')),
          if (settings.pinEnabled)
            TextButton(
              onPressed: () {
                settings.disablePin();
                Navigator.pop(context);
              },
              child: Text(isBangla ? 'বন্ধ করুন' : 'Disable', style: const TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.length >= 4 && controller.text.length <= 6) {
                settings.setPin(controller.text);
                Navigator.pop(context);
              } else {
                HapticFeedback.vibrate();
              }
            },
            child: Text(isBangla ? 'সেভ' : 'Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) => Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(title, style: TextStyle(color: isDark ? Colors.blueAccent : Colors.grey[600], fontSize: 14, fontWeight: FontWeight.bold)));

  Widget _buildDropdownTile({required IconData icon, required String title, required String value, required void Function(dynamic)? onChanged, required List<DropdownMenuItem<dynamic>> items}) => ListTile(leading: Icon(icon), title: Text(title), subtitle: Text(value), trailing: DropdownButton<dynamic>(underline: const SizedBox(), icon: const Icon(Icons.arrow_drop_down), onChanged: onChanged, items: items));
}
