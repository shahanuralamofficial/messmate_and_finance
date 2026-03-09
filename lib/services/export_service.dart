
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/debt.dart';

class ExportService {
  static Future<void> exportTransactionsToCSV(List<Transaction> transactions, List<Account> accounts) async {
    String csv = 'Date,Title,Amount,Type,Category,Account,Note\n';
    
    for (var t in transactions) {
      final account = accounts.firstWhere((a) => a.id == t.accountId, orElse: () => Account(id: '', userId: '', name: 'N/A', balance: 0, type: 'cash'));
      
      String date = DateFormat('yyyy-MM-dd').format(t.date);
      String type = t.type.name;
      
      csv += '$date,"${t.title}",${t.amount},$type,"${t.category}","${account.name}","${t.note ?? ''}"\n';
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/transactions_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(path)], text: 'Transaction Export');
  }

  static Future<void> exportDebtsToCSV(List<Debt> debts) async {
    String csv = 'Person,Amount,Type,Status,Due Date,Note\n';
    
    for (var d in debts) {
      String date = DateFormat('yyyy-MM-dd').format(d.dueDate);
      String type = d.type == DebtType.oweMe ? 'Owe Me' : 'I Owe';
      String status = d.isSettled ? 'Settled' : 'Pending';
      
      csv += '"${d.personName}",${d.amount},$type,$status,$date,"${d.note ?? ''}"\n';
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/debts_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(path)], text: 'Debts Export');
  }
}
