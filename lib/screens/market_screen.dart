import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/translations.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/add_market_item_dialog.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  void _showAddItemDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog(context: context, builder: (_) => const AddMarketItemDialog());
  }

  void _convertToExpense(BuildContext context) {
    HapticFeedback.mediumImpact();
    final financeProvider = Provider.of<FinanceProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final locale = settings.locale.languageCode;
    final purchasedItems = financeProvider.marketItems.where((item) => item.isPurchased).toList();

    if (purchasedItems.isEmpty) return;

    final totalCost = purchasedItems.fold<double>(0, (sum, item) => sum + item.price);
    
    showDialog(
      context: context,
      builder: (ctx) {
        String? selectedAccountId;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(AppTranslations.translate('convert_to_expense', locale), style: const TextStyle(fontWeight: FontWeight.bold)),
          content: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
            hint: Text(locale == 'bn' ? 'অ্যাকাউন্ট নির্বাচন করুন' : 'Select Account'),
            items: financeProvider.accounts.map((acc) => DropdownMenuItem(value: acc.id, child: Text(acc.name))).toList(),
            onChanged: (val) => selectedAccountId = val,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(locale == 'bn' ? 'বাতিল' : 'Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                if (selectedAccountId != null) {
                  final newTransaction = Transaction(
                    id: const Uuid().v4(),
                    userId: authProvider.user!.uid,
                    title: locale == 'bn' ? 'বাজার খরচ' : 'Market Expense',
                    type: TransactionType.expense,
                    amount: totalCost,
                    category: 'market', 
                    date: DateTime.now(),
                    accountId: selectedAccountId,
                    note: 'Market purchase conversion',
                  );
                  financeProvider.addTransaction(newTransaction);
                  for (var item in purchasedItems) {
                    financeProvider.deleteMarketItem(authProvider.user!.uid, item.id);
                  }
                  Navigator.pop(ctx);
                }
              },
              child: Text(locale == 'bn' ? 'কনভার্ট' : 'Convert', style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final financeProvider = Provider.of<FinanceProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final locale = settings.locale.languageCode;
    final isBangla = locale == 'bn';
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(AppTranslations.translate('market_list', locale), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), // Reduced top padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isBangla ? '${financeProvider.marketItems.length}টি আইটেম' : '${financeProvider.marketItems.length} Items Listed',
                  style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600),
                ),
                if (financeProvider.marketItems.any((i) => i.isPurchased))
                  TextButton.icon(
                    onPressed: () => _convertToExpense(context),
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                    label: Text(isBangla ? 'খরচে রূপান্তর' : 'Sync to Expense'),
                    style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (financeProvider.marketItems.isEmpty)
              _buildEmptyState(isBangla ? 'বাজার তালিকা খালি' : 'Market list is empty', isDark)
            else
              ...financeProvider.marketItems.map((item) => _buildProfessionalMarketTile(item, authProvider.user!.uid, financeProvider, isDark, settings.currencySymbol)),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context),
        label: Text(isBangla ? 'আইটেম যোগ করুন' : 'Add Item'),
        icon: const Icon(Icons.add_shopping_cart_rounded),
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildProfessionalMarketTile(dynamic item, String uid, FinanceProvider fp, bool isDark, String symbol) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Checkbox(
          value: item.isPurchased,
          activeColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          onChanged: (v) {
            HapticFeedback.selectionClick();
            fp.togglePurchased(uid, item.id);
          },
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: item.isPurchased ? TextDecoration.lineThrough : null,
            color: item.isPurchased ? Colors.grey : (isDark ? Colors.white : Colors.black87),
          ),
        ),
        subtitle: Text('${item.quantity} ${item.unit}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$symbol${item.price}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 20),
              onPressed: () {
                HapticFeedback.vibrate();
                fp.deleteMarketItem(uid, item.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, bool isDark) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}
