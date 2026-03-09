
import 'package:printing/printing.dart';
import '../models/mess_member.dart';
import '../models/mess_market_expense.dart';
import '../models/mess_info.dart';
import 'package:intl/intl.dart';

class MessReportHelper {
  static Future<void> generateAndPrintReport({
    required MessInfo messInfo,
    required List<MessMember> members,
    required List<MessMarketExpense> expenses,
    required double totalMeals,
    required double totalCost,
    required double mealRate,
    required String currency,
  }) async {
    final dateStr = DateFormat('dd MMMM, yyyy').format(DateTime.now());
    
    // Logo HTML (Using placeholder if no logo)
    final logoHtml = messInfo.logoUrl != null 
      ? '<img src="${messInfo.logoUrl}" style="height: 80px; width: 80px; border-radius: 50%; object-fit: cover;">'
      : '<div style="height: 80px; width: 80px; background: #3f51b5; color: white; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 24px; font-weight: bold; margin: 0 auto;">${messInfo.name[0]}</div>';

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

    final htmlContent = """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body { font-family: 'SolaimanLipi', sans-serif; padding: 20px; color: #333; }
        .header-table { width: 100%; border-bottom: 3px solid #3f51b5; padding-bottom: 15px; margin-bottom: 25px; }
        .mess-details { text-align: left; vertical-align: middle; }
        .logo-container { text-align: right; vertical-align: middle; width: 100px; }
        .mess-name { font-size: 32px; font-weight: bold; color: #3f51b5; margin: 0; }
        .mess-info { font-size: 14px; color: #666; margin: 3px 0; }
        .stats-container { display: flex; justify-content: space-around; margin-bottom: 30px; }
        .stat-box { background: #f0f2f5; border-radius: 12px; padding: 15px; text-align: center; min-width: 130px; }
        .stat-label { font-size: 11px; color: #57606f; text-transform: uppercase; letter-spacing: 1px; }
        .stat-value { font-size: 20px; font-weight: bold; color: #2f3542; margin-top: 5px; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th { background-color: #3f51b5; color: white; text-align: left; padding: 12px; font-size: 14px; }
        td { border-bottom: 1px solid #eee; padding: 12px; font-size: 13px; }
        tr:nth-child(even) { background-color: #f8f9fa; }
        .section-title { font-size: 18px; font-weight: bold; color: #3f51b5; margin: 30px 0 10px 0; border-left: 5px solid #3f51b5; padding-left: 10px; }
        .footer { margin-top: 60px; text-align: center; font-size: 11px; color: #a4b0be; }
        .app-branding { display: flex; align-items: center; justify-content: center; margin-top: 10px; gap: 5px; }
      </style>
    </head>
    <body>
      <table class="header-table">
        <tr>
          <td class="mess-details" style="border:none;">
            <h1 class="mess-name">${messInfo.name}</h1>
            <p class="mess-info">📍 ${messInfo.address}</p>
            <p class="mess-info">📞 Owner: ${messInfo.ownerPhone}</p>
            <p class="mess-info">📅 Billing Period: ${dateStr}</p>
          </td>
          <td class="logo-container" style="border:none;">
            $logoHtml
          </td>
        </tr>
      </table>

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

      <div class="section-title">Member Financial Summary (সদস্য বিবরণী)</div>
      <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>Meals</th>
            <th>Meal Cost</th>
            <th>Other Bills</th>
            <th>Deposit</th>
            <th>Net Due</th>
          </tr>
        </thead>
        <tbody>
          $memberRows
        </tbody>
      </table>

      <div class="footer">
        <div class="app-branding">
          <span>Powered by <strong>Messmate & Finance Manager</strong></span>
        </div>
        <p>© ${DateTime.now().year} All Rights Reserved. Generated for transparent mess management.</p>
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
