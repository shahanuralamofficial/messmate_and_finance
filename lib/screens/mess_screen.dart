
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/mess_meal_plan.dart';
import '../providers/finance_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../models/mess_member.dart';
import '../models/mess_meal.dart';
import '../models/mess_market_expense.dart';
import '../utils/mess_report_helper.dart';

class MessScreen extends StatefulWidget {
  const MessScreen({super.key});

  @override
  State<MessScreen> createState() => _MessScreenState();
}

class _MessScreenState extends State<MessScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final financeProvider = Provider.of<FinanceProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final locale = settings.locale.languageCode;
    final isBN = locale == 'bn';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isBN ? 'মেস ম্যানেজার' : 'Mess Manager', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: () => MessReportHelper.generateAndPrintReport(
              messName: isBN ? 'আমার মেস' : 'My Mess',
              members: financeProvider.messMembers,
              expenses: financeProvider.messMarketExpenses,
              totalMeals: financeProvider.totalMessMeals,
              totalCost: financeProvider.totalMessMarketCost,
              mealRate: financeProvider.mealRate,
              currency: settings.currencySymbol,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          tabs: [
            Tab(text: isBN ? 'সদস্য' : 'Members'),
            Tab(text: isBN ? 'খরচ' : 'Expenses'),
            Tab(text: isBN ? 'ইতিহাস' : 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMembersTab(financeProvider, authProvider, isBN, isDark, settings.currencySymbol),
          _buildExpensesTab(financeProvider, isBN, isDark, settings.currencySymbol),
          _buildLogsTab(financeProvider, isBN, isDark),
        ],
      ),
    );
  }

  Widget _buildMembersTab(FinanceProvider fp, AuthProvider auth, bool isBN, bool isDark, String symbol) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildOverviewCard(fp, isBN, isDark, symbol),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isBN ? 'সদস্যবৃন্দ' : 'Members', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () => _showAddMemberDialog(context, auth.user!.uid, fp, isBN),
                icon: const Icon(Icons.person_add_alt_1),
                label: Text(isBN ? 'সদস্য যোগ' : 'Add Member'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (fp.messMembers.isEmpty)
            _buildEmptyState(isBN ? 'কোন সদস্য নেই' : 'No members found', isDark)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: fp.messMembers.length,
              itemBuilder: (context, index) {
                final member = fp.messMembers[index];
                return _buildMemberTile(member, fp, isBN, isDark, symbol);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildExpensesTab(FinanceProvider fp, bool isBN, bool isDark, String symbol) {
    if (fp.messMarketExpenses.isEmpty) {
      return _buildEmptyState(isBN ? 'কোন খরচ নেই' : 'No expenses recorded', isDark);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: fp.messMarketExpenses.length,
      itemBuilder: (context, index) {
        final expense = fp.messMarketExpenses[index];
        return Card(
          elevation: 0,
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.orangeAccent, child: Icon(Icons.shopping_bag, color: Colors.white)),
            title: Text(expense.description, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${expense.memberName} • ${DateFormat('dd MMM').format(expense.date)}'),
            trailing: Text('$symbol${expense.amount}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildLogsTab(FinanceProvider fp, bool isBN, bool isDark) {
    if (fp.messLogs.isEmpty) {
      return _buildEmptyState(isBN ? 'ইতিহাস খালি' : 'No activity logs', isDark);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: fp.messLogs.length,
      itemBuilder: (context, index) {
        final log = fp.messLogs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('HH:mm').format(log.timestamp), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
                        children: [
                          TextSpan(text: log.actorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: ' ${log.action}: '),
                          TextSpan(text: log.details, style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(DateFormat('dd MMM, yyyy').format(log.timestamp), style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(FinanceProvider fp, bool isBN, bool isDark, String symbol) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(isBN ? 'মোট বাজার' : 'Total Market', '$symbol${fp.totalMessMarketCost.toStringAsFixed(0)}', Colors.white),
              _buildStatItem(isBN ? 'মোট মিল' : 'Total Meals', fp.totalMessMeals.toStringAsFixed(1), Colors.white),
            ],
          ),
          const Divider(color: Colors.white24, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(isBN ? 'মিল রেট' : 'Meal Rate', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  Text('$symbol${fp.mealRate.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMemberTile(MessMember member, FinanceProvider fp, bool isBN, bool isDark, String symbol) {
    final double cost = member.totalMeals * fp.mealRate;
    final double balance = member.initialDeposit - cost;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: Colors.blueAccent.withOpacity(0.1), child: Text(member.name[0], style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (member.isManager) Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: const Text('MGR', style: TextStyle(color: Colors.orangeAccent, fontSize: 8, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    Text('${isBN ? 'মিল' : 'Meals'}: ${member.totalMeals}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$symbol${balance.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: balance >= 0 ? Colors.green : Colors.redAccent)),
                  Text(balance >= 0 ? (isBN ? 'পাবে' : 'Balance') : (isBN ? 'দেবে' : 'Due'), style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                ],
              ),
              IconButton(icon: const Icon(Icons.more_vert), onPressed: () => _showMemberOptions(member, fp, isBN)),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionBtn(Icons.calendar_month_outlined, isBN ? 'মিলের প্ল্যান' : 'Meal Plan', () => _showMealPlanDialog(member, fp, isBN)),
              _buildActionBtn(Icons.shopping_cart_outlined, isBN ? 'বাজার' : 'Market', () => _showAddMarketDialog(member, fp, isBN)),
              _buildActionBtn(Icons.receipt_long_outlined, isBN ? 'বিল' : 'Bills', () => _showEditBillsDialog(member, fp, isBN)),
              _buildActionBtn(Icons.account_balance_wallet_outlined, isBN ? 'জমা' : 'Deposit', () => _showDepositDialog(member, fp, isBN)),
            ],
          ),
          if (member.isManager) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _confirmSettleMonth(fp, isBN),
              icon: const Icon(Icons.auto_awesome_motion_rounded, size: 16),
              label: Text(isBN ? 'মাস শেষ করুন' : 'Settle Month'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ]
        ],
      ),
    );
  }

  void _showEditBillsDialog(MessMember member, FinanceProvider fp, bool isBN) {
    final rentController = TextEditingController(text: member.monthlyRent.toString());
    final wifiController = TextEditingController(text: member.wifiBill.toString());
    final currentController = TextEditingController(text: member.electricityBill.toString());
    final otherController = TextEditingController(text: member.otherBills.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${member.name} - ${isBN ? 'বিল যোগ করুন' : 'Manage Bills'}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _billField(rentController, isBN ? 'ঘর ভাড়া' : 'Rent'),
              _billField(wifiController, 'WiFi'),
              _billField(currentController, isBN ? 'বিদ্যুৎ বিল' : 'Electricity'),
              _billField(otherController, isBN ? 'অন্যান্য' : 'Others'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBN ? 'বাতিল' : 'Cancel')),
          ElevatedButton(
            onPressed: () {
              fp.updateMessMemberBills(
                member.userId,
                member.id,
                rent: double.tryParse(rentController.text),
                wifi: double.tryParse(wifiController.text),
                electricity: double.tryParse(currentController.text),
                others: double.tryParse(otherController.text),
              );
              Navigator.pop(ctx);
            },
            child: Text(isBN ? 'সেভ করুন' : 'Save'),
          ),
        ],
      ),
    );
  }

  Widget _billField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  void _confirmSettleMonth(FinanceProvider fp, bool isBN) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBN ? 'মাসিক হিসাব বন্ধ?' : 'Settle Month?'),
        content: Text(isBN 
          ? 'আপনি কি নিশ্চিত? এটি বর্তমান মাসের বাজার ও মিলের হিসাব মুছে ফেলবে এবং বকেয়া পরবর্তী মাসে নিয়ে যাবে।' 
          : 'Are you sure? This will clear current market/meal logs and carry over balances as Previous Due.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBN ? 'না' : 'No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              fp.settleMonth(fp.messMembers.first.userId);
              Navigator.pop(ctx);
            },
            child: Text(isBN ? 'হ্যাঁ, বন্ধ করুন' : 'Yes, Settle'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.blueAccent),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.blueAccent)),
        ],
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, String uid, FinanceProvider fp, bool isBN) {
    final nameController = TextEditingController();
    bool isManager = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isBN ? 'নতুন সদস্য' : 'New Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(hintText: isBN ? 'নাম লিখুন' : 'Enter Name')),
              const SizedBox(height: 10),
              CheckboxListTile(
                title: Text(isBN ? 'ম্যানেজার?' : 'Is Manager?'),
                value: isManager,
                onChanged: (v) => setState(() => isManager = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBN ? 'বাতিল' : 'Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  fp.addMessMember(MessMember(
                    id: const Uuid().v4(),
                    userId: uid,
                    name: nameController.text,
                    isManager: isManager,
                  ));
                  Navigator.pop(ctx);
                }
              },
              child: Text(isBN ? 'যোগ করুন' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMealPlanDialog(MessMember member, FinanceProvider fp, bool isBN) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    showDialog(
      context: context,
      builder: (ctx) {
        final plan = fp.messMealPlans.firstWhere(
          (p) => p.memberId == member.id && p.date.day == tomorrow.day && p.date.month == tomorrow.month,
          orElse: () => MessMealPlan(id: '', messId: member.userId, memberId: member.id, date: tomorrow, isEnabled: true),
        );
        bool currentStatus = plan.isEnabled;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('${isBN ? 'আগামীকাল' : 'Tomorrow'}: ${DateFormat('dd MMM').format(tomorrow)}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isBN ? 'আগামীকাল মিল কি চালু থাকবে?' : 'Will you have meal tomorrow?'),
                const SizedBox(height: 20),
                SwitchListTile(
                  title: Text(currentStatus ? (isBN ? 'মিল অন' : 'Meal ON') : (isBN ? 'মিল অফ' : 'Meal OFF')),
                  value: currentStatus,
                  onChanged: (v) {
                    setDialogState(() => currentStatus = v);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBN ? 'বন্ধ করুন' : 'Close')),
              ElevatedButton(
                onPressed: () {
                  fp.toggleMealPlan(member.userId, member.id, tomorrow, currentStatus, member.name);
                  Navigator.pop(ctx);
                },
                child: Text(isBN ? 'নিশ্চিত করুন' : 'Confirm'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddMarketDialog(MessMember member, FinanceProvider fp, bool isBN) {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${member.name} - ${isBN ? 'বাজার খরচ' : 'Market Cost'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: isBN ? 'টাকার পরিমাণ' : 'Amount')),
            const SizedBox(height: 10),
            TextField(controller: descController, decoration: InputDecoration(hintText: isBN ? 'কি বাজার করলেন?' : 'Description (e.g., Fish, Rice)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBN ? 'বাতিল' : 'Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                fp.addMessMarketCost(member.userId, member.id, amount, descController.text.isEmpty ? (isBN ? 'বাজার' : 'Market') : descController.text, member.name);
                Navigator.pop(ctx);
              }
            },
            child: Text(isBN ? 'যোগ করুন' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showDepositDialog(MessMember member, FinanceProvider fp, bool isBN) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${member.name} - ${isBN ? 'টাকা জমা' : 'Deposit Money'}'),
        content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: isBN ? 'টাকার পরিমাণ' : 'Amount')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBN ? 'বাতিল' : 'Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                fp.depositMoney(member.userId, member.id, amount);
                Navigator.pop(ctx);
              }
            },
            child: Text(isBN ? 'জমা করুন' : 'Deposit'),
          ),
        ],
      ),
    );
  }

  void _showMemberOptions(MessMember member, FinanceProvider fp, bool isBN) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text(isBN ? 'সদস্য ডিলিট করুন' : 'Delete Member', style: const TextStyle(color: Colors.red)),
            onTap: () {
              fp.deleteMessMember(member.userId, member.id);
              Navigator.pop(ctx);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, bool isDark) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.people_outline, size: 60, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 10),
          Text(message, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}
