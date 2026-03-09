
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/finance_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../models/budget.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fp = Provider.of<FinanceProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isBN = settings.locale.languageCode == 'bn';

    return Scaffold(
      appBar: AppBar(
        title: Text(isBN ? 'বাজেট ম্যানেজমেন্ট' : 'Budget Management'),
      ),
      body: fp.budgets.isEmpty
          ? Center(child: Text(isBN ? 'কোনো বাজেট সেট করা নেই' : 'No budgets set yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: fp.budgets.length,
              itemBuilder: (ctx, i) {
                final budget = fp.budgets[i];
                // In a real app, you'd calculate 'spent' from transactions of that category
                final double spent = fp.transactions
                    .where((t) => t.category == budget.category && t.date.month == budget.month.month)
                    .fold(0, (sum, t) => sum + t.amount);
                
                final double percent = (spent / budget.amount).clamp(0.0, 1.0);
                final Color progressColor = percent > 0.9 ? Colors.red : (percent > 0.7 ? Colors.orange : Colors.green);

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(budget.category, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('${settings.currencySymbol}${budget.amount.toStringAsFixed(0)}', 
                                style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: percent,
                          backgroundColor: Colors.grey[200],
                          color: progressColor,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(isBN ? 'খরচ: ${settings.currencySymbol}${spent.toStringAsFixed(0)}' : 'Spent: ${settings.currencySymbol}${spent.toStringAsFixed(0)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            Text('${(percent * 100).toStringAsFixed(1)}%', 
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: progressColor)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetDialog(context, fp, auth.user!.uid, isBN),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddBudgetDialog(BuildContext context, FinanceProvider fp, String userId, bool isBN) {
    final amountController = TextEditingController();
    String selectedCategory = 'Food';
    final categories = ['Food', 'Transport', 'Rent', 'Shopping', 'Bills', 'Others'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isBN ? 'বাজেট যোগ করুন' : 'Add Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => selectedCategory = v!),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: isBN ? 'পরিমাণ' : 'Amount'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBN ? 'বাতিল' : 'Cancel')),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount > 0) {
                  final b = Budget(
                    id: const Uuid().v4(),
                    userId: userId,
                    category: selectedCategory,
                    amount: amount,
                    month: DateTime.now(),
                  );
                  fp.addBudget(b);
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
