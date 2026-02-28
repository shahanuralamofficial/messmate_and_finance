import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/account.dart';
import '../providers/finance_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/translations.dart'; // Added translations import
import '../utils/constants.dart';

class AddAccountDialog extends StatefulWidget {
  final Account? account;

  const AddAccountDialog({super.key, this.account});

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _balanceController = TextEditingController(text: widget.account?.balance.toString() ?? '0');
    _selectedType = widget.account?.type ?? AppConstants.accountTypes[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final financeProvider = Provider.of<FinanceProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user!.uid;

    if (widget.account == null) {
      final newAccount = Account(
        id: const Uuid().v4(),
        userId: userId,
        name: _nameController.text.trim(),
        type: _selectedType,
        balance: double.parse(_balanceController.text),
      );
      financeProvider.addAccount(newAccount);
    } else {
      final updatedAccount = widget.account!.copyWith(
        name: _nameController.text.trim(),
        type: _selectedType,
        balance: double.parse(_balanceController.text),
      );
      financeProvider.updateAccount(updatedAccount);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final locale = settings.locale.languageCode;
    final isBangla = locale == 'bn';

    return AlertDialog(
      title: Text(widget.account == null 
        ? (isBangla ? 'নতুন অ্যাকাউন্ট' : 'Add Account') 
        : (isBangla ? 'অ্যাকাউন্ট আপডেট' : 'Edit Account')),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: isBangla ? 'নাম' : 'Name'),
                validator: (val) => val == null || val.isEmpty ? (isBangla ? 'নাম দিন' : 'Enter name') : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(labelText: isBangla ? 'ধরণ' : 'Type'),
                // Translated account type items
                items: AppConstants.accountTypes.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(AppTranslations.translate(type, locale)),
                )).toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                decoration: InputDecoration(labelText: isBangla ? 'ব্যালেন্স' : 'Balance'),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || double.tryParse(val) == null ? (isBangla ? 'সঠিক সংখ্যা দিন' : 'Enter valid number') : null,
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
