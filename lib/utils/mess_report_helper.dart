
import 'package:printing/printing.dart';
import '../models/mess_member.dart';
import '../models/mess_market_expense.dart';
import 'package:intl/intl.dart';

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
    final dateStr = DateFormat('dd MMMM, yyyy').format(DateTime.now());

    // Member rows generation
    String memberRows = '';
    for (var m in members) {
      final mealCost = m.totalMeals * mealRate;
      final extraBills = m.monthlyRent + m.wifiBill + m.electricityBill + m.otherBills;
      final totalAmount = mealCost + extraBills + m.previousDue;
      final netDue = totalAmount - m.initialDeposit;
      
      memberRows += """
        <tr>
          <td>${m.name}</td>
          <td>${m.totalMeals.toStringAsFixed(1)}</td>
          <td>${mealCost.toStringAsFixed(1)}</td>
          <td>${extraBills.toStringAsFixed(1)}</td>
          <td>${m.initialDeposit.toStringAsFixed(1)}</td>
          <td style="font-weight: bold; color: ${netDue > 0 ? '#e53935' : '#43a047'}">${netDue.toStringAsFixed(1)}</td>
        </tr>
      """;
    }

    // Expense rows generation
    String expenseRows = '';
    for (var e in expenses.where((exp) => exp.status == ExpenseStatus.approved)) {
      expenseRows += """
        <tr>
          <td>${DateFormat('dd-MM-yy').format(e.date)}</td>
          <td>${e.memberName}</td>
          <td>${e.description}</td>
          <td>${e.amount.toStringAsFixed(1)}</td>
        </tr>
      """;
    }

    final htmlContent = """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif, 'SolaimanLipi'; padding: 20px; color: #333; }
        .header { text-align: center; border-bottom: 2px solid #3f51b5; padding-bottom: 10px; margin-bottom: 20px; }
        .mess-name { font-size: 28px; font-weight: bold; color: #3f51b5; margin: 0; }
        .report-title { font-size: 18px; color: #666; margin: 5px 0; }
        .stats-container { display: flex; justify-content: space-around; margin-bottom: 30px; }
        .stat-box { background: #f5f6fa; border: 1px solid #dcdde1; padding: 15px; border-radius: 10px; text-align: center; min-width: 120px; }
        .stat-label { font-size: 12px; color: #7f8c8d; text-transform: uppercase; margin-bottom: 5px; }
        .stat-value { font-size: 18px; font-weight: bold; color: #2f3640; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; font-size: 14px; }
        th { background-color: #3f51b5; color: white; text-align: left; padding: 12px; }
        td { border: 1px solid #dcdde1; padding: 10px; text-align: left; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        h2 { color: #3f51b5; border-left: 5px solid #3f51b5; padding-left: 10px; margin-top: 30px; font-size: 20px; }
        .footer { margin-top: 50px; text-align: center; font-size: 12px; color: #95a5a6; border-top: 1px solid #eee; padding-top: 10px; }
      </style>
    </head>
    <body>
      <div class="header">
        <h1 class="mess-name">$messName</h1>
        <p class="report-title">Monthly Finance Summary</p>
        <p style="font-size: 12px;">Generated on: $dateStr</p>
      </div>

      <div class="stats-container">
        <div class="stat-box">
          <div class="stat-label">Total Market</div>
          <div class="stat-value">$currency${totalCost.toStringAsFixed(1)}</div>
        </div>
        <div class="stat-box">
          <div class="stat-label">Total Meals</div>
          <div class="stat-value">${totalMeals.toStringAsFixed(1)}</div>
        </div>
        <div class="stat-box">
          <div class="stat-label">Meal Rate</div>
          <div class="stat-value">$currency${mealRate.toStringAsFixed(2)}</div>
        </div>
      </div>

      <h2>Member Summary (সদস্য বিবরণী)</h2>
      <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>Meals</th>
            <th>Meal Cost</th>
            <th>Bills</th>
            <th>Deposit</th>
            <th>Net Due</th>
          </tr>
        </thead>
        <tbody>
          $memberRows
        </tbody>
      </table>

      <h2>Market Expenses (বাজারের হিসাব)</h2>
      <table>
        <thead>
          <tr>
            <th>Date</th>
            <th>Buyer</th>
            <th>Description</th>
            <th>Amount</th>
          </tr>
        </thead>
        <tbody>
          $expenseRows
        </tbody>
      </table>

      <div class="footer">
        <p>This is a computer-generated report from Messmate & Finance Manager App.</p>
      </div>
    </body>
    </html>
    """;

    await Printing.layoutPdf(
      onLayout: (format) async => await Printing.convertHtml(
        format: format,
        html: htmlContent,
      ),
    );
  }
}
