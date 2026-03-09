import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/translations.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final locale = settings.locale.languageCode;
    final isBangla = locale == 'bn';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final primaryColor = const Color(0xFF6366F1);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: primaryColor,
            unselectedItemColor: isDark ? Colors.white54 : Colors.grey[500],
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            onTap: (index) {
              if (index == currentIndex) return;
              HapticFeedback.lightImpact();
              switch (index) {
                case 0:
                  Navigator.pushReplacementNamed(context, '/home');
                  break;
                case 1:
                  Navigator.pushReplacementNamed(context, '/accounts');
                  break;
                case 2:
                  Navigator.pushReplacementNamed(context, '/tools');
                  break;
                case 3:
                  Navigator.pushReplacementNamed(context, '/mess');
                  break;
                case 4:
                  Navigator.pushReplacementNamed(context, '/settings');
                  break;
              }
            },
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.grid_view_rounded),
                activeIcon: const Icon(Icons.grid_view_rounded),
                label: AppTranslations.translate('home', locale),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                activeIcon: const Icon(Icons.account_balance_wallet_rounded),
                label: AppTranslations.translate('accounts', locale),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.category_outlined),
                activeIcon: const Icon(Icons.category_rounded),
                label: isBangla ? 'সরঞ্জাম' : 'Tools',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.group_outlined),
                activeIcon: const Icon(Icons.group_rounded),
                label: isBangla ? 'মেস' : 'Mess',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings_outlined),
                activeIcon: const Icon(Icons.settings_rounded),
                label: AppTranslations.translate('settings', locale),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
