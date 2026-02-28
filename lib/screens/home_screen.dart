import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/finance_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/translations.dart';
import '../widgets/add_transaction_dialog.dart';
import '../models/transaction.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final financeProvider = Provider.of<FinanceProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final locale = settings.locale.languageCode;
    final isBangla = locale == 'bn';
    final isDark = themeProvider.isDarkMode;

    // Fallback name logic: DB name > Auth profile name > Default 'User'
    final String displayName = authProvider.userModel?.displayName ?? 
                               authProvider.user?.displayName ?? 
                               (isBangla ? 'ব্যবহারকারী' : 'User');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () => financeProvider.loadUserData(authProvider.user!.uid),
        child: CustomScrollView(
          slivers: [
            // Professional App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: isDark ? const Color(0xFF38BDF8) : Colors.black87,
                  size: 30,
                ),
              ),
              leadingWidth: 54,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBangla ? 'শুভ দিন 👋' : 'Good Day 👋',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                  Text(
                    displayName,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: authProvider.userModel?.photoURL != null 
                        ? NetworkImage(authProvider.userModel!.photoURL!) 
                        : null,
                      child: authProvider.userModel?.photoURL == null 
                        ? const Icon(Icons.person, size: 20, color: Colors.blueAccent) 
                        : null,
                    ),
                  ),
                ),
              ],
            ),

            // Premium Dashboard Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark 
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFF0F172A), const Color(0xFF334155)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : Colors.blueAccent).withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppTranslations.translate('total_balance', locale),
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, letterSpacing: 1),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${settings.currencySymbol}${financeProvider.totalBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildModernStat(Icons.arrow_downward_rounded, Colors.greenAccent, isBangla ? 'আয়' : 'Income', '${settings.currencySymbol}${financeProvider.totalIncome}'),
                          Container(width: 1, height: 40, color: Colors.white24),
                          _buildModernStat(Icons.arrow_upward_rounded, Colors.redAccent, isBangla ? 'ব্যয়' : 'Expense', '${settings.currencySymbol}${financeProvider.totalExpense}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Accounts Horizontal List
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppTranslations.translate('accounts', locale),
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/accounts'),
                          child: Text(isBangla ? 'সব দেখুন' : 'See All', style: const TextStyle(color: Colors.blueAccent)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 130,
                    child: financeProvider.accounts.isEmpty 
                      ? Center(child: Text(isBangla ? 'অ্যাকাউন্ট যোগ করুন' : 'No accounts active', style: const TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: financeProvider.accounts.length,
                          itemBuilder: (ctx, i) {
                            final acc = financeProvider.accounts[i];
                            return _buildAccountCard(acc, settings.currencySymbol, isDark);
                          },
                        ),
                  ),
                ],
              ),
            ),

            // Recent Transactions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isBangla ? 'সাম্প্রতিক লেনদেন' : 'Recent Activities',
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/reports'),
                          child: Text(isBangla ? 'সব দেখুন' : 'See All', style: const TextStyle(color: Colors.blueAccent)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (financeProvider.transactions.isEmpty)
                      _buildEmptyState(isBangla ? 'কোন লেনদেন নেই' : 'No recent activities found', isDark)
                    else
                      ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: financeProvider.transactions.take(5).length,
                        itemBuilder: (ctx, i) {
                          final t = financeProvider.transactions[i];
                          return _buildTransactionTile(t, settings.currencySymbol, isDark);
                        },
                      ),
                  ],
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickAdd(context),
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          isBangla ? 'নতুন যোগ করুন' : 'Add New',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildModernStat(IconData icon, Color color, String label, String value) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAccountCard(dynamic acc, String currency, bool isDark) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12, bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.blueAccent, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(acc.name, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('$currency${acc.balance}', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(dynamic t, String currency, bool isDark) {
    final isIncome = t.type == TransactionType.income;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isIncome ? Colors.greenAccent : Colors.redAccent).withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            isIncome ? Icons.keyboard_double_arrow_down_rounded : Icons.keyboard_double_arrow_up_rounded,
            color: isIncome ? Colors.green : Colors.redAccent,
            size: 20,
          ),
        ),
        title: Text(AppTranslations.translate(t.category, 'en'), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(DateFormat('dd MMM, yyyy').format(t.date), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        trailing: Text(
          '${isIncome ? '+' : '-'}$currency${t.amount}',
          style: TextStyle(
            color: isIncome ? Colors.greenAccent : Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, bool isDark) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.receipt_long_rounded, size: 50, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    );
  }

  void _showQuickAdd(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickAddSheet(),
    );
  }
}

class QuickAddSheet extends StatelessWidget {
  const QuickAddSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final isBangla = settings.locale.languageCode == 'bn';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isBangla ? 'দ্রুত যোগ করুন' : 'Quick Actions', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _buildQuickAction(context, Icons.trending_up_rounded, Colors.greenAccent, isBangla ? 'আয়' : 'Income', () {
                  Navigator.pop(context);
                  showDialog(context: context, builder: (_) => const AddTransactionDialog(type: TransactionType.income));
                }, isDark),
                _buildQuickAction(context, Icons.trending_down_rounded, Colors.redAccent, isBangla ? 'ব্যয়' : 'Expense', () {
                  Navigator.pop(context);
                  showDialog(context: context, builder: (_) => const AddTransactionDialog(type: TransactionType.expense));
                }, isDark),
                _buildQuickAction(context, Icons.shopping_cart_rounded, Colors.orangeAccent, isBangla ? 'বাজার' : 'Market', () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/market');
                }, isDark),
                _buildQuickAction(context, Icons.note_add_rounded, Colors.blueAccent, isBangla ? 'নোট' : 'Notes', () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/notes');
                }, isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, Color color, String label, VoidCallback onTap, bool isDark) {
    double width = (MediaQuery.of(context).size.width - 80) / 3;
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
