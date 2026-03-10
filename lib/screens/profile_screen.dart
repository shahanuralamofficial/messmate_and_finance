import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/finance_provider.dart';
import '../utils/translations.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // Optional: if provided, show that user's profile

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianPhoneController = TextEditingController();
  final _relationController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  UserModel? _viewedUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (widget.userId != null && widget.userId != authProvider.user?.uid) {
      setState(() => _isLoading = true);
      _viewedUser = await authProvider.getUserById(widget.userId!);
      setState(() => _isLoading = false);
    } else {
      _viewedUser = authProvider.userModel;
      if (_viewedUser != null) {
        _nameController.text = _viewedUser!.displayName ?? '';
        _phoneController.text = _viewedUser!.phoneNumber ?? '';
        _guardianNameController.text = _viewedUser!.guardianName ?? '';
        _guardianPhoneController.text = _viewedUser!.guardianPhone ?? '';
        _relationController.text = _viewedUser!.guardianRelation ?? '';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile(AuthProvider authProvider) async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    try {
      await authProvider.updateProfile({
        'displayName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'guardianName': _guardianNameController.text.trim(),
        'guardianPhone': _guardianPhoneController.text.trim(),
        'guardianRelation': _relationController.text.trim(),
      });
      if (mounted) {
        final locale = Provider.of<SettingsProvider>(context, listen: false).locale.languageCode;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(locale == 'bn' ? 'প্রোফাইল আপডেট হয়েছে' : 'Profile Updated Successfully'), backgroundColor: Colors.green)
        );
        _loadUserData();
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
        _loadUserData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
    
    final bool isMyProfile = widget.userId == null || widget.userId == authProvider.user?.uid;
    final primaryColor = isDark ? const Color(0xFF6366F1) : const Color(0xFF4F46E5);

    if (_isLoading && _viewedUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
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
              if (isMyProfile)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: Icon(_isEditing ? Icons.check_circle_rounded : Icons.edit_note_rounded, color: primaryColor, size: 28),
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      if (_isEditing) await _updateProfile(authProvider);
                      setState(() => _isEditing = !_isEditing);
                    },
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [primaryColor.withValues(alpha: isDark ? 0.3 : 0.2), isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)],
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
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primaryColor.withValues(alpha: 0.5), width: 2)),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              backgroundImage: _viewedUser?.photoURL != null ? NetworkImage(_viewedUser!.photoURL!) : null,
                              child: _viewedUser?.photoURL == null
                                  ? Text((_viewedUser?.displayName?.isNotEmpty == true ? _viewedUser!.displayName![0] : _viewedUser?.email[0] ?? 'U').toUpperCase(),
                                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: primaryColor))
                                  : null,
                            ),
                          ),
                          if (isMyProfile)
                            GestureDetector(
                              onTap: () => _showImagePickerDialog(authProvider),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle, border: Border.all(color: isDark ? const Color(0xFF0F172A) : Colors.white, width: 3)),
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
                            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 22, fontWeight: FontWeight.w800),
                            decoration: InputDecoration(hintText: isBangla ? 'নাম লিখুন' : 'Enter Name'),
                          ),
                        )
                      else
                        Text(_viewedUser?.displayName ?? (isBangla ? 'ব্যবহারকারী' : 'User'),
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                      Text(_viewedUser?.email ?? '', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isMyProfile) ...[
                    Row(
                      children: [
                        _buildStatCard(isBangla ? 'অ্যাকাউন্টস' : 'Accounts', financeProvider.accounts.length.toString(), Icons.account_balance_wallet_rounded, const Color(0xFF6366F1), isDark),
                        const SizedBox(width: 16),
                        _buildStatCard(isBangla ? 'লেনদেন' : 'Activities', financeProvider.transactions.length.toString(), Icons.swap_vert_rounded, const Color(0xFF10B981), isDark),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],

                  _buildSectionLabel(isBangla ? 'ব্যক্তিগত তথ্য' : 'Personal Info', isDark),
                  _buildSettingsGroup([
                    if (_isEditing) ...[
                      _buildEditField(_phoneController, isBangla ? 'ফোন নম্বর' : 'Phone Number', Icons.phone, isDark),
                    ] else ...[
                      _buildProfessionalTile(
                        icon: Icons.phone,
                        title: isBangla ? 'ফোন নম্বর' : 'Phone Number',
                        subtitle: _viewedUser?.phoneNumber ?? (isBangla ? 'দেওয়া হয়নি' : 'Not set'),
                        iconColor: Colors.blue,
                        isDark: isDark,
                      ),
                    ],
                  ], isDark),

                  const SizedBox(height: 24),
                  _buildSectionLabel(isBangla ? 'অভিভাবকের তথ্য (Emergency)' : 'Guardian Info', isDark),
                  _buildSettingsGroup([
                    if (_isEditing) ...[
                      _buildEditField(_guardianNameController, isBangla ? 'অভিভাবকের নাম' : 'Guardian Name', Icons.person_pin, isDark),
                      _buildEditField(_relationController, isBangla ? 'সম্পর্ক' : 'Relation', Icons.family_restroom, isDark),
                      _buildEditField(_guardianPhoneController, isBangla ? 'অভিভাবকের ফোন' : 'Guardian Phone', Icons.phone_android, isDark),
                    ] else ...[
                      _buildProfessionalTile(
                        icon: Icons.person_pin,
                        title: isBangla ? 'অভিভাবকের নাম' : 'Guardian Name',
                        subtitle: _viewedUser?.guardianName ?? (isBangla ? 'দেওয়া হয়নি' : 'Not set'),
                        iconColor: Colors.orange,
                        isDark: isDark,
                      ),
                      _buildProfessionalTile(
                        icon: Icons.family_restroom,
                        title: isBangla ? 'সম্পর্ক' : 'Relation',
                        subtitle: _viewedUser?.guardianRelation ?? (isBangla ? 'দেওয়া হয়নি' : 'Not set'),
                        iconColor: Colors.purple,
                        isDark: isDark,
                      ),
                      _buildProfessionalTile(
                        icon: Icons.phone_android,
                        title: isBangla ? 'অভিভাবকের ফোন' : 'Guardian Phone',
                        subtitle: _viewedUser?.guardianPhone ?? (isBangla ? 'দেওয়া হয়নি' : 'Not set'),
                        iconColor: Colors.green,
                        isDark: isDark,
                        onTap: _viewedUser?.guardianPhone != null ? () => _makePhoneCall(_viewedUser!.guardianPhone!) : null,
                      ),
                    ],
                  ], isDark),

                  if (isMyProfile) ...[
                    const SizedBox(height: 24),
                    _buildSectionLabel(isBangla ? 'অ্যাকাউন্ট অ্যাকশন' : 'Account Actions', isDark),
                    _buildSettingsGroup([
                      _buildProfessionalTile(
                        icon: Icons.power_settings_new_rounded,
                        title: AppTranslations.translate('logout', locale),
                        subtitle: isBangla ? 'সেশন শেষ করে বের হোন' : 'Sign out securely',
                        iconColor: const Color(0xFFF43F5E),
                        isDark: isDark,
                        onTap: () => _showLogoutDialog(context, authProvider, isBangla),
                      ),
                    ], isDark),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(TextEditingController controller, String label, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    // In a real app, use url_launcher
    debugPrint('Calling $phoneNumber...');
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(28)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 16),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E293B))),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF6366F1) : Colors.blueGrey, letterSpacing: 1.5)),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(children: children),
    );
  }

  Widget _buildProfessionalTile({required IconData icon, required String title, required String subtitle, required Color iconColor, required bool isDark, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 20)),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      trailing: onTap != null ? const Icon(Icons.call, size: 18, color: Colors.green) : null,
    );
  }

  void _showImagePickerDialog(AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera, authProvider); }),
          ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery, authProvider); }),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider, bool isBangla) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBangla ? 'লগআউট' : 'Logout'),
        content: Text(isBangla ? 'আপনি কি নিশ্চিত?' : 'Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBangla ? 'না' : 'No')),
          ElevatedButton(onPressed: () { Navigator.pop(ctx); authProvider.signOut(); Navigator.pushReplacementNamed(context, '/login'); }, child: Text(isBangla ? 'হ্যাঁ' : 'Yes')),
        ],
      ),
    );
  }
}
