import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/bottom_nav_bar.dart';

import '../services/export_service.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isBN = settings.locale.languageCode == 'bn';

    return Scaffold(
      appBar: AppBar(
        title: Text(isBN ? 'সরঞ্জাম' : 'Tools'),
        elevation: 0,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildToolCard(
            context,
            Icons.pie_chart_outline_rounded,
            isBN ? 'বাজেট' : 'Budget',
            Colors.orange,
            '/budgets',
          ),
          _buildToolCard(
            context,
            Icons.handshake_outlined,
            isBN ? 'ধার-দেনা' : 'Debts',
            Colors.redAccent,
            '/debts',
          ),
          _buildToolCard(
            context,
            Icons.track_changes_rounded,
            isBN ? 'সেভিংস গোল' : 'Savings Goals',
            Colors.green,
            '/savings',
          ),
          _buildToolCard(
            context,
            Icons.repeat_rounded,
            isBN ? 'অটো বিল' : 'Recurring',
            Colors.blue,
            '/recurring',
          ),
          _buildToolCard(
            context,
            Icons.lock_outline_rounded,
            isBN ? 'নিরাপত্তা' : 'Security',
            Colors.indigo,
            '/security',
          ),
          _buildToolCard(
            context,
            Icons.table_view_rounded,
            isBN ? 'এক্সপোর্ট' : 'Export',
            Colors.teal,
            () => _showExportDialog(context, isBN),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2), // Assuming 2 is Tools
    );
  }

  Widget _buildToolCard(BuildContext context, IconData icon, String title, Color color, dynamic action) {
    return InkWell(
      onTap: () {
        if (action is String) {
          Navigator.pushNamed(context, action);
        } else if (action is Function) {
          action();
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color.darken(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context, bool isBN) {
    final fp = Provider.of<FinanceProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBN ? 'ডাটা এক্সপোর্ট' : 'Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.green),
              title: Text(isBN ? 'লেনদেন (CSV)' : 'Transactions (CSV)'),
              onTap: () {
                ExportService.exportTransactionsToCSV(fp.transactions, fp.accounts);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.handshake, color: Colors.red),
              title: Text(isBN ? 'ধার-দেনা (CSV)' : 'Debts (CSV)'),
              onTap: () {
                ExportService.exportDebtsToCSV(fp.debts);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
