import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/export_service.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final isBN = settings.locale.languageCode == 'bn';
    
    final primaryColor = isDark ? const Color(0xFF6366F1) : const Color(0xFF4F46E5);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isBN ? 'সরঞ্জাম' : 'Tools & Services',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: 0.5),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Text(
                isBN ? 'আপনার আর্থিক ব্যবস্থাপনা সহজ করতে নিচের টুলসগুলো ব্যবহার করুন।' : 'Use these powerful tools to manage your finances more effectively.',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.95,
              ),
              delegate: SliverChildListDelegate([
                _buildToolCard(context, Icons.pie_chart_rounded, isBN ? 'বাজেট' : 'Budget', const Color(0xFFF59E0B), '/budgets', isDark),
                _buildToolCard(context, Icons.handshake_rounded, isBN ? 'ধার-দেনা' : 'Debts', const Color(0xFFEF4444), '/debts', isDark),
                _buildToolCard(context, Icons.track_changes_rounded, isBN ? 'সেভিংস গোল' : 'Savings', const Color(0xFF10B981), '/savings', isDark),
                _buildToolCard(context, Icons.repeat_rounded, isBN ? 'অটো বিল' : 'Recurring', const Color(0xFF3B82F6), '/recurring', isDark),
                _buildToolCard(context, Icons.security_rounded, isBN ? 'নিরাপত্তা' : 'Security', const Color(0xFF6366F1), '/security', isDark),
                _buildToolCard(context, Icons.ios_share_rounded, isBN ? 'এক্সপোর্ট' : 'Export', const Color(0xFF06B6D4), () => _showExportDialog(context, isBN), isDark),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildToolCard(BuildContext context, IconData icon, String title, Color color, dynamic action, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
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
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            HapticFeedback.lightImpact();
            if (action is String) {
              Navigator.pushNamed(context, action);
            } else if (action is Function) {
              action();
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context, bool isBN) {
    final fp = Provider.of<FinanceProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text(isBN ? 'ডাটা এক্সপোর্ট করুন' : 'Export Your Data', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.description_rounded, color: Colors.green),
              ),
              title: Text(isBN ? 'লেনদেন (CSV)' : 'Transactions (CSV)', style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                ExportService.exportTransactionsToCSV(fp.transactions, fp.accounts);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.handshake_rounded, color: Colors.red),
              ),
              title: Text(isBN ? 'ধার-দেনা (CSV)' : 'Debts (CSV)', style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                ExportService.exportDebtsToCSV(fp.debts);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
