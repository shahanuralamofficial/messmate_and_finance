import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/translations.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/add_account_dialog.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final financeProvider = Provider.of<FinanceProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final locale = settings.locale.languageCode;
    final isBangla = locale == 'bn';
    final isDark = themeProvider.isDarkMode;

    final primaryColor = isDark ? const Color(0xFF6366F1) : const Color(0xFF4F46E5);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          AppTranslations.translate('accounts', locale),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: 0.5),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
        elevation: 0,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withValues(alpha: 0.15),
              isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 120, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTotalAssetsCard(isDark, isBangla, settings.currencySymbol, financeProvider.totalBalance, primaryColor),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isBangla ? 'আপনার অ্যাকাউন্টসমূহ' : 'Your Accounts',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isBangla ? '${financeProvider.accounts.length}টি' : '${financeProvider.accounts.length} Total',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (financeProvider.accounts.isEmpty)
                _buildEmptyState(isBangla ? 'কোন অ্যাকাউন্ট পাওয়া যায়নি' : 'No accounts found', isDark)
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: financeProvider.accounts.length,
                  itemBuilder: (context, index) {
                    final account = financeProvider.accounts[index];
                    return _buildProfessionalAccountTile(
                      context, 
                      account, 
                      isDark, 
                      settings.currencySymbol, 
                      financeProvider, 
                      authProvider.user!.uid,
                      primaryColor
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            HapticFeedback.mediumImpact();
            _showAddAccount(context);
          },
          label: Text(isBangla ? 'নতুন অ্যাকাউন্ট' : 'Add Account', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          icon: const Icon(Icons.add_rounded, size: 26),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildTotalAssetsCard(bool isDark, bool isBangla, String symbol, double total, Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isBangla ? 'মোট সম্পদ' : 'NET WORTH',
              style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 4),
                child: Text(symbol, style: TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.w600)),
              ),
              Text(
                total.toStringAsFixed(2),
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalAccountTile(BuildContext context, dynamic account, bool isDark, String symbol, FinanceProvider fp, String uid, Color primaryColor) {
    final accountColor = _getAccountColor(account.type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showAddAccount(context, account: account),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accountColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(_getAccountIcon(account.type), color: accountColor, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppTranslations.translate(account.type, 'en').toUpperCase(),
                        style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$symbol${account.balance}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    PopupMenuButton(
                      icon: Icon(Icons.more_horiz_rounded, color: Colors.grey[400], size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 120),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          onTap: () => fp.deleteAccount(uid, account.id),
                          child: const Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red, fontSize: 14))]), 
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getAccountIcon(String type) {
    if (type.contains('bank')) return Icons.account_balance_rounded;
    if (type.contains('card')) return Icons.credit_card_rounded;
    if (type.contains('mobile')) return Icons.phone_android_rounded;
    return Icons.wallet_rounded;
  }

  Color _getAccountColor(String type) {
    if (type.contains('bank')) return const Color(0xFF3B82F6);
    if (type.contains('card')) return const Color(0xFFF59E0B);
    if (type.contains('mobile')) return const Color(0xFFEC4899);
    return const Color(0xFF10B981);
  }

  Widget _buildEmptyState(String message, bool isDark) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance_wallet_outlined, size: 60, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showAddAccount(BuildContext context, {dynamic account}) {
    showDialog(context: context, builder: (context) => AddAccountDialog(account: account));
  }
}
