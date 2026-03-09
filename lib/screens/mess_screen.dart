import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/mess_meal_plan.dart';
import '../providers/finance_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../models/mess_member.dart';
import '../models/mess_market_expense.dart';
import '../models/mess_info.dart';
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
    _tabController = TabController(length: 4, vsync: this);
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

    final pendingExpenses = financeProvider.messMarketExpenses.where((e) => e.status == ExpenseStatus.pending).toList();
    final pendingMeals = financeProvider.messMealPlans.where((p) => p.status == MealPlanStatus.pending).toList();
    final totalPending = pendingExpenses.length + pendingMeals.length;

    // Check if current user is manager
    final currentMember = financeProvider.messMembers.firstWhere(
      (m) => m.appUserId == authProvider.user?.uid, 
      orElse: () => MessMember(id: '', name: '', messId: '', isManager: false, userId: '')
    );
    final bool isManager = currentMember.isManager;

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
              messInfo: financeProvider.messInfo ?? MessInfo(id: '', name: isBN ? 'আমার মেস' : 'My Mess', address: '', ownerPhone: ''),
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
          isScrollable: true,
          tabs: [
            Tab(text: isBN ? 'সদস্য' : 'Members'),
            Tab(
              child: Row(
                children: [
                  Text(isBN ? 'অনুরোধ' : 'Requests'),
                  if (totalPending > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text(totalPending.toString(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                ],
              ),
            ),
            Tab(text: isBN ? 'খরচ' : 'Expenses'),
            Tab(text: isBN ? 'ইতিহাস' : 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMembersTab(financeProvider, authProvider, isBN, isDark, settings.currencySymbol, isManager),
          _buildRequestsTab(financeProvider, authProvider, isBN, isDark, settings.currencySymbol, isManager),
          _buildExpensesTab(financeProvider, isBN, isDark, settings.currencySymbol),
          _buildLogsTab(financeProvider, isBN, isDark),
        ],
      ),
    );
  }

  Widget _buildRequestsTab(FinanceProvider fp, AuthProvider auth, bool isBN, bool isDark, String symbol, bool isManager) {
    final pendingExpenses = fp.messMarketExpenses.where((e) => e.status == ExpenseStatus.pending).toList();
    final pendingMeals = fp.messMealPlans.where((p) => p.status == MealPlanStatus.pending).toList();

    if (pendingExpenses.isEmpty && pendingMeals.isEmpty) {
      return _buildEmptyState(isBN ? 'কোন পেন্ডিং অনুরোধ নেই' : 'No pending requests', isDark);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pendingExpenses.isNotEmpty) ...[
          Text(isBN ? 'বাজার খরচের অনুরোধ' : 'Market Expense Requests', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ...pendingExpenses.map((e) => _buildExpenseRequestTile(e, fp, isManager, isBN, isDark, symbol)),
          const SizedBox(height: 20),
        ],
        if (pendingMeals.isNotEmpty) ...[
          Text(isBN ? 'মিল অন/অফ অনুরোধ' : 'Meal Toggle Requests', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ...pendingMeals.map((p) => _buildMealRequestTile(p, fp, isManager, isBN, isDark)),
        ],
      ],
    );
  }

  Widget _buildExpenseRequestTile(MessMarketExpense e, FinanceProvider fp, bool isManager, bool isBN, bool isDark, String symbol) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text(e.description, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${e.memberName} • $symbol${e.amount}'),
        trailing: isManager 
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => fp.approveExpense(e.messId, e)),
                IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => fp.rejectExpense(e.messId, e.id)),
              ],
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(isBN ? 'পেন্ডিং' : 'Pending', style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
      ),
    );
  }

  Widget _buildMealRequestTile(MessMealPlan p, FinanceProvider fp, bool isManager, bool isBN, bool isDark) {
    final dateStr = DateFormat('dd MMM').format(p.date);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text('${p.memberName} - ${p.isEnabled ? (isBN ? "মিল অন" : "Meal ON") : (isBN ? "মিল অফ" : "Meal OFF")}'),
        subtitle: Text('${isBN ? "তারিখ" : "Date"}: $dateStr'),
        trailing: isManager 
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => fp.approveMealPlan(p.messId, p)),
                IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => fp.rejectMealPlan(p.messId, p.id)),
              ],
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(isBN ? 'পেন্ডিং' : 'Pending', style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
      ),
    );
  }

  Widget _buildMembersTab(FinanceProvider fp, AuthProvider auth, bool isBN, bool isDark, String symbol, bool isManager) {
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
              if (isManager)
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _showAddMemberDialog(context, auth.user!.uid, fp, isBN),
                      icon: const Icon(Icons.person_add_alt_1, color: Colors.blueAccent),
                    ),
                    IconButton(
                      onPressed: () => _showMessSettingsDialog(fp, isBN),
                      icon: const Icon(Icons.settings_suggest_outlined, color: Colors.indigo),
                    ),
                  ],
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
                return _buildMemberTile(member, fp, isBN, isDark, symbol, auth, isManager);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(MessMember m, FinanceProvider fp, bool isBN, bool isDark, String symbol, AuthProvider auth, bool isManager) {
    final mealCost = m.totalMeals * fp.mealRate;
    final totalDue = mealCost + m.monthlyRent + m.wifiBill + m.electricityBill + m.otherBills + m.previousDue;
    final currentBalance = m.initialDeposit - totalDue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent.withOpacity(0.1),
          child: Text(m.name[0], style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
        ),
        title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${isBN ? "ব্যালেন্স" : "Balance"}: $symbol${currentBalance.toStringAsFixed(1)}'),
        trailing: m.isManager ? Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(isBN ? 'ম্যানেজার' : 'Manager', style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
        ) : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(isBN ? 'মোট মিল' : 'Total Meals', m.totalMeals.toStringAsFixed(1), isDark),
                _buildInfoRow(isBN ? 'মিল খরচ' : 'Meal Cost', '$symbol${mealCost.toStringAsFixed(1)}', isDark),
                _buildInfoRow(isBN ? 'অন্যান্য বিল' : 'Other Bills', '$symbol${(m.monthlyRent + m.wifiBill + m.electricityBill + m.otherBills).toStringAsFixed(0)}', isDark),
                _buildInfoRow(isBN ? 'জমা' : 'Deposit', '$symbol${m.initialDeposit}', isDark),
                const Divider(),
                if (isManager)
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showAddMealDialog(m, fp, isBN),
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: Text(isBN ? 'মিল যোগ' : 'Add Meal'),
                      ),
                      TextButton.icon(
                        onPressed: () => _showEditBillsDialog(m, fp, isBN),
                        icon: const Icon(Icons.edit_note, size: 18),
                        label: Text(isBN ? 'বিল এডিট' : 'Edit Bills'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesTab(FinanceProvider fp, bool isBN, bool isDark, String symbol) {
    final approvedExpenses = fp.messMarketExpenses.where((e) => e.status == ExpenseStatus.approved).toList();
    if (approvedExpenses.isEmpty) {
      return _buildEmptyState(isBN ? 'কোন খরচ নেই' : 'No expenses recorded', isDark);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: approvedExpenses.length,
      itemBuilder: (context, index) {
        final expense = approvedExpenses[index];
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
                  Text(isBN ? 'গড় মিল রেট' : 'Avg. Meal Rate', style: const TextStyle(color: Colors.white70, fontSize: 14)),
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
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 10),
          Text(msg, style: TextStyle(color: Colors.grey.withOpacity(0.8))),
        ],
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, String managerId, FinanceProvider fp, bool isBN) {
    final nameController = TextEditingController();
    final depositController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBN ? 'নতুন সদস্য' : 'Add Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(hintText: isBN ? 'সদস্যের নাম' : 'Member Name')),
            TextField(controller: depositController, decoration: InputDecoration(hintText: isBN ? 'প্রাথমিক জমা' : 'Initial Deposit'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBN ? 'বাতিল' : 'Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                fp.addMessMember(managerId, nameController.text, double.tryParse(depositController.text) ?? 0.0);
                Navigator.pop(ctx);
              }
            },
            child: Text(isBN ? 'যোগ করুন' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showAddMealDialog(MessMember m, FinanceProvider fp, bool isBN) {
    final countController = TextEditingController(text: "1.0");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBN ? 'মিল যোগ করুন' : 'Add Meal'),
        content: TextField(
          controller: countController,
          decoration: InputDecoration(hintText: isBN ? 'মিলের সংখ্যা' : 'Meal Count'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBN ? 'বাতিল' : 'Cancel')),
          ElevatedButton(
            onPressed: () {
              final count = double.tryParse(countController.text) ?? 0.0;
              fp.addMeal(m.messId, m.id, count);
              Navigator.pop(ctx);
            },
            child: Text(isBN ? 'যোগ করুন' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showEditBillsDialog(MessMember m, FinanceProvider fp, bool isBN) {
    final rentController = TextEditingController(text: m.monthlyRent.toString());
    final wifiController = TextEditingController(text: m.wifiBill.toString());
    final electController = TextEditingController(text: m.electricityBill.toString());
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBN ? 'বিল পরিবর্তন' : 'Edit Bills'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: rentController, decoration: InputDecoration(labelText: isBN ? 'সিট ভাড়া' : 'Rent'), keyboardType: TextInputType.number),
              TextField(controller: wifiController, decoration: InputDecoration(labelText: isBN ? 'ওয়াইফাই' : 'WiFi'), keyboardType: TextInputType.number),
              TextField(controller: electController, decoration: InputDecoration(labelText: isBN ? 'বিদ্যুৎ' : 'Electricity'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBN ? 'বাতিল' : 'Cancel')),
          ElevatedButton(
            onPressed: () {
              fp.updateMemberBills(
                m.messId, 
                m.id, 
                double.tryParse(rentController.text) ?? 0,
                double.tryParse(wifiController.text) ?? 0,
                double.tryParse(electController.text) ?? 0,
              );
              Navigator.pop(ctx);
            },
            child: Text(isBN ? 'সেভ করুন' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _showMessSettingsDialog(FinanceProvider fp, bool isBN) {
    final nameController = TextEditingController(text: fp.messInfo?.name ?? "");
    final addressController = TextEditingController(text: fp.messInfo?.address ?? "");
    final phoneController = TextEditingController(text: fp.messInfo?.ownerPhone ?? "");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBN ? 'মেস সেটিংস' : 'Mess Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: isBN ? 'মেসের নাম' : 'Mess Name')),
              TextField(controller: addressController, decoration: InputDecoration(labelText: isBN ? 'ঠিকানা' : 'Address')),
              TextField(controller: phoneController, decoration: InputDecoration(labelText: isBN ? 'ফোন' : 'Phone')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBN ? 'বাতিল' : 'Cancel')),
          ElevatedButton(
            onPressed: () {
              fp.updateMessInfo(
                nameController.text,
                addressController.text,
                phoneController.text,
              );
              Navigator.pop(ctx);
            },
            child: Text(isBN ? 'সেভ' : 'Save'),
          ),
        ],
      ),
    );
  }
}
