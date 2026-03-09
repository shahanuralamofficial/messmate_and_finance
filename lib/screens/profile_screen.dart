import 'dart:io';
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
  bool _isLoading = false;

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
    setState(() => _isLoading = true);
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          )
        );
      }
    } catch (e) {
      debugPrint('Update error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source, AuthProvider authProvider) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    
    if (pickedFile != null) {
      setState(() => _isLoading = true);
      try {
        await authProvider.updateProfilePicture(File(pickedFile.path));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated!'), backgroundColor: Colors.green)
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
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
    
    final primaryColor = isDark ? const Color(0xFF6366F1) : const Color(0xFF4F46E5);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium Header with dynamic elements
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            stretch: true,
            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: Icon(_isEditing ? Icons.check_circle_rounded : Icons.edit_note_rounded, 
                    color: primaryColor, size: 28),
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    if (_isEditing) {
                      await _updateProfile(authProvider);
                    }
                    setState(() => _isEditing = !_isEditing);
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Decorative Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          primaryColor.withOpacity(isDark ? 0.3 : 0.2),
                          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withOpacity(0.05),
                      ),
                    ),
                  ),
                  
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Hero(
                            tag: 'profile_pic',
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: primaryColor.withOpacity(0.5), width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                backgroundImage: authProvider.userModel?.photoURL != null
                                    ? NetworkImage(authProvider.userModel!.photoURL!)
                                    : null,
                                child: authProvider.userModel?.photoURL == null
                                    ? Text(
                                        (authProvider.userModel?.displayName?.isNotEmpty == true 
                                          ? authProvider.userModel!.displayName![0] 
                                          : authProvider.user?.email?[0] ?? 'U').toUpperCase(),
                                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: primaryColor),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          if (_isLoading)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.24), shape: BoxShape.circle),
                                child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
                              ),
                            ),
                          GestureDetector(
                            onTap: () => _showImagePickerDialog(authProvider),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: isDark ? const Color(0xFF0F172A) : Colors.white, width: 3),
                                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_isEditing)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 50),
                          child: TextField(
                            controller: _nameController,
                            textAlign: TextAlign.center,
                            autofocus: true,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF1E293B), 
                              fontSize: 22, 
                              fontWeight: FontWeight.w800
                            ),
                            decoration: InputDecoration(
                              hintText: isBangla ? 'নাম লিখুন' : 'Enter Name',
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor.withOpacity(0.3))),
                              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                            ),
                          ),
                        )
                      else
                        Column(
                          children: [
                            Text(
                              authProvider.userModel?.displayName ?? (isBangla ? 'ব্যবহারকারী' : 'User'),
                              style: TextStyle(
                                fontSize: 24, 
                                fontWeight: FontWeight.w900, 
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                                letterSpacing: -0.5
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              authProvider.user?.email ?? '',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Body Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Section
                  Row(
                    children: [
                      _buildStatCard(isBangla ? 'অ্যাকাউন্টস' : 'Accounts', financeProvider.accounts.length.toString(), Icons.account_balance_wallet_rounded, const Color(0xFF6366F1), isDark),
                      const SizedBox(width: 16),
                      _buildStatCard(isBangla ? 'লেনদেন' : 'Activities', financeProvider.transactions.length.toString(), Icons.swap_vert_rounded, const Color(0xFF10B981), isDark),
                    ],
                  ),
                  const SizedBox(height: 32),

                  _buildSectionLabel(isBangla ? 'ব্যক্তিগত বিবরণ' : 'Personal Details', isDark),
                  _buildSettingsGroup([
                    _buildProfessionalTile(
                      icon: Icons.alternate_email_rounded,
                      title: isBangla ? 'ইমেইল আইডি' : 'Email ID',
                      subtitle: authProvider.user?.email ?? '',
                      iconColor: const Color(0xFFEF4444),
                      isDark: isDark,
                    ),
                    _buildProfessionalTile(
                      icon: Icons.event_available_rounded,
                      title: isBangla ? 'যোগদানের সময়' : 'Joined Since',
                      subtitle: authProvider.userModel != null 
                        ? DateFormat.yMMMMd(locale == 'bn' ? 'bn_BD' : 'en_US').format(authProvider.userModel!.createdAt)
                        : '',
                      iconColor: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                  ], isDark),

                  const SizedBox(height: 24),
                  _buildSectionLabel(isBangla ? 'অ্যাকাউন্ট অ্যাকশন' : 'Account Actions', isDark),
                  _buildSettingsGroup([
                    _buildProfessionalTile(
                      icon: Icons.vpn_key_rounded,
                      title: isBangla ? 'পাসওয়ার্ড পরিবর্তন' : 'Change Password',
                      subtitle: isBangla ? 'লিঙ্ক ইমেইলে পাঠানো হবে' : 'Get reset link in your email',
                      iconColor: const Color(0xFF3B82F6),
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        authProvider.resetPassword(authProvider.user!.email!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isBangla ? 'রিসেট ইমেইল পাঠানো হয়েছে' : 'Reset email has been sent'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.blue,
                          )
                        );
                      },
                    ),
                    _buildProfessionalTile(
                      icon: Icons.power_settings_new_rounded,
                      title: AppTranslations.translate('logout', locale),
                      subtitle: isBangla ? 'সেশন শেষ করে বের হোন' : 'Sign out securely',
                      iconColor: const Color(0xFFF43F5E),
                      isDark: isDark,
                      onTap: () => _showLogoutDialog(context, authProvider, isBangla),
                    ),
                  ], isDark),
                  
                  const SizedBox(height: 40),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Messmate & Finance',
                          style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version 1.2.0 (Stable)',
                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                      ],
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 16),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E293B))),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600)),
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
        style: TextStyle(
          fontSize: 11, 
          fontWeight: FontWeight.w800, 
          color: isDark ? const Color(0xFF6366F1).withOpacity(0.8) : Colors.blueGrey, 
          letterSpacing: 1.5
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withOpacity(0.03),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1E293B))),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500)),
      trailing: onTap != null ? Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]) : null,
    );
  }

  void _showImagePickerDialog(AuthProvider authProvider) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text(
              Provider.of<SettingsProvider>(context, listen: false).locale.languageCode == 'bn' 
                ? 'ছবি পরিবর্তন করুন' : 'Update Photo',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(Icons.camera_alt_rounded, 'Camera', ImageSource.camera, authProvider),
                _buildPickerOption(Icons.photo_library_rounded, 'Gallery', ImageSource.gallery, authProvider),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption(IconData icon, String label, ImageSource source, AuthProvider authProvider) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _pickImage(source, authProvider);
      },
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF6366F1), size: 32),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider, bool isBangla) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(isBangla ? 'লগআউট নিশ্চিত করুন' : 'Confirm Logout', style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          isBangla ? 'আপনি কি আপনার অ্যাকাউন্ট থেকে বের হয়ে যেতে চান?' : 'Are you sure you want to sign out of your account?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: Text(isBangla ? 'না' : 'Cancel', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold))
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await authProvider.signOut();
                if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF43F5E),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(isBangla ? 'হ্যাঁ, বের হন' : 'Logout', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
