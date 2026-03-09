
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../models/recurring_transaction.dart';

class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fp = Provider.of<FinanceProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isBN = settings.locale.languageCode == 'bn';

    return Scaffold(
      appBar: AppBar(
        title: Text(isBN ? 'অটো বিল' : 'Recurring Bills'),
      ),
      body: fp.recurringTransactions.isEmpty
          ? Center(child: Text(isBN ? 'কোনো অটো বিল সেট করা নেই' : 'No recurring bills set yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: fp.recurringTransactions.length,
              itemBuilder: (ctx, i) {
                final rt = fp.recurringTransactions[i];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: const Icon(Icons.repeat, color: Colors.blue),
                    ),
                    title: Text(rt.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${rt.category} • ${rt.interval.name.toUpperCase()}\n${isBN ? 'পরবর্তী:' : 'Next:'} ${DateFormat('dd MMM, yyyy').format(rt.nextDate)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${settings.currencySymbol}${rt.amount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Switch(
                          value: rt.isActive,
                          onChanged: (val) => fp.toggleRecurringActive(auth.user!.uid, rt.id, val),
                          activeColor: Colors.blue,
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    onLongPress: () => _confirmDelete(context, fp, auth.user!.uid, rt.id, isBN),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecurringDialog(context, fp, auth.user!.uid, isBN),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, FinanceProvider fp, String userId, String id, bool isBN) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBN ? 'মুছে ফেলুন?' : 'Delete?'),
        content: Text(isBN ? 'আপনি কি এটি মুছতে চান?' : 'Do you want to delete this recurring bill?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBN ? 'না' : 'No')),
          TextButton(
            onPressed: () {
              fp.deleteRecurringTransaction(userId, id);
              Navigator.pop(ctx);
            },
            child: Text(isBN ? 'হ্যাঁ' : 'Yes'),
          ),
        ],
      ),
    );
  }

  void _showAddRecurringDialog(BuildContext context, FinanceProvider fp, String userId, bool isBN) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = 'Bills';
    RecurringInterval selectedInterval = RecurringInterval.monthly;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isBN ? 'নতুন অটো বিল' : 'New Recurring Bill'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: isBN ? 'শিরোনাম' : 'Title'),
                ),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: isBN ? 'পরিমাণ' : 'Amount'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: ['Bills', 'Rent', 'Wifi', 'Subscription', 'Others']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedCategory = v!),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                DropdownButtonFormField<RecurringInterval>(
                  value: selectedInterval,
                  items: RecurringInterval.values
                      .map((i) => DropdownMenuItem(value: i, child: Text(i.name.toUpperCase())))
                      .toList(),
                  onChanged: (v) => setState(() => selectedInterval = v!),
                  decoration: const InputDecoration(labelText: 'Interval'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(isBN ? 'প্রথম পেমেন্ট তারিখ' : 'First Payment Date'),
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
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBN ? 'বাতিল' : 'Cancel')),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (titleController.text.isNotEmpty && amount > 0) {
                  final rt = RecurringTransaction(
                    id: const Uuid().v4(),
                    userId: userId,
                    title: titleController.text,
                    amount: amount,
                    category: selectedCategory,
                    interval: selectedInterval,
                    nextDate: selectedDate,
                  );
                  fp.addRecurringTransaction(rt);
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
