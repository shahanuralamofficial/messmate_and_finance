
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../models/savings_goal.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fp = Provider.of<FinanceProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isBN = settings.locale.languageCode == 'bn';

    return Scaffold(
      appBar: AppBar(
        title: Text(isBN ? 'সেভিংস গোল' : 'Savings Goals'),
      ),
      body: fp.savingsGoals.isEmpty
          ? Center(child: Text(isBN ? 'কোনো লক্ষ্য সেট করা নেই' : 'No savings goals set yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: fp.savingsGoals.length,
              itemBuilder: (ctx, i) {
                final goal = fp.savingsGoals[i];
                final double percent = (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
                final bool isCompleted = goal.currentAmount >= goal.targetAmount;

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                goal.title,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (isCompleted)
                              const Icon(Icons.check_circle, color: Colors.green)
                            else
                              Text(
                                '${(percent * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${isBN ? 'লক্ষ্য:' : 'Deadline:'} ${DateFormat('dd MMM, yyyy').format(goal.deadline)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: percent,
                            minHeight: 12,
                            backgroundColor: Colors.grey[200],
                            color: isCompleted ? Colors.green : Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${settings.currencySymbol}${goal.currentAmount.toStringAsFixed(0)} / ${settings.currencySymbol}${goal.targetAmount.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            if (!isCompleted)
                              ElevatedButton(
                                onPressed: () => _showAddProgressDialog(context, fp, auth.user!.uid, goal, isBN),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  minimumSize: const Size(60, 30),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(isBN ? 'টাকা জমান' : 'Add Money'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(context, fp, auth.user!.uid, isBN),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddProgressDialog(BuildContext context, FinanceProvider fp, String userId, SavingsGoal goal, bool isBN) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBN ? 'টাকা যোগ করুন' : 'Add Savings'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: isBN ? 'পরিমাণ' : 'Amount',
            prefixText: fp.error ?? '', // just a placeholder
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBN ? 'বাতিল' : 'Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                fp.updateSavingsProgress(userId, goal.id, amount);
                Navigator.pop(ctx);
              }
            },
            child: Text(isBN ? 'যোগ করুন' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, FinanceProvider fp, String userId, bool isBN) {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isBN ? 'নতুন লক্ষ্য' : 'New Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: isBN ? 'কি কিনতে চান?' : 'Goal Title'),
              ),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: isBN ? 'কত টাকা লাগবে?' : 'Target Amount'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(isBN ? 'শেষ তারিখ' : 'Target Date'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => selectedDate = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBN ? 'বাতিল' : 'Cancel')),
            ElevatedButton(
              onPressed: () {
                final target = double.tryParse(targetController.text) ?? 0;
                if (titleController.text.isNotEmpty && target > 0) {
                  final goal = SavingsGoal(
                    id: const Uuid().v4(),
                    userId: userId,
                    title: titleController.text,
                    targetAmount: target,
                    deadline: selectedDate,
                  );
                  fp.addSavingsGoal(goal);
                  Navigator.pop(ctx);
                }
              },
              child: Text(isBN ? 'সেভ' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
