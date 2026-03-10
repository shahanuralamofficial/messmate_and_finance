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

    final primaryColor = isDark ? const Color(0xFF6366F1) : const Color(0xFF4F46E5);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          AppTranslations.translate('settings', locale),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: 0.5),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () => themeProvider.setTheme(isDark ? AppTheme.light : AppTheme.dark),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        physics: const BouncingScrollPhysics(),
        children: [
          // User Profile Card
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: const EdgeInsets.all(20),
                leading: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: authProvider.userModel?.photoURL != null
                        ? NetworkImage(authProvider.userModel!.photoURL!)
                        : null,
                    child: authProvider.userModel?.photoURL == null
                        ? Icon(Icons.person, size: 35, color: primaryColor)
                        : null,
                  ),
                ),
                title: Text(
                  authProvider.userModel?.displayName ?? (isBangla ? 'ব্যবহারকারী' : 'User'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                subtitle: Text(
                  authProvider.userModel?.email ?? '',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          _buildSectionHeader(AppTranslations.translate('preferences', locale), isDark),
          _buildSettingsGroup([
            _buildSettingTile(
              context: context,
              icon: Icons.language_rounded,
              iconColor: Colors.blue,
              title: AppTranslations.translate('language', locale),
              subtitle: settings.locale.languageCode == 'bn' ? 'বাংলা' : 'English',
              onTap: () => _showLanguagePicker(context, settings, isBangla),
            ),
            _buildSettingTile(
              context: context,
              icon: Icons.payments_rounded,
              iconColor: Colors.teal,
              title: AppTranslations.translate('currency', locale),
              subtitle: '${settings.currency} (${settings.currencySymbol})',
              onTap: () => _showCurrencyPicker(context, settings, isBangla),
            ),
          ], cardColor, isDark),

          const SizedBox(height: 24),
          
          _buildSectionHeader(AppTranslations.translate('security', locale), isDark),
          _buildSettingsGroup([
            _buildSettingTile(
              context: context,
              icon: Icons.lock_person_rounded,
              iconColor: Colors.orange,
              title: AppTranslations.translate('app_lock', locale),
              subtitle: settings.pinEnabled 
                  ? (isBangla ? 'সক্রিয়' : 'Enabled') 
                  : (isBangla ? 'নিষ্ক্রিয়' : 'Disabled'),
              onTap: () => _showPinDialog(context, settings, isBangla),
            ),
            _buildToggleTile(
              icon: Icons.fingerprint_rounded,
              iconColor: Colors.pink,
              title: isBangla ? 'বায়োমেট্রিক লগইন' : 'Biometric Login',
              value: settings.biometricEnabled,
              onChanged: (val) async {
                final auth = LocalAuthentication();
                if (await auth.canCheckBiometrics) {
                  settings.setBiometricEnabled(val);
                }
              },
            ),
          ], cardColor, isDark),

          const SizedBox(height: 24),
          
          _buildSectionHeader(AppTranslations.translate('data', locale), isDark),
          _buildSettingsGroup([
            _buildSettingTile(
              context: context,
              icon: Icons.cloud_done_rounded,
              iconColor: Colors.cyan,
              title: isBangla ? 'ক্লাউড সিঙ্ক' : 'Cloud Sync',
              subtitle: isBangla ? 'এখনই আপডেট করুন' : 'Sync now',
              onTap: () async {
                if (authProvider.isAuthenticated) {
                  await financeProvider.loadUserData(authProvider.user!.uid);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        content: Text(isBangla ? 'সিঙ্ক সফল হয়েছে' : 'Sync Successful'),
                      ),
                    );
                  }
                }
              },
            ),
          ], cardColor, isDark),

          const SizedBox(height: 32),
          
          // Logout Button
          TextButton.icon(
            onPressed: () => authProvider.signOut(),
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            label: Text(
              isBangla ? 'লগ আউট' : 'Log Out',
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: isDark ? Colors.blueGrey[300] : Colors.blueGrey[600],
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children, Color cardColor, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      activeColor: const Color(0xFF4F46E5),
    );
  }

  void _showLanguagePicker(BuildContext context, SettingsProvider settings, bool isBangla) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text(isBangla ? 'ভাষা নির্বাচন করুন' : 'Select Language', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildPickerOption(context, 'বাংলা', settings.locale.languageCode == 'bn', () {
              settings.setLanguage('bn', context);
              Navigator.pop(context);
            }),
            _buildPickerOption(context, 'English', settings.locale.languageCode == 'en', () {
              settings.setLanguage('en', context);
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, SettingsProvider settings, bool isBangla) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text(isBangla ? 'কারেন্সি নির্বাচন করুন' : 'Select Currency', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildPickerOption(context, 'BDT (৳)', settings.currency == 'BDT', () {
              settings.setCurrency('BDT', '৳', context);
              Navigator.pop(context);
            }),
            _buildPickerOption(context, 'USD (\$)', settings.currency == 'USD', () {
              settings.setCurrency('USD', '\$', context);
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption(BuildContext context, String label, bool isSelected, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF4F46E5)) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showPinDialog(BuildContext context, SettingsProvider settings, bool isBangla) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isBangla ? 'সিকিউরিটি পিন' : 'Security PIN', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isBangla ? '৪-৬ ডিজিটের পিন দিন' : 'Enter 4-6 digit PIN',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(isBangla ? 'বাতিল' : 'Cancel'),
                ),
              ),
              if (settings.pinEnabled)
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      settings.disablePin();
                      Navigator.pop(context);
                    },
                    child: Text(isBangla ? 'বন্ধ করুন' : 'Disable', style: const TextStyle(color: Colors.redAccent)),
                  ),
                ),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (controller.text.length >= 4 && controller.text.length <= 6) {
                      settings.setPin(controller.text);
                      Navigator.pop(context);
                    } else {
                      HapticFeedback.vibrate();
                    }
                  },
                  child: Text(isBangla ? 'সেভ' : 'Save', style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
