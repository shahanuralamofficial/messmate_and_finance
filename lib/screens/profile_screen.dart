import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/finance_provider.dart';
import '../utils/translations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _nameController.text = authProvider.userModel?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile(AuthProvider authProvider) async {
    if (_nameController.text.trim().isEmpty) return;
    
    HapticFeedback.mediumImpact();
    try {
      await authProvider.updateUserSettings({
        'displayName': _nameController.text.trim(),
      });
      if (mounted) {
        final locale = Provider.of<SettingsProvider>(context, listen: false).locale.languageCode;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(locale == 'bn' ? 'প্রোফাইল আপডেট হয়েছে' : 'Profile Updated Successfully'),
            backgroundColor: Colors.green,
          )
        );
      }
    } catch (e) {
      debugPrint('Update error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final financeProvider = Provider.of<FinanceProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final locale = settings.locale.languageCode;
    final isBangla = locale == 'bn';
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Professional Gradient Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark 
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [Colors.black, const Color(0xFF334155)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.grey[800],
                            backgroundImage: authProvider.userModel?.photoURL != null
                                ? NetworkImage(authProvider.userModel!.photoURL!)
                                : null,
                            child: authProvider.userModel?.photoURL == null
                                ? Text(
                                    (authProvider.userModel?.displayName?.isNotEmpty == true 
                                      ? authProvider.userModel!.displayName![0] 
                                      : authProvider.user?.email?[0] ?? 'U').toUpperCase(),
                                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                                  )
                                : null,
                          ),
                        ),
                        if (_isEditing)
                          GestureDetector(
                            onTap: _showImagePickerDialog,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isEditing)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: TextField(
                          controller: _nameController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                          ),
                        ),
                      )
                    else
                      Text(
                        authProvider.userModel?.displayName ?? (isBangla ? 'ব্যবহারকারী' : 'User'),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    Text(
                      authProvider.user?.email ?? '',
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(_isEditing ? Icons.check_circle : Icons.edit, color: Colors.white),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  if (_isEditing) {
                    await _updateProfile(authProvider);
                  }
                  setState(() => _isEditing = !_isEditing);
                },
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats Row
                  Row(
                    children: [
                      _buildStatCard(isBangla ? 'অ্যাকাউন্টস' : 'Accounts', financeProvider.accounts.length.toString(), Icons.wallet, Colors.blue, isDark),
                      const SizedBox(width: 12),
                      _buildStatCard(isBangla ? 'নোটস' : 'Notes', financeProvider.notes.length.toString(), Icons.notes, Colors.orange, isDark),
                    ],
                  ),
                  const SizedBox(height: 32),

                  _buildSectionLabel(isBangla ? 'ব্যক্তিগত তথ্য' : 'Personal Information', isDark),
                  _buildSettingsGroup([
                    _buildProfessionalTile(
                      icon: Icons.email_rounded,
                      title: isBangla ? 'ইমেইল' : 'Email Address',
                      subtitle: authProvider.user?.email ?? '',
                      iconColor: Colors.redAccent,
                      isDark: isDark,
                    ),
                    _buildProfessionalTile(
                      icon: Icons.calendar_month_rounded,
                      title: isBangla ? 'যোগদানের তারিখ' : 'Member Since',
                      subtitle: authProvider.userModel != null 
                        ? DateFormat.yMMMMd(locale == 'bn' ? 'bn_BD' : 'en_US').format(authProvider.userModel!.createdAt)
                        : '',
                      iconColor: Colors.greenAccent,
                      isDark: isDark,
                    ),
                  ], isDark),

                  const SizedBox(height: 24),
                  _buildSectionLabel(isBangla ? 'নিরাপত্তা ও সেটিংস' : 'Security & Actions', isDark),
                  _buildSettingsGroup([
                    _buildProfessionalTile(
                      icon: Icons.lock_reset_rounded,
                      title: isBangla ? 'পাসওয়ার্ড পরিবর্তন' : 'Change Password',
                      subtitle: isBangla ? 'ইমেইল লিঙ্ক পাঠানো হবে' : 'Send reset link to email',
                      iconColor: Colors.blueAccent,
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        authProvider.resetPassword(authProvider.user!.email!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isBangla ? 'ইমেইল পাঠানো হয়েছে' : 'Reset email sent'))
                        );
                      },
                    ),
                    _buildProfessionalTile(
                      icon: Icons.logout_rounded,
                      title: AppTranslations.translate('logout', locale),
                      subtitle: isBangla ? 'অ্যাকাউন্ট থেকে বের হয়ে যান' : 'Sign out of your account',
                      iconColor: Colors.red,
                      isDark: isDark,
                      onTap: () => _showLogoutDialog(context, authProvider, isBangla),
                    ),
                  ], isDark),
                  
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      'v1.0.0 (Stable)',
                      style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.blueAccent : Colors.blueGrey, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildProfessionalTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      trailing: onTap != null ? Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]) : null,
    );
  }

  void _showImagePickerDialog() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(Icons.camera_alt_rounded, 'Camera', ImageSource.camera),
                _buildPickerOption(Icons.photo_library_rounded, 'Gallery', ImageSource.gallery),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption(IconData icon, String label, ImageSource source) {
    return InkWell(
      onTap: () => _pickImage(source),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.blueAccent, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      // Logic for upload can be added here
    }
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider, bool isBangla) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isBangla ? 'লগআউট' : 'Logout'),
        content: Text(isBangla ? 'আপনি কি নিশ্চিতভাবে লগআউট করতে চান?' : 'Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBangla ? 'বাতিল' : 'Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await authProvider.signOut();
              if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(isBangla ? 'লগআউট' : 'Logout', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
