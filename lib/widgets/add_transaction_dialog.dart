import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/translations.dart'; // Added translations import
import '../utils/constants.dart';

class AddTransactionDialog extends StatefulWidget {
  final TransactionType type;

  const AddTransactionDialog({super.key, required this.type});

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  String? _selectedAccountId;
  String _selectedCategory = AppConstants.categories[1];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.type == TransactionType.income 
      ? AppConstants.categories[0] 
      : AppConstants.categories[1];
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final financeProvider = Provider.of<FinanceProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user!.uid;

    final newTransaction = Transaction(
      id: const Uuid().v4(),
      userId: userId,
      title: _selectedCategory, 
      type: widget.type,
      amount: double.parse(_amountController.text),
      category: _selectedCategory,
      date: _selectedDate,
      accountId: _selectedAccountId,
      note: _noteController.text.trim(),
    );

    await financeProvider.addTransaction(newTransaction);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final financeProvider = Provider.of<FinanceProvider>(context);
    final locale = settings.locale.languageCode;
    final isBangla = locale == 'bn';

    return AlertDialog(
      title: Text(widget.type == TransactionType.income 
          ? (isBangla ? 'নতুন আয়' : 'New Income') 
          : (isBangla ? 'নতুন ব্যয়' : 'New Expense')),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: isBangla ? 'টাকার পরিমাণ' : 'Amount'),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || double.tryParse(val) == null ? (isBangla ? 'সঠিক সংখ্যা দিন' : 'Enter a valid number') : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedAccountId,
                decoration: InputDecoration(labelText: isBangla ? 'অ্যাকাউন্ট' : 'Account'),
                items: financeProvider.accounts.map((acc) => DropdownMenuItem(value: acc.id, child: Text(acc.name))).toList(),
                onChanged: (val) => setState(() => _selectedAccountId = val),
                validator: (val) => val == null ? (isBangla ? 'একটি অ্যাকাউন্ট নির্বাচন করুন' : 'Select an account') : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(labelText: isBangla ? 'বিভাগ' : 'Category'),
                // Translated category items
                items: AppConstants.categories.map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(AppTranslations.translate(cat, locale)),
                )).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(isBangla ? 'তারিখ' : 'Date'),
                subtitle: Text(DateFormat.yMMMd().format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() => _selectedDate = pickedDate);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(labelText: isBangla ? 'নোট (ঐচ্ছিক)' : 'Note (Optional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(isBangla ? 'বাতিল' : 'Cancel')),
        ElevatedButton(onPressed: _submit, child: Text(isBangla ? 'সেভ' : 'Save')),
      ],
    );
  }
}
