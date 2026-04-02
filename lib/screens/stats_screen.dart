import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/database_helper.dart';
import '../models/expense.dart';
import '../models/app_state.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, double> _catTotals = {};
  Map<String, double> _monthlyTotals = {};
  double _total = 0;
  double _budget = 400000;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseHelper.instance;
    final cats = await db.getCategoryTotals();
    final monthly = await db.getMonthlyTotals();
    final total = await db.getTotalAmount();
    final budget = await db.getBudget();
    setState(() {
      _catTotals = cats;
      _monthlyTotals = monthly;
      _total = total;
      _budget = budget;
    });
  }

  Future<void> _exportPDF() async {
    setState(() => _exporting = true);
    final db = DatabaseHelper.instance;
    final all = await db.getAllExpenses();

    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        pw.Header(level: 0, child: pw.Text('ENNIFI 2025 - تقرير مصاريف البناء', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 10),
        pw.Text('تاريخ التقرير: ${DateTime.now().toIso8601String().substring(0, 10)}'),
        pw.Text('الإجمالي: ${_total.toStringAsFixed(2)} درهم'),
        pw.Text('الميزانية: ${_budget.toStringAsFixed(2)} درهم'),
        pw.Text('المتبقي: ${(_budget - _total).toStringAsFixed(2)} درهم'),
        pw.SizedBox(height: 20),
        pw.Text('التفصيل حسب الفئة:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: ['الفئة', 'المبلغ (درهم)', 'النسبة'],
          data: _catTotals.entries.map((e) => [
            e.key,
            e.value.toStringAsFixed(2),
            '${(e.value / _total * 100).toStringAsFixed(1)}%'
          ]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
          cellAlignment: pw.Alignment.centerLeft,
        ),
        pw.SizedBox(height: 20),
        pw.Text('قائمة النفقات الكاملة:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: ['التاريخ', 'الوصف', 'الصنف', 'المبلغ'],
          data: all.map((e) => [e.date, e.description, e.category, '${e.amount.toStringAsFixed(2)} درهم']).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
          cellStyle: const pw.TextStyle(fontSize: 9),
        ),
      ],
    ));

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/ennifi_rapport_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    setState(() => _exporting = false);

    if (mounted) {
      await Printing.sharePdf(bytes: await pdf.save(), filename: 'ennifi_rapport.pdf');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final isAr = state?.isArabic ?? true;
    final remaining = _budget - _total;
    final colors = [
      const Color(0xFF1A3A5C), const Color(0xFFE74C3C), const Color(0xFF27AE60),
      const Color(0xFFF39C12), const Color(0xFF8E44AD), const Color(0xFF16A085),
      const Color(0xFF2980B9), const Color(0xFFD35400), const Color(0xFF7F8C8D),
    ];
    final sorted = _catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(isAr ? 'التقارير والإحصاء' : 'Rapports & Statistiques'),
        actions: [
          IconButton(
            onPressed: _exporting ? null : _exportPDF,
            icon: _exporting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_rounded),
            tooltip: isAr ? 'تصدير PDF' : 'Exporter PDF',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // بطاقات ملخص
            Row(children: [
              _StatCard(label: isAr ? 'إجمالي المصاريف' : 'Total dépenses', value: '${_total.toStringAsFixed(0)} ${isAr ? 'درهم' : 'DH'}', color: const Color(0xFF1A3A5C), icon: '💰'),
              const SizedBox(width: 10),
              _StatCard(label: isAr ? 'المتبقي من الميزانية' : 'Reste budget', value: '${remaining.toStringAsFixed(0)} ${isAr ? 'درهم' : 'DH'}', color: remaining >= 0 ? const Color(0xFF27AE60) : const Color(0xFFE74C3C), icon: remaining >= 0 ? '✅' : '⚠️'),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _StatCard(label: isAr ? 'نسبة الاستهلاك' : 'Taux consommation', value: '${(_total / _budget * 100).toStringAsFixed(1)}%', color: const Color(0xFFF39C12), icon: '📊'),
              const SizedBox(width: 10),
              _StatCard(label: isAr ? 'عدد الفئات' : 'Catégories', value: '${_catTotals.length}', color: const Color(0xFF8E44AD), icon: '📁'),
            ]),

            const SizedBox(height: 20),

            // شريط التقدم للميزانية
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isAr ? 'تقدم الميزانية' : 'Avancement budget', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (_total / _budget).clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _total > _budget ? Colors.red : const Color(0xFF1A3A5C),
                      ),
                      minHeight: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${(_total / _budget * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
                      Text('${_budget.toStringAsFixed(0)} ${isAr ? 'درهم' : 'DH'}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // تفصيل الفئات
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isAr ? 'التفصيل حسب الفئة' : 'Détail par catégorie', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 16),
                  ...List.generate(sorted.length, (i) {
                    final e = sorted[i];
                    final pct = _total > 0 ? e.value / _total : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[i % colors.length], borderRadius: BorderRadius.circular(3))),
                              const SizedBox(width: 8),
                              Expanded(child: Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                              Text('${e.value.toStringAsFixed(0)} ${isAr ? 'درهم' : 'DH'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text('${(pct * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, color: colors[i % colors.length])),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              backgroundColor: Colors.grey.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(colors[i % colors.length]),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // زر التصدير
            ElevatedButton.icon(
              onPressed: _exporting ? null : _exportPDF,
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: Text(isAr ? 'تصدير التقرير PDF' : 'Exporter rapport PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC0392B),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String icon;

  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
