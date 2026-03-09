
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/mess_member.dart';
import '../models/mess_market_expense.dart';

class MessReportHelper {
  static Future<void> generateAndPrintReport({
    required String messName,
    required List<MessMember> members,
    required List<MessMarketExpense> expenses,
    required double totalMeals,
    required double totalCost,
    required double mealRate,
    required String currency,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Mess Monthly Report - $messName', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text(DateTime.now().toString().substring(0, 10)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatBox('Total Market', '$currency${totalCost.toStringAsFixed(2)}'),
              _buildStatBox('Total Meals', totalMeals.toStringAsFixed(1)),
              _buildStatBox('Meal Rate', '$currency${mealRate.toStringAsFixed(2)}'),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Text('Member Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.TableHelper.fromTextArray(
            headers: ['Name', 'Deposit', 'Meals', 'Cost', 'Balance'],
            data: members.map((m) {
              final cost = m.totalMeals * mealRate;
              final balance = m.initialDeposit - cost;
              return [
                m.name,
                m.initialDeposit.toStringAsFixed(1),
                m.totalMeals.toStringAsFixed(1),
                cost.toStringAsFixed(1),
                balance.toStringAsFixed(1),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 30),
          pw.Text('Market Expenses Details', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Member', 'Description', 'Amount'],
            data: expenses.map((e) => [
              e.date.toString().substring(0, 10),
              e.memberName,
              e.description,
              e.amount.toStringAsFixed(1),
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static pw.Widget _buildStatBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
      child: pw.Column(
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
