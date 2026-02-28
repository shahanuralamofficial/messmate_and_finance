import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../services/report_service.dart';
import '../utils/translations.dart';
import '../widgets/bottom_nav_bar.dart';
import '../models/transaction.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _reportService = ReportService();
  int _touchedIndex = -1;
  int _selectedYear = DateTime.now().year;

  void _showDownloadOptions() {
    HapticFeedback.mediumImpact();
    final financeProvider = Provider.of<FinanceProvider>(context, listen: false);
    final now = DateTime.now();
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              _buildDownloadTile(ctx, Icons.calendar_view_week, 'Weekly Report', () {
                final weeklyTxs = financeProvider.transactions.where((t) => now.difference(t.date).inDays <= 7).toList();
                _reportService.generateAndSharePdf(weeklyTxs, 'Weekly');
              }),
              _buildDownloadTile(ctx, Icons.calendar_view_month, 'Monthly Report', () {
                final monthlyTxs = financeProvider.transactions.where((t) => t.date.year == now.year && t.date.month == now.month).toList();
                _reportService.generateAndSharePdf(monthlyTxs, 'Monthly');
              }),
              _buildDownloadTile(ctx, Icons.calendar_today, 'Yearly Report', () {
                final yearlyTxs = financeProvider.transactions.where((t) => t.date.year == _selectedYear).toList();
                _reportService.generateAndSharePdf(yearlyTxs, 'Yearly');
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDownloadTile(BuildContext ctx, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: () {
        Navigator.pop(ctx);
        onTap();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final financeProvider = Provider.of<FinanceProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final locale = settings.locale.languageCode;
    final isBangla = locale == 'bn';
    final isDark = themeProvider.isDarkMode;
    
    final yearTransactions = financeProvider.transactions.where((t) => t.date.year == _selectedYear).toList();
    final double yearlyIncome = yearTransactions.where((t) => t.type == TransactionType.income).fold(0, (sum, t) => sum + t.amount);
    final double yearlyExpense = yearTransactions.where((t) => t.type == TransactionType.expense).fold(0, (sum, t) => sum + t.amount);

    final categoryData = financeProvider.getCategoryWiseExpense();
    final monthlyData = financeProvider.getMonthlyData(_selectedYear);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          AppTranslations.translate('reports', locale),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.file_download_outlined), onPressed: _showDownloadOptions),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                _buildProfessionalSummaryCard(isDark, Icons.trending_up, Colors.greenAccent, isBangla ? 'আয়' : 'Income', '${settings.currencySymbol}${yearlyIncome.toStringAsFixed(0)}'),
                const SizedBox(width: 12),
                _buildProfessionalSummaryCard(isDark, Icons.trending_down, Colors.redAccent, isBangla ? 'ব্যয়' : 'Expense', '${settings.currencySymbol}${yearlyExpense.toStringAsFixed(0)}'),
              ],
            ),
            const SizedBox(height: 24),

            _buildProfessionalChartCard(
              isDark,
              isBangla ? 'ব্যয়ের খাতসমূহ' : 'Expense Categories',
              SizedBox(
                height: 250,
                child: categoryData.isEmpty 
                  ? Center(child: Text(isBangla ? 'কোনো ব্যয় নেই' : 'No expenses recorded', style: TextStyle(color: Colors.grey[500])))
                  : Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(touchCallback: (event, response) {
                                setState(() {
                                  if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex = response.touchedSection!.touchedSectionIndex;
                                });
                              }),
                              sectionsSpace: 4,
                              centerSpaceRadius: 40,
                              sections: List.generate(categoryData.length, (i) {
                                final isTouched = i == _touchedIndex;
                                final value = categoryData.values.elementAt(i);
                                return PieChartSectionData(
                                  color: Colors.primaries[i % Colors.primaries.length],
                                  value: value,
                                  title: '${(value / yearlyExpense * 100).toStringAsFixed(0)}%',
                                  radius: isTouched ? 65 : 55,
                                  titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                                );
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: SingleChildScrollView(
                            child: Column(
                              children: categoryData.keys.map((key) {
                                int index = categoryData.keys.toList().indexOf(key);
                                // Translate category keys in Legend
                                return _buildLegendRow(AppTranslations.translate(key, locale), Colors.primaries[index % Colors.primaries.length], isDark);
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
              ),
            ),
            const SizedBox(height: 24),

            _buildProfessionalChartCard(
              isDark,
              '${isBangla ? 'মাসিক রিপোর্ট' : 'Monthly Summary'} ($_selectedYear)',
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      DropdownButton<int>(
                        value: _selectedYear,
                        underline: const SizedBox(),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        items: List.generate(5, (i) => DateTime.now().year - i).map((y) => 
                          DropdownMenuItem(value: y, child: Text(y.toString()))
                        ).toList(),
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedYear = val!);
                        },
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        barGroups: List.generate(monthlyData.length, (i) {
                          final data = monthlyData[i];
                          return BarChartGroupData(
                            x: data['month'],
                            barRods: [
                              BarChartRodData(toY: data['income'], color: Colors.greenAccent, width: 8, borderRadius: BorderRadius.circular(4)),
                              BarChartRodData(toY: data['expense'], color: Colors.redAccent, width: 8, borderRadius: BorderRadius.circular(4)),
                            ]
                          );
                        }),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                if (val < 1 || val > 12) return const SizedBox();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(monthNames[val.toInt() - 1], style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildProfessionalSummaryCard(bool isDark, IconData icon, Color color, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalChartCard(bool isDark, String title, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          content,
        ],
      ),
    );
  }

  Widget _buildLegendRow(String label, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
