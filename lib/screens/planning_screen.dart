import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../models/planning_model.dart';
import '../models/user_model.dart';
import 'dart:async';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  @override
  Widget build(BuildContext context) {
    final fp = Provider.of<FinanceProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isBN = settings.locale.languageCode == 'bn';
    final isDark = themeProvider.isDarkMode;
    final symbol = settings.currencySymbol;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isBN ? 'পরিকল্পনা ও ফান্ড' : 'Planning & Fund', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: false,
      ),
      body: fp.plannings.isEmpty
          ? _buildEmptyState(isBN, isDark)
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildOverallSummaryCard(fp, isBN, isDark, symbol),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final plan = fp.plannings[index];
                        return _buildPlanningCard(plan, fp, auth.user?.uid ?? '', isBN, isDark, symbol);
                      },
                      childCount: fp.plannings.length,
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePlanDialog(context, fp, auth, isBN, isDark),
        label: Text(isBN ? 'নতুন পরিকল্পনা' : 'New Plan', style: const TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_task_rounded),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildOverallSummaryCard(FinanceProvider fp, bool isBN, bool isDark, String symbol) {
    double totalCollected = 0;
    double totalTarget = 0;
    int paidMembers = 0;
    int totalMembers = 0;

    for (var plan in fp.plannings) {
      final members = fp.getPlanningMembers(plan.id);
      totalTarget += plan.targetAmount;
      for (var m in members) {
        totalCollected += m.contributedAmount;
        totalMembers++;
        if (m.hasPaid) paidMembers++;
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isBN ? 'মোট জমা ফান্ড' : 'TOTAL COLLECTED FUND',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$symbol ${totalCollected.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  '${totalMembers > 0 ? ((paidMembers / totalMembers) * 100).toStringAsFixed(0) : 0}% Paid',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(isBN ? 'মোট টার্গেট' : 'Target', '$symbol${totalTarget.toStringAsFixed(0)}'),
              _buildSummaryItem(isBN ? 'পরিকল্পনা' : 'Plans', '${fp.plannings.length}'),
              _buildSummaryItem(isBN ? 'সদস্য' : 'Members', '$paidMembers/$totalMembers'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildPlanningCard(Planning plan, FinanceProvider fp, String currentUserId, bool isBN, bool isDark, String symbol) {
    final members = fp.getPlanningMembers(plan.id);
    final totalCollected = members.fold(0.0, (sum, m) => sum + m.contributedAmount);
    final progress = plan.targetAmount > 0 ? (totalCollected / plan.targetAmount).clamp(0.0, 1.0) : 0.0;
    final isCreator = plan.creatorId == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(20),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(plan.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : const Color(0xFF1E293B))),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      isBN ? (plan.collectionType == 'Weekly' ? 'সাপ্তাহিক' : 'মাসিক') : plan.collectionType,
                      style: const TextStyle(color: Color(0xFF6366F1), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$symbol${plan.periodicAmount.toStringAsFixed(0)} / ${isBN ? (plan.collectionType == 'Weekly' ? 'সপ্তাহ' : 'মাস') : (plan.collectionType == 'Weekly' ? 'week' : 'month')}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? Colors.green : const Color(0xFF6366F1)),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$symbol${totalCollected.toStringAsFixed(0)} / $symbol${plan.targetAmount.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('${(progress * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w900, fontSize: 13)),
                ],
              ),
            ],
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isBN ? 'সদস্য তালিকা' : 'Member List', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (isCreator)
                  IconButton(
                    onPressed: () => _showAddMemberDialog(context, plan.id, fp, isBN, isDark),
                    icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF6366F1)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (members.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text(isBN ? 'কোনো সদস্য নেই' : 'No members yet', style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic)))
            else
              ...members.map((m) => _buildMemberTile(m, plan, fp, isCreator, isBN, isDark, symbol)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(PlanningMember m, Planning plan, FinanceProvider fp, bool isCreator, bool isBN, bool isDark, String symbol) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: m.hasPaid ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
          child: Icon(m.hasPaid ? Icons.check_circle_rounded : Icons.pending_rounded, size: 20, color: m.hasPaid ? Colors.green : Colors.orange),
        ),
        title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('$symbol${m.contributedAmount}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        trailing: isCreator 
          ? IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF6366F1)),
              onPressed: () => _showCollectMoneyDialog(context, plan.id, m, plan.periodicAmount, fp, isBN, isDark),
            )
          : (m.hasPaid ? const Icon(Icons.verified_rounded, color: Colors.blue, size: 18) : null),
      ),
    );
  }

  void _showCreatePlanDialog(BuildContext context, FinanceProvider fp, AuthProvider auth, bool isBN, bool isDark) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final targetController = TextEditingController();
    final periodicController = TextEditingController();
    String collectionType = 'Monthly';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text(isBN ? 'নতুন পরিকল্পনা তৈরি করুন' : 'Create New Plan', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildField(isBN ? 'শিরোনাম' : 'Title', titleController, Icons.title_rounded),
                _buildField(isBN ? 'বর্ণনা' : 'Description', descController, Icons.description_rounded),
                Row(
                  children: [
                    Expanded(child: _buildField(isBN ? 'টার্গেট অ্যামাউন্ট' : 'Target Amount', targetController, Icons.track_changes_rounded, isNumber: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildField(isBN ? 'কিস্তির পরিমাণ' : 'Periodic Amount', periodicController, Icons.payments_rounded, isNumber: true)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(isBN ? 'কালেকশন টাইপ' : 'Collection Type', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildTypeChip('Weekly', isBN ? 'সাপ্তাহিক' : 'Weekly', collectionType == 'Weekly', (val) => setModalState(() => collectionType = val)),
                    const SizedBox(width: 12),
                    _buildTypeChip('Monthly', isBN ? 'মাসিক' : 'Monthly', collectionType == 'Monthly', (val) => setModalState(() => collectionType = val)),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isBN ? 'দয়া করে একটি শিরোনাম দিন' : 'Please enter a title'),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                        return;
                      }

                      try {
                        await fp.createPlanning(
                          titleController.text.trim(),
                          descController.text.trim(),
                          double.tryParse(targetController.text) ?? 0,
                          double.tryParse(periodicController.text) ?? 0,
                          collectionType,
                          auth.user!.uid,
                          auth.userModel?.displayName ?? 'Admin',
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isBN ? 'পরিকল্পনা সফলভাবে তৈরি হয়েছে' : 'Plan created successfully'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(isBN ? 'শুরু করুন' : 'Get Started', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.grey.withValues(alpha: 0.1),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String value, String label, bool isSelected, Function(String) onSelect) {
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  void _showCollectMoneyDialog(BuildContext context, String planId, PlanningMember member, double suggestAmount, FinanceProvider fp, bool isBN, bool isDark) {
    final amountController = TextEditingController(text: suggestAmount.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${member.name} - ${isBN ? "টাকা জমা" : "Collect Money"}'),
        content: TextField(
          controller: amountController,
          decoration: InputDecoration(
            labelText: isBN ? 'পরিমাণ' : 'Amount',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(isBN ? 'বাতিল' : 'Cancel')),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amountController.text) ?? 0;
              if (amt > 0) {
                fp.updateContributedAmount(planId, member.userId, amt);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
            child: Text(isBN ? 'নিশ্চিত করুন' : 'Confirm'),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, String planId, FinanceProvider fp, bool isBN, bool isDark) {
    final searchController = TextEditingController();
    List<UserModel> searchResults = [];
    Timer? debounce;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isBN ? 'সদস্য যোগ করুন' : 'Add Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: isBN ? 'নাম বা ইমেইল দিয়ে খুঁজুন' : 'Search by name/email',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (val) {
                  if (debounce?.isActive ?? false) debounce!.cancel();
                  debounce = Timer(const Duration(milliseconds: 500), () async {
                    if (val.isNotEmpty) {
                      final results = await Provider.of<AuthProvider>(context, listen: false).searchUsers(val);
                      setState(() => searchResults = results);
                    }
                  });
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 250,
                width: double.maxFinite,
                child: searchResults.isEmpty
                    ? Center(child: Text(isBN ? 'কাউকে পাওয়া যায়নি' : 'No users found'))
                    : ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, i) {
                          final user = searchResults[i];
                          return ListTile(
                            leading: CircleAvatar(child: Text(user.displayName?[0] ?? 'U')),
                            title: Text(user.displayName ?? ''),
                            subtitle: Text(user.email, style: const TextStyle(fontSize: 12)),
                            onTap: () {
                              fp.addPlanningMember(planId, user.uid, user.displayName ?? 'User', user.email);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isBN, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.event_note_rounded, size: 80, color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: 24),
          Text(isBN ? 'কোনো পরিকল্পনা নেই' : 'No planning found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E293B))),
          const SizedBox(height: 8),
          Text(isBN ? 'ট্যুর বা ইভেন্টের জন্য ফান্ড তৈরি করুন' : 'Create a fund for tours or events', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}
