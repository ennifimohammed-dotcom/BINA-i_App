import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/database_helper.dart';
import '../models/expense.dart';
import '../models/app_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _total = 0;
  double _budget = 400000;
  Map<String, double> _catTotals = {};
  Map<String, double> _monthlyTotals = {};
  List<Expense> _recent = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseHelper.instance;
    final total = await db.getTotalAmount();
    final budget = await db.getBudget();
    final cats = await db.getCategoryTotals();
    final monthly = await db.getMonthlyTotals();
    final all = await db.getAllExpenses();

    setState(() {
      _total = total;
      _budget = budget;
      _catTotals = cats;
      _monthlyTotals = monthly;
      _recent = all.take(5).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final isAr = state?.isArabic ?? true;
    final remaining = _budget - _total;
    final progress = (_total / _budget).clamp(0.0, 1.0);
    final isOverBudget = _total > _budget;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A3A5C), Color(0xFF2E6BA8)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isAr ? 'مصاريف البناء' : 'Dépenses Construction',
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'ENNIFI 2025',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_total.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')} درهم',
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAr ? 'إجمالي المصاريف' : 'Total des dépenses',
                            style: const TextStyle(color: Colors.white60, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isOverBudget ? Colors.redAccent : const Color(0xFF4ECDC4),
                              ),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(progress * 100).toStringAsFixed(1)}% ${isAr ? 'مستهلك' : 'consommé'}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Text(
                                isAr
                                    ? 'الميزانية: ${_budget.toStringAsFixed(0)} درهم'
                                    : 'Budget: ${_budget.toStringAsFixed(0)} DH',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                          if (isOverBudget)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isAr ? '⚠️ تجاوز الميزانية!' : '⚠️ Budget dépassé!',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // بطاقات ملخص
                    Row(
                      children: [
                        _SummaryCard(
                          label: isAr ? 'المتبقي' : 'Restant',
                          value: remaining < 0
                              ? '-${remaining.abs().toStringAsFixed(0)}'
                              : remaining.toStringAsFixed(0),
                          suffix: isAr ? 'درهم' : 'DH',
                          color: remaining < 0 ? Colors.red : Colors.green,
                          icon: Icons.account_balance_wallet_rounded,
                        ),
                        const SizedBox(width: 12),
                        _SummaryCard(
                          label: isAr ? 'عدد العمليات' : 'Opérations',
                          value: _catTotals.values.fold(0.0, (a, b) => a + b).toStringAsFixed(0),
                          suffix: '',
                          color: const Color(0xFF1A3A5C),
                          icon: Icons.receipt_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // رسم التوزيع حسب الفئة
                    if (_catTotals.isNotEmpty) ...[
                      Text(
                        isAr ? 'التوزيع حسب الفئة' : 'Répartition par catégorie',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C)),
                      ),
                      const SizedBox(height: 12),
                      _CategoryChart(catTotals: _catTotals, total: _total),
                      const SizedBox(height: 20),
                    ],

                    // رسم الأشهر
                    if (_monthlyTotals.isNotEmpty) ...[
                      Text(
                        isAr ? 'المصاريف الشهرية' : 'Dépenses mensuelles',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C)),
                      ),
                      const SizedBox(height: 12),
                      _MonthlyChart(monthlyTotals: _monthlyTotals),
                      const SizedBox(height: 20),
                    ],

                    // آخر النفقات
                    Text(
                      isAr ? 'آخر النفقات' : 'Dernières dépenses',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C)),
                    ),
                    const SizedBox(height: 12),
                    ..._recent.map((e) => _RecentExpenseItem(expense: e, isAr: isAr)),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.suffix,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              '$value ${suffix.isNotEmpty ? suffix : ''}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  final Map<String, double> catTotals;
  final double total;

  const _CategoryChart({required this.catTotals, required this.total});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF1A3A5C), const Color(0xFFE74C3C), const Color(0xFF27AE60),
      const Color(0xFFF39C12), const Color(0xFF8E44AD), const Color(0xFF16A085),
      const Color(0xFF2980B9), const Color(0xFFD35400), const Color(0xFF7F8C8D),
    ];

    final sorted = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: List.generate(sorted.length, (i) {
                  final entry = sorted[i];
                  return PieChartSectionData(
                    value: entry.value,
                    color: colors[i % colors.length],
                    radius: 70,
                    title: '${(entry.value / total * 100).toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: List.generate(sorted.length, (i) {
              final entry = sorted[i];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[i % colors.length], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 4),
                  Text('${entry.key}: ${entry.value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.black87)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  final Map<String, double> monthlyTotals;

  const _MonthlyChart({required this.monthlyTotals});

  @override
  Widget build(BuildContext context) {
    final months = monthlyTotals.keys.toList()..sort();
    final values = months.map((m) => monthlyTotals[m]!).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);

    final monthLabels = {
      '01': 'يناير', '02': 'فبراير', '03': 'مارس', '04': 'أبريل',
      '05': 'ماي', '06': 'يونيو', '07': 'يوليوز', '08': 'غشت',
      '09': 'شتنبر', '10': 'أكتوبر', '11': 'نونبر', '12': 'دجنبر'
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            maxY: maxVal * 1.2,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, meta) {
                    final idx = val.toInt();
                    if (idx >= months.length) return const SizedBox();
                    final mo = months[idx].substring(5, 7);
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(monthLabels[mo]?.substring(0, 3) ?? mo, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                    );
                  },
                ),
              ),
            ),
            barGroups: List.generate(months.length, (i) => BarChartGroupData(
              x: i,
              barRods: [BarChartRodData(
                toY: values[i],
                color: const Color(0xFF1A3A5C),
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              )],
            )),
          ),
        ),
      ),
    );
  }
}

class _RecentExpenseItem extends StatelessWidget {
  final Expense expense;
  final bool isAr;

  const _RecentExpenseItem({required this.expense, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final cat = ExpenseCategory.findByName(expense.category);
    final color = cat != null ? Color(cat.colorValue) : const Color(0xFF888888);
    final icon = cat?.icon ?? '📦';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${expense.category} • ${expense.date}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text(
            '-${expense.amount.toStringAsFixed(0)} ${isAr ? 'د' : 'DH'}',
            style: const TextStyle(color: Color(0xFFC0392B), fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
