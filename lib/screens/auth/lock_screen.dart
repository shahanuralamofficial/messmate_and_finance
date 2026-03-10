import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import '../../providers/settings_provider.dart';
import '../../utils/translations.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pinController = TextEditingController();
  String _errorText = '';
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      if (settings.biometricEnabled) {
        _authenticateWithBiometrics();
      }
    });
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) return;

      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final locale = settings.locale.languageCode;

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: AppTranslations.translate('unlock_with_biometrics', locale),
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (didAuthenticate) {
        _unlock();
      }
    } catch (e) {
      debugPrint('Biometric Error: $e');
    }
  }

  void _checkPin() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (_pinController.text == settings.pinCode) {
      _unlock();
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _errorText = AppTranslations.translate('incorrect_pin', settings.locale.languageCode);
        _pinController.clear();
      });
    }
  }

  void _unlock() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final locale = settings.locale.languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center( // Added Center to wrap the Column
          child: SingleChildScrollView( // To prevent overflow
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center, // Ensure center alignment
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline_rounded, size: 60, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppTranslations.translate('enter_pin_to_unlock', locale),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 250,
                    child: TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        errorText: _errorText.isEmpty ? null : _errorText,
                      ),
                      onChanged: (value) {
                        if (value.length == settings.pinCode?.length) {
                          _checkPin();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (settings.biometricEnabled)
                    InkWell(
                      onTap: _authenticateWithBiometrics,
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.fingerprint_rounded, size: 40, color: Colors.blueAccent),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
