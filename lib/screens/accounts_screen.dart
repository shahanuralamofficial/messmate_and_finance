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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          AppTranslations.translate('accounts', locale),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showAddAccount(context);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTotalAssetsCard(isDark, isBangla, settings.currencySymbol, financeProvider.totalBalance),
            const SizedBox(height: 24),
            Text(
              isBangla ? '${financeProvider.accounts.length}টি অ্যাকাউন্ট' : '${financeProvider.accounts.length} Accounts Active',
              style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1),
            ),
            const SizedBox(height: 16),
            if (financeProvider.accounts.isEmpty)
              _buildEmptyState(isBangla ? 'কোন অ্যাকাউন্ট পাওয়া যায়নি' : 'No accounts found', isDark)
            else
              ...financeProvider.accounts.map((account) => _buildProfessionalAccountTile(context, account, isDark, settings.currencySymbol, financeProvider, authProvider.user!.uid)),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showAddAccount(context);
        },
        label: Text(isBangla ? 'নতুন অ্যাকাউন্ট' : 'Add Account'),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildTotalAssetsCard(bool isDark, bool isBangla, String symbol, double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(isBangla ? 'মোট সম্পদ' : 'Total Net Worth', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          const SizedBox(height: 8),
          Text('$symbol${total.toStringAsFixed(2)}', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 32, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildProfessionalAccountTile(BuildContext context, dynamic account, bool isDark, String symbol, FinanceProvider fp, String uid) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _getAccountColor(account.type).withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
          child: Icon(_getAccountIcon(account.type), color: _getAccountColor(account.type), size: 24),
        ),
        title: Text(account.name, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(AppTranslations.translate(account.type, 'en'), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$symbol${account.balance}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.blueAccent)),
            const SizedBox(width: 8),
            PopupMenuButton(
              icon: Icon(Icons.more_vert, color: Colors.grey[400]),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              itemBuilder: (ctx) => [
                PopupMenuItem(child: const ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit')), onTap: () => Future.delayed(Duration.zero, () => _showAddAccount(context, account: account))),
                PopupMenuItem(child: const ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red))), onTap: () => fp.deleteAccount(uid, account.id)),
              ],
            ),
          ],
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
    if (type.contains('bank')) return Colors.blue;
    if (type.contains('card')) return Colors.orange;
    if (type.contains('mobile')) return Colors.pink;
    return Colors.green;
  }

  Widget _buildEmptyState(String message, bool isDark) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.account_balance_wallet_outlined, size: 60, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  void _showAddAccount(BuildContext context, {dynamic account}) {
    showDialog(context: context, builder: (context) => AddAccountDialog(account: account));
  }
}
