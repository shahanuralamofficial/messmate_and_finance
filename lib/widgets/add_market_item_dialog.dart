import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/market_item.dart';
import '../providers/finance_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';

class AddMarketItemDialog extends StatefulWidget {
  const AddMarketItemDialog({super.key});

  @override
  State<AddMarketItemDialog> createState() => _AddMarketItemDialogState();
}

class _AddMarketItemDialogState extends State<AddMarketItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedUnit = AppConstants.units[0];

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final financeProvider = Provider.of<FinanceProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final newItem = MarketItem(
      id: const Uuid().v4(),
      userId: authProvider.user!.uid,
      name: _nameController.text.trim(),
      quantity: double.parse(_quantityController.text),
      unit: _selectedUnit,
      price: double.parse(_priceController.text),
      addedDate: DateTime.now(),
    );

    financeProvider.addMarketItem(newItem);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isBangla = Provider.of<SettingsProvider>(context).locale.languageCode == 'bn';
    return AlertDialog(
      title: Text(isBangla ? 'নতুন বাজার আইটেম' : 'New Market Item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: isBangla ? 'আইটেমের নাম' : 'Item Name'),
                validator: (val) => val!.isEmpty ? (isBangla ? 'নাম দিন' : 'Enter a name') : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(labelText: isBangla ? 'পরিমাণ' : 'Quantity'),
                      keyboardType: TextInputType.number,
                      validator: (val) => val!.isEmpty || double.tryParse(val) == null ? (isBangla ? 'সঠিক সংখ্যা দিন' : 'Enter a valid number') : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedUnit,
                    items: AppConstants.units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (val) => setState(() => _selectedUnit = val!),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: isBangla ? 'আনুমানিক মূল্য' : 'Estimated Price'),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty || double.tryParse(val) == null ? (isBangla ? 'সঠিক মূল্য দিন' : 'Enter a valid price') : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(isBangla ? 'বাতিল' : 'Cancel')),
        ElevatedButton(onPressed: _submit, child: Text(isBangla ? 'যোগ করুন' : 'Add')),
      ],
    );
  }
}
