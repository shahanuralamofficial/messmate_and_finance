
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../models/debt.dart';

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fp = Provider.of<FinanceProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isBN = settings.locale.languageCode == 'bn';

    return Scaffold(
      appBar: AppBar(
        title: Text(isBN ? 'ধার-দেনা' : 'Debts & Loans'),
      ),
      body: fp.debts.isEmpty
          ? Center(child: Text(isBN ? 'কোনো ধারের হিসাব নেই' : 'No debt records found'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: fp.debts.length,
              itemBuilder: (ctx, i) {
                final debt = fp.debts[i];
                final bool isOweMe = debt.type == DebtType.oweMe;

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isOweMe ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      child: Icon(
                        isOweMe ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isOweMe ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(debt.personName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isOweMe 
                          ? (isBN ? 'আমি পাবো' : 'Owes me') 
                          : (isBN ? 'আমি দেবো' : 'I owe them')),
                        Text('${isBN ? 'তারিখ' : 'Due'}: ${DateFormat('dd MMM, yyyy').format(debt.dueDate)}', 
                             style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${settings.currencySymbol}${debt.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: debt.isSettled ? Colors.grey : (isOweMe ? Colors.green : Colors.red),
                          ),
                        ),
                        if (debt.isSettled)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
                            child: Text(isBN ? 'পরিশোধিত' : 'Settled', style: const TextStyle(fontSize: 10)),
                          )
                        else
                          TextButton(
                            onPressed: () => fp.settleDebt(auth.user!.uid, debt.id),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                            child: Text(isBN ? 'পরিশোধ' : 'Settle', style: const TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDebtDialog(context, fp, auth.user!.uid, isBN),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDebtDialog(BuildContext context, FinanceProvider fp, String userId, bool isBN) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    DebtType selectedType = DebtType.oweMe;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isBN ? 'নতুন হিসাব' : 'New Record'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: isBN ? 'নাম' : 'Name'),
                ),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: isBN ? 'পরিমাণ' : 'Amount'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(isBN ? 'ধরণ:' : 'Type:'),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: Text(isBN ? 'আমি পাবো' : 'Owe Me'),
                      selected: selectedType == DebtType.oweMe,
                      onSelected: (val) => setState(() => selectedType = DebtType.oweMe),
                    ),
                    const SizedBox(width: 5),
                    ChoiceChip(
                      label: Text(isBN ? 'আমি দেবো' : 'I Owe'),
                      selected: selectedType == DebtType.iOwe,
                      onSelected: (val) => setState(() => selectedType = DebtType.iOwe),
                    ),
                  ],
                ),
                ListTile(
                  title: Text(isBN ? 'পরিশোধের তারিখ' : 'Due Date'),
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
                if (nameController.text.isNotEmpty && amount > 0) {
                  final d = Debt(
                    id: const Uuid().v4(),
                    userId: userId,
                    personName: nameController.text,
                    amount: amount,
                    type: selectedType,
                    dueDate: selectedDate,
                  );
                  fp.addDebt(d);
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
