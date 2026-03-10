import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/mess_market_expense.dart';
import '../models/mess_meal.dart';
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

    final primaryColor = isDark ? const Color(0xFF6366F1) : const Color(0xFF4F46E5);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () => financeProvider.loadUserData(authProvider.user!.uid),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Professional App Bar
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        primaryColor.withValues(alpha: 0.2),
                        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      ],
                    ),
                  ),
                ),
                titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBangla ? 'শুভ দিন 👋' : 'Good Day 👋',
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          displayName,
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                      child: Hero(
                        tag: 'profile_pic',
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: primaryColor.withValues(alpha: 0.5), width: 1.5),
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                            backgroundImage: authProvider.userModel?.photoURL != null 
                              ? NetworkImage(authProvider.userModel!.photoURL!) 
                              : null,
                            child: authProvider.userModel?.photoURL == null 
                              ? Icon(Icons.person, size: 20, color: primaryColor) 
                              : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Premium Dashboard Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark 
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [primaryColor, primaryColor.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: isDark ? 0.1 : 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          AppTranslations.translate('total_balance', locale).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${settings.currencySymbol}${financeProvider.totalBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildModernStat(Icons.arrow_downward_rounded, const Color(0xFF34D399), isBangla ? 'আয়' : 'Income', '${settings.currencySymbol}${financeProvider.totalIncome}'),
                          Container(width: 1, height: 35, color: Colors.white.withValues(alpha: 0.2)),
                          _buildModernStat(Icons.arrow_upward_rounded, const Color(0xFFFB7185), isBangla ? 'ব্যয়' : 'Expense', '${settings.currencySymbol}${financeProvider.totalExpense}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Mess Quick Summary
            if (financeProvider.messMembers.any((m) => m.appUserId == authProvider.user?.uid))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(isBangla ? 'মেস আপডেট (আজ)' : 'Mess Update (Today)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Icon(Icons.restaurant_menu_rounded, color: Colors.orangeAccent, size: 20),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildQuickMessItem(isBangla ? 'বাজার খরচ' : 'Market', '${settings.currencySymbol}${financeProvider.messMarketExpenses.where((e) => e.date.day == DateTime.now().day && e.status == ExpenseStatus.approved).fold(0.0, (sum, e) => sum + e.amount).toStringAsFixed(0)}', isDark),
                            _buildQuickMessItem(isBangla ? 'মোট মিল' : 'Total Meals', financeProvider.messMeals.where((m) => m.date.day == DateTime.now().day).fold(0.0, (sum, m) => sum + m.count).toStringAsFixed(1), isDark),
                            _buildQuickMessItem(isBangla ? 'আপনার মিল' : 'Your Meal', financeProvider.messMeals.where((m) => m.date.day == DateTime.now().day && m.appUserId == authProvider.user?.uid).fold(0.0, (sum, m) => sum + m.count).toStringAsFixed(1), isDark),
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showQuickAdd(context),
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.add_rounded, size: 28),
          label: Text(
            isBangla ? 'নতুন যোগ করুন' : 'Add New',
            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildQuickMessItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
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
      width: 150,
      margin: const EdgeInsets.only(right: 16, bottom: 8, top: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF6366F1), size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                acc.name, 
                style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.bold), 
                overflow: TextOverflow.ellipsis
              ),
              const SizedBox(height: 4),
              Text(
                '$currency${acc.balance}', 
                style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w900, fontSize: 16)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(dynamic t, String currency, bool isDark) {
    final isIncome = t.type == TransactionType.income;
    final color = isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              isIncome ? Icons.keyboard_double_arrow_down_rounded : Icons.keyboard_double_arrow_up_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.translate(t.category, 'en'), 
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1E293B), 
                    fontWeight: FontWeight.bold, 
                    fontSize: 15
                  )
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM, yyyy').format(t.date), 
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}$currency${t.amount}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, bool isDark) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.receipt_long_rounded, size: 50, color: Colors.grey.withValues(alpha: 0.3)),
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
                _buildQuickAction(context, Icons.group_add_rounded, Colors.indigoAccent, isBangla ? 'মেস' : 'Mess', () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/mess');
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
                color: color.withValues(alpha: 0.1),
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
